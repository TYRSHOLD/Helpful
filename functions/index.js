/**
 * Firebase Cloud Functions for Helpful – Plaid link token + exchange + transaction sync.
 *
 * HOW TO PUT YOUR PLAID KEYS IN THE BACKEND:
 *
 * 1. Local testing (emulator):
 *    - Copy functions/.env.example to functions/.env
 *    - Open functions/.env and set PLAID_CLIENT_ID and PLAID_SECRET (Sandbox keys from Plaid Dashboard → Keys)
 *    - .env is in .gitignore – do not commit it
 *
 * 2. Deployed (production):
 *    - From project root: cd functions && npm install && cd ..
 *    - firebase deploy --only functions
 *    - On first deploy you’ll be prompted for PLAID_CLIENT_ID and PLAID_SECRET; enter your Sandbox values
 *    - They’re saved to functions/.env.<your-project-id> (you can add that file to .gitignore if you want)
 */

import "dotenv/config";
import { onRequest } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { Configuration, PlaidApi, PlaidEnvironments } from "plaid";

// Plaid keys: use params (prompted on first deploy) or env vars for local
const plaidClientId = defineString("PLAID_CLIENT_ID");
const plaidSecret = defineString("PLAID_SECRET");

initializeApp();
const db = getFirestore();

function getPlaidClient() {
  const clientId = plaidClientId.value() || process.env.PLAID_CLIENT_ID;
  const secret = plaidSecret.value() || process.env.PLAID_SECRET;
  if (!clientId || !secret) {
    throw new Error("Missing PLAID_CLIENT_ID or PLAID_SECRET. Set them in Firebase config or .env.");
  }
  const configuration = new Configuration({
    basePath: PlaidEnvironments.sandbox,
    baseOptions: {
      headers: {
        "PLAID-CLIENT-ID": clientId,
        "PLAID-SECRET": secret,
      },
    },
  });
  return new PlaidApi(configuration);
}

/**
 * POST /plaidLinkToken
 * Body: { "userId": "<firebase-uid>" }
 * Returns: { "link_token": "..." }
 */
export const plaidLinkToken = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }
    try {
      const { userId } = req.body || {};
      if (!userId) {
        res.status(400).json({ error: "Missing userId" });
        return;
      }
      const client = getPlaidClient();
      const response = await client.linkTokenCreate({
        user: { client_user_id: userId },
        client_name: "Helpful",
        products: ["transactions"],
        country_codes: ["US"],
        language: "en",
      });
      res.json({ link_token: response.data.link_token });
    } catch (e) {
      console.error("plaidLinkToken error:", e);
      res.status(500).json({ error: e.message || "Failed to create link token" });
    }
  }
);

/**
 * POST /plaidExchange
 * Body: { "public_token": "...", "userId": "<firebase-uid>" }
 * Exchanges token, fetches transactions, writes to Firestore users/{userId}/transactions
 */
export const plaidExchange = onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }
    try {
      const { public_token, userId } = req.body || {};
      if (!public_token || !userId) {
        res.status(400).json({ error: "Missing public_token or userId" });
        return;
      }
      const client = getPlaidClient();
      const exchangeRes = await client.itemPublicTokenExchange({ public_token });
      const accessToken = exchangeRes.data.access_token;

      // Fetch transactions (last 30 days for sandbox)
      const endDate = new Date().toISOString().slice(0, 10);
      const startDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
      const txRes = await client.transactionsGet({
        access_token: accessToken,
        start_date: startDate,
        end_date: endDate,
      });

      const transactions = txRes.data.transactions || [];
      const txRef = db.collection("users").doc(userId).collection("transactions");

      for (const t of transactions) {
        const amount = Math.abs(t.amount);
        const kind = t.amount < 0 ? "Expense" : "Income";
        const category = (t.personal_finance_category?.primary || t.category?.[0] || "Other").replace(/_/g, " ");
        const note = [t.name, t.merchant_name].filter(Boolean).join(" – ") || "Plaid";
        const date = t.date ? new Date(t.date) : new Date();

        await txRef.add({
          amount,
          category,
          note,
          date: date,
          isRecurring: false,
          kind,
          tags: ["plaid"],
        });
      }

      res.status(200).json({ ok: true, synced: transactions.length });
    } catch (e) {
      console.error("plaidExchange error:", e);
      res.status(500).json({ error: e.message || "Exchange failed" });
    }
  }
);

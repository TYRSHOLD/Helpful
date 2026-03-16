# Adding Plaid to Helpful

Plaid lets users connect bank accounts so you can pull transactions (and optionally balances) into the app. Integration has **three parts**: Plaid account, a **backend** that talks to Plaid’s API, and the **iOS app** using the Link SDK.

---

## 1. Plaid account and keys

1. Sign up at [dashboard.plaid.com](https://dashboard.plaid.com) and create an application.
2. In **Team Settings → API**, copy your **Client ID** and **Secret** (and choose **Sandbox** for development).
3. In **API → Allowed redirect URIs**, add a Universal Link you’ll use for OAuth, e.g. `https://yourdomain.com/plaid/` (see step 3 below).

---

## 2. Backend (required)

Plaid **must not** be called with your secret from the app. You need a backend that:

- Creates a **link token** (so the app can open Link).
- Exchanges the **public token** (from Link) for an **access token** and then fetches transactions (and optionally syncs them to Firestore).

### Option A: Firebase Cloud Functions (fits your stack)

The iOS app expects two HTTPS endpoints (configurable via `PlaidService.shared.backendBaseURL`):

1. **POST `{baseURL}/plaidLinkToken`**  
   Request body: `{ "userId": "<firebase-uid>" }`.  
   Your function calls Plaid’s `/link/token/create` and returns `{ "link_token": "<token>" }`.  
   Use your Plaid **client_id** and **secret** only in the function (e.g. via environment config or Secret Manager).  
   For OAuth redirects, include the `redirect_uri` in the create call (see Universal Links below).

2. **POST `{baseURL}/plaidExchange`**  
   Request body: `{ "public_token": "<from-link>", "userId": "<firebase-uid>" }`.  
   Your function:
   - Calls Plaid’s `/item/public_token/exchange` to get an `access_token`.
   - Stores `access_token` (and optional `item_id`) per user, e.g. in Firestore.
   - Uses Plaid’s **Transactions** API to pull transactions and writes them into the user’s `transactions` subcollection (map Plaid fields to your `Transaction` model).
   - Returns 200 on success so the app can show “Bank connected” and refresh.

Use the official [Plaid Node library](https://github.com/plaid/plaid-node) in the Cloud Function. Plaid’s docs: [link/token/create](https://plaid.com/docs/api/tokens/#linktokencreate), [exchange](https://plaid.com/docs/api/items/#itempublic_tokenexchange), [transactions/get](https://plaid.com/docs/api/products/transactions/#transactionsget).

### Option B: Your own server (Node, Python, etc.)

Same idea: one endpoint that returns a link token, another that accepts the public token, exchanges it, and fetches/syncs transactions. Never expose the Plaid secret to the client.

---

## 3. Universal Links (for OAuth)

When a user is sent to their bank to log in, Plaid redirects back to your app via a **Universal Link**. You need:

1. **A domain you control** (e.g. `https://yourdomain.com`).
2. **File** `https://yourdomain.com/.well-known/apple-app-site-association` (no file extension), e.g.:

```json
{
  "applinks": {
    "details": [{
      "appIDs": ["TEAM_ID.com.DontaD.Helpful"],
      "components": [{ "/": "/plaid/*", "comment": "Plaid OAuth redirect" }]
    }]
  }
}
```

Replace `TEAM_ID` with your Apple Team ID (e.g. from Xcode or developer.apple.com).

3. **In Xcode**: Target → Signing & Capabilities → **Associated Domains** → add `applinks:yourdomain.com`.
4. **In Plaid Dashboard**: Add `https://yourdomain.com/plaid/` (or your chosen path) under **Allowed redirect URIs**, and use the same redirect URI when calling `/link/token/create`.

---

## 4. iOS app (this project)

- **Add LinkKit**  
  In Xcode: **File → Add Package Dependencies** → URL:  
  `https://github.com/plaid/plaid-link-ios-spm`  
  Add the **LinkKit** product to the **Helpful** app target.  
  (Without this package, “Connect bank” still runs but will show an error; the rest of the app builds.)

- **Set your backend URL**  
  In code or via a config: set `PlaidService.shared.backendBaseURL` to your backend base URL (e.g. `https://us-central1-YOUR_PROJECT.cloudfunctions.net`). You can do this in `HelpfulApp.swift` or when the user is authenticated.

- **Use the Plaid service**  
  `PlaidService` (see `Helpful/PlaidService.swift`):
  - Set `PlaidService.shared.backendBaseURL` to your backend base URL (e.g. Cloud Functions URL).
  - “Connect bank” at the top of the **Spending** tab (above Income) calls `presentLink(userId:onSuccess:onExit:onFailure)`.
  - The service fetches a link token from `POST {baseURL}/plaidLinkToken`, presents Plaid Link, then sends the public token to `POST {baseURL}/plaidExchange`.
  - Your backend exchanges the token and syncs transactions to Firestore; the app refreshes transactions on success.

- **Where to open Link**  
  Add a “Connect bank account” or “Link account” action (e.g. in **Spending** or **More**) that calls `PlaidService.shared.createLinkToken()` then presents Link. After a successful link, refresh transactions so the new data appears.

- **Optional: Identity Verification**  
  If you later use Plaid’s Identity Verification product, add a **Camera Usage Description** in Info.plist for the document capture step.

---

## 5. Mapping Plaid transactions to your model

Your `Transaction` model has: `amount`, `category`, `note`, `date`, `kind` (expense/income), `tags`, etc. Plaid’s transaction object has:

- `amount`, `date`, `name` (merchant/description), `personal_finance_category` or `category` (you can map to your `TransactionCategory`), and a `transaction_type` (e.g. debit vs credit).

In your backend, when syncing:

- Use `amount` (positive); set `kind` to expense or income from `transaction_type` (or your own rule).
- Map Plaid category to your `category` string or enum.
- Use `name` (and maybe `merchant_name`) for `note`.
- Store a Plaid `transaction_id` somewhere (e.g. in the document or a separate field) so you can avoid inserting duplicates on later syncs.

---

## Quick checklist

- [ ] Plaid account + Client ID + Secret (Sandbox for dev)
- [ ] Backend: create link token + exchange public token + fetch/sync transactions (e.g. Cloud Functions)
- [ ] Redirect URI in Plaid Dashboard and in `/link/token/create`
- [ ] Domain + `apple-app-site-association` + Associated Domains in Xcode
- [ ] LinkKit added to Helpful target
- [ ] “Connect bank” UI that gets link token, presents Link, sends public token to backend
- [ ] After link, refresh transactions so Firestore updates appear in the app

# How to put your Plaid keys in the backend

Your Plaid **Client ID** and **Secret** (Sandbox) are used only inside these Cloud Functions. Never put them in the iOS app.

## Option 1: Local testing (emulator)

1. In the `functions` folder, copy the example env file:
   ```bash
   cp .env.example .env
   ```
2. Open `functions/.env` in a text editor.
3. Paste your keys (from Plaid Dashboard → **Developers → Keys**, use **Sandbox**):
   ```
   PLAID_CLIENT_ID=your_actual_client_id
   PLAID_SECRET=your_actual_sandbox_secret
   ```
4. Save the file. Do **not** commit `.env` (it’s in `.gitignore`).
5. Run the emulator: from project root, `firebase emulators:start --only functions`.

## Option 2: Deployed (production)

1. Install dependencies and deploy:
   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions
   ```
2. The first time you deploy, Firebase will **prompt you** for:
   - `PLAID_CLIENT_ID` – paste your Sandbox Client ID
   - `PLAID_SECRET` – paste your Sandbox Secret
3. Those values are saved to `functions/.env.<your-project-id>` (you can add that file to `.gitignore` if you like).

After deployment, copy your Functions URL (e.g. `https://us-central1-YOUR_PROJECT.cloudfunctions.net`) and set it in the app as `PlaidService.shared.backendBaseURL`.

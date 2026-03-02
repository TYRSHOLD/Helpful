## Helpful – Install & Run Guide

This guide walks you (or a teammate) through getting the **Helpful** iOS app running locally from a fresh clone.

---

## 1. Requirements

- **macOS** with Xcode **15+**
- **iOS 17+** simulator or device
- A **Firebase** project with:
  - Authentication (Email/Password) enabled
  - Cloud Firestore enabled
  - Firebase Storage enabled
- A **RapidAPI** account with access to the **JSearch** API (free tier is fine)

---

## 2. Clone the Repo

```bash
git clone <your-repo-url>.git
cd Helpful
```

No CocoaPods are used; all dependencies are via **Swift Package Manager** inside the Xcode project.

---

## 3. Configure Firebase

1. Go to the [Firebase Console](https://console.firebase.google.com) and create (or reuse) a project.
2. Add a new **iOS app** to the project:
   - iOS bundle ID must match the one used in the project (check `HelpfulApp` target in Xcode).
3. Download the generated **`GoogleService-Info.plist`**.
4. In Finder or Xcode, place the file at:

   - `Helpful/GoogleService-Info.plist`

   If a file already exists there, replace it with your version.

5. In the Firebase Console:
   - **Authentication → Sign-in method**: enable **Email/Password**.
   - **Firestore Database**: create a database (start in test mode for local dev, then tighten rules for production).
   - **Storage**: enable Firebase Storage.

> The Firestore structure expected by the app is documented in `README.md` under **Firebase Backend**.

---

## 4. Configure JSearch (RapidAPI) Key

1. Sign up at [rapidapi.com](https://rapidapi.com) and subscribe to the **JSearch** API.
2. Copy your **RapidAPI key** from the dashboard.
3. Open the file:

   - `Helpful/Secrets.plist`

4. Replace the placeholder value `YOUR_RAPIDAPI_KEY_HERE` (or equivalent) with your actual key under the `RapidAPIKey` entry.

`Secrets.plist` is gitignored so your key will not be committed.

---

## 5. Open in Xcode

From the repo root:

```bash
open Helpful.xcodeproj
```

Xcode will:

- Resolve Swift Package Manager dependencies.
- Index the project.

If SPM doesn’t resolve automatically, open **File → Packages → Resolve Package Versions**.

---

## 6. Select Scheme & Run

1. In Xcode, choose the **Helpful** scheme.
2. Select a target device (e.g. **iPhone 15** simulator).
3. Press **Run** (⌘R).

On first launch:

- You should see the **auth flow** (login / sign up).
- After signing up, the app will create your user document in Firestore and walk you through onboarding.

If you want to test widgets, also run on a simulator/device that supports iOS widgets and add the **Helpful** widgets from the iOS widget gallery after you’ve added some budgets/transactions.

---

## 7. Common Issues & Fixes

- **Blank screen / Firebase errors at launch**
  - Check that `GoogleService-Info.plist` is present in the `Helpful` target and not just the project.
  - In Xcode, select the file → **File Inspector** → ensure the `Helpful` target is checked under **Target Membership**.

- **Firestore permission errors**
  - For development, you can temporarily use permissive rules:
    ```text
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        match /{document=**} {
          allow read, write: if request.auth != null;
        }
      }
    }
    ```
  - Then tighten them to the per-user rules shown in `README.md` before shipping.

- **Opportunities (Discover tab) not loading**
  - Double-check `Secrets.plist` has a valid RapidAPI key.
  - Verify your RapidAPI subscription hasn’t exceeded its quota.

---

## 8. Running on a Physical Device

To run Helpful on an iPhone/iPad:

1. Connect the device via USB or Wi‑Fi.
2. In Xcode, select your device as the run target.
3. Ensure your Apple ID / Team is set under **Signing & Capabilities** for the Helpful target.
4. Press **Run** (⌘R).

Firebase and RapidAPI configuration is the same; they’re bundled with the app at build time.

---

If you’d like, I can also add a short **CONTRIBUTING.md** with coding conventions and how to run through a smoke-test checklist before commits.


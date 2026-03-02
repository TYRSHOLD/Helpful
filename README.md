# Helpful

A SwiftUI iOS app designed as an all-in-one student financial companion. Helpful lets students manage budgets, track spending, set savings goals, upload documents, plan their semester, and discover scholarships and internships with a Tinder-style swipe interface -- all backed by Firebase.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Firebase Backend](#firebase-backend)
- [Data Models](#data-models)
- [App Flow](#app-flow)
- [Views](#views)
- [ViewModels](#viewmodels)
- [Services](#services)
- [Theming](#theming)
- [Setup](#setup)

---

## Features

**Authentication**
- Email/password signup and login
- Persistent sessions via Firebase Auth
- User-friendly error messages for common auth failures
- Sign out from the Home screen toolbar or Profile screen

**Guided Onboarding**
- 3-step onboarding flow shown after first signup
- Welcome screen introducing the app
- Profile setup collecting name, birthday, school, and major
- Saves to Firestore and marks onboarding as complete

**Dashboard (Home)**
- Time-of-day greeting with the user's name
- 5 tappable summary cards (Budget, Spent, Saved, Goals, Opportunities) that navigate to their respective tabs
- Quick-action buttons for common tasks
- Recent transactions list with swipe-to-delete and tap-to-view-detail

**Budget Tracking**
- Create monthly budgets with a total amount
- Progress bar showing spent vs. total
- Budget `spent` field auto-updates when transactions are added or deleted
- Swipe-to-delete budgets
- Floating action button (FAB) to add new budgets

**Transaction Tracking**
- Log transactions with amount, category, optional note, and optional receipt photo
- 8 categories (Food, Transport, Entertainment, Shopping, Bills, Education, Health, Other), each with a unique icon and color
- Transactions grouped by date
- Swipe-to-delete with automatic budget rollback
- Tap any transaction to view full details including receipt image
- Receipt photos uploaded to Firebase Storage

**Savings Goals**
- Create goals with a title, emoji icon, target amount, and deadline
- Compact card layout with emoji, progress bar, and amounts
- Add funds toward a goal via a menu option
- Swipe-to-delete goals
- Emoji picker with common goal icons when creating a goal

**Document Uploads**
- Upload PDFs and images to Firebase Storage
- Documents listed with title, date, and file-type icon
- Tap to open in browser, swipe-to-delete
- Metadata stored in Firestore, files stored in Firebase Storage

**Semester Tools**
- GPA Calculator: add courses with name, credits, and letter grade; semester GPA calculated live
- Cost Calculator: line items for tuition, books, housing, food, transport, and custom items; total calculated live
- Both calculators support swipe-to-delete rows and a FAB to add new entries

**Opportunity Discovery (Scholarships & Internships)**
- Tinder-style swipe interface for browsing scholarships and internships
- Powered by the RapidAPI JSearch API (aggregates from LinkedIn, Indeed, Glassdoor, etc.)
- Swipe right to save, swipe left to dismiss
- Green "SAVE" / red "PASS" overlays with rotation during drag
- Card stack showing top 3 opportunities with stacked depth effect
- Action buttons: dismiss (X), undo last dismiss, and save (heart)
- Segmented filter: All / Scholarships / Internships
- Saved opportunities list with swipe-to-unfavorite
- Tap a saved opportunity to open the application link in Safari
- Saved and dismissed states persisted in Firestore
- Automatic pagination: loads more cards when the stack runs low

**Profile & Settings**
- Edit name, school, and major
- Toggle notifications and dark mode preferences
- Sign-out button
- All changes saved to Firestore

---

## Architecture

The app follows an MVVM-like pattern with SwiftUI's `@Observable` macro for reactive state management and Firebase as the backend.

```
HelpfulApp
  └─ ContentView (auth routing)
       ├─ AuthFlowView (not authenticated)
       │    ├─ LoginView
       │    └─ SignUpView
       ├─ OnboardingView (authenticated, onboarding incomplete)
       └─ MainTabView (authenticated, onboarding complete)
            ├─ HomeView (Dashboard)
            ├─ BudgetView
            ├─ TransactionsView
            ├─ GoalsView
            ├─ DocumentsView
            ├─ SemesterCalcView (Tools)
            │    ├─ GPACalculatorView
            │    └─ CostCalculatorView
            └─ OpportunitiesTabView (Discover)
                 ├─ OpportunityDiscoverView (swipe cards)
                 └─ SavedOpportunitiesView
```

**Data flow:**

- `AuthViewModel` manages authentication state and is injected into the environment at the app root.
- `MainTabView` creates and owns the five feature ViewModels (`BudgetViewModel`, `TransactionViewModel`, `GoalViewModel`, `DocumentViewModel`, `OpportunityViewModel`) and injects them into the environment.
- Each ViewModel subscribes to Firestore snapshot listeners for real-time data.
- All Firestore and Firebase Storage operations go through the singleton `FirestoreService`.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI (iOS 17+) |
| State Management | `@Observable` macro (Observation framework) |
| Authentication | Firebase Auth (email/password) |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Dependency Manager | Swift Package Manager |
| Concurrency | Swift async/await, `@MainActor` |
| External API | RapidAPI JSearch (scholarship & internship listings) |

**Firebase SDK version:** 12.9.0

---

## Project Structure

```
Helpful/
├── Helpful.xcodeproj/          # Xcode project with SPM dependencies
└── Helpful/
    ├── HelpfulApp.swift         # @main entry point, Firebase configuration
    ├── ContentView.swift        # Root view: auth routing + onboarding gate
    ├── GoogleService-Info.plist # Firebase config (not committed to public repos)
    ├── Assets.xcassets/         # App icon, accent color, images
    │
    ├── // --- Theme ---
    ├── AppTheme.swift           # Colors, gradients, reusable UI components
    │
    ├── // --- Auth ---
    ├── AuthViewModel.swift      # Auth state, login, signup, profile fetch
    ├── AuthFlowView.swift       # Login/signup container with transitions
    ├── LoginView.swift          # Login screen
    ├── SignUpView.swift         # Signup screen with password strength bar
    ├── OnboardingView.swift     # 3-step post-signup onboarding flow
    │
    ├── // --- Data Models ---
    ├── User.swift               # AppUser model (profile, settings)
    ├── Budget.swift             # Budget model
    ├── Transaction.swift        # Transaction model (with receiptURL)
    ├── Goal.swift               # Goal model (with emoji)
    ├── Document.swift           # UserDocument model
    ├── Opportunity.swift        # Opportunity model (scholarship/internship)
    │
    ├── // --- Services ---
    ├── FirestoreService.swift   # All Firebase operations (Firestore + Storage)
    ├── OpportunityService.swift # JSearch API client for fetching opportunities
    │
    ├── // --- ViewModels ---
    ├── BudgetViewModel.swift    # Budget CRUD, spending updates, listeners
    ├── TransactionViewModel.swift # Transaction CRUD, grouping, listeners
    ├── GoalViewModel.swift      # Goal CRUD, progress updates, listeners
    ├── DocumentViewModel.swift  # Document upload/delete, listeners
    ├── OpportunityViewModel.swift # Card stack, save/dismiss/undo, API + Firestore sync
    │
    ├── // --- Main App Views ---
    ├── MainTabView.swift        # 7-tab TabView container
    ├── HomeView.swift           # Dashboard with cards, quick actions, recent txns
    ├── ProfileView.swift        # User profile and settings editor
    │
    ├── // --- Budget Views ---
    ├── BudgetView.swift         # Budget list with progress bars
    ├── AddBudgetView.swift      # Add budget sheet
    │
    ├── // --- Transaction Views ---
    ├── TransactionsView.swift   # Transaction list grouped by date
    ├── AddTransactionView.swift # Add transaction sheet with receipt picker
    ├── TransactionDetailView.swift # Full transaction detail with receipt image
    │
    ├── // --- Goal Views ---
    ├── GoalsView.swift          # Goal list with emoji cards
    ├── AddGoalView.swift        # Add goal sheet with emoji picker
    │
    ├── // --- Document Views ---
    ├── DocumentsView.swift      # Document list with open/delete
    ├── AddDocumentView.swift    # File picker + upload sheet
    │
    ├── // --- Tools Views ---
    ├── SemesterCalcView.swift   # Segmented picker (GPA vs Cost)
    ├── GPACalculatorView.swift  # GPA calculator with course list
    ├── CostCalculatorView.swift # Semester cost calculator
    │
    ├── // --- Opportunity Discovery Views ---
    ├── OpportunitiesTabView.swift      # Segmented picker (Discover vs Saved)
    ├── OpportunityDiscoverView.swift   # Tinder-style card stack with swipe UI
    ├── SwipeableCardView.swift         # Individual swipeable card with drag gesture
    ├── SavedOpportunitiesView.swift    # List of saved/favorited opportunities
    │
    └── // --- Config ---
    └── Secrets.plist            # API keys (gitignored)
```

---

## Firebase Backend

### Firestore Database Schema

All user data is stored under a per-user document path:

```
users/{uid}
├── name: String
├── email: String
├── createdAt: Timestamp
├── hasCompletedOnboarding: Bool
├── profile: Map
│   ├── firstName: String
│   ├── lastName: String
│   ├── school: String
│   ├── major: String
│   └── birthday: Timestamp (optional)
├── settings: Map
│   ├── notificationsEnabled: Bool
│   └── darkMode: Bool
│
├── budgets/ (subcollection)
│   └── {budgetId}
│       ├── month: String
│       ├── total: Double
│       ├── spent: Double
│       └── createdAt: Timestamp
│
├── transactions/ (subcollection)
│   └── {transactionId}
│       ├── amount: Double
│       ├── category: String
│       ├── note: String
│       ├── date: Timestamp
│       └── receiptURL: String (optional)
│
├── goals/ (subcollection)
│   └── {goalId}
│       ├── title: String
│       ├── emoji: String
│       ├── targetAmount: Double
│       ├── currentAmount: Double
│       └── deadline: Timestamp
│
├── documents/ (subcollection)
│   └── {documentId}
│       ├── title: String
│       ├── fileName: String
│       ├── downloadURL: String
│       └── uploadedAt: Timestamp
│
├── savedOpportunities/ (subcollection)
│   └── {externalId}
│       ├── title: String
│       ├── employer: String
│       ├── descriptionText: String
│       ├── location: String
│       ├── type: String (Scholarship | Internship)
│       ├── applyURL: String
│       ├── datePosted: Timestamp
│       ├── savedAt: Timestamp
│       └── externalId: String
│
└── dismissedOpportunities/ (subcollection)
    └── {externalId}
        └── dismissedAt: Timestamp
```

### Firebase Storage Structure

```
users/{uid}/
├── receipts/{uuid}.jpg      # Transaction receipt photos
└── documents/{fileName}     # Uploaded PDFs and images
```

### Real-Time Listeners

The app uses Firestore snapshot listeners (`addSnapshotListener`) on each subcollection so the UI updates in real time when data changes on the server. Listeners are started when `MainTabView` appears and stopped when it disappears.

---

## Data Models

All models conform to `Codable` and `Identifiable`. They use Firestore's `@DocumentID` property wrapper to automatically capture the Firestore document ID.

| Model | File | Key Fields |
|-------|------|-----------|
| `AppUser` | `User.swift` | name, email, createdAt, hasCompletedOnboarding, profile (school, major, birthday), settings |
| `Budget` | `Budget.swift` | month, total, spent, createdAt; computed: remaining, progress |
| `Transaction` | `Transaction.swift` | amount, category, note, date, receiptURL; computed: parsedCategory |
| `Goal` | `Goal.swift` | title, emoji, targetAmount, currentAmount, deadline; computed: progress, remaining |
| `UserDocument` | `Document.swift` | title, fileName, downloadURL, uploadedAt |
| `Opportunity` | `Opportunity.swift` | title, employer, descriptionText, location, type (OpportunityType), applyURL, datePosted, savedAt, externalId |

Models with complex schemas (`Goal`, `Transaction`, `AppUser`, `Opportunity`) include custom `init(from decoder:)` implementations that provide default values for any missing fields, ensuring backward compatibility with older Firestore documents.

---

## App Flow

1. **Launch** -- `HelpfulApp` configures Firebase, creates `AuthViewModel`, and renders `ContentView`.
2. **Auth Check** -- `ContentView` observes `auth.isAuthenticated`:
   - Not authenticated: shows `AuthFlowView` (login/signup).
   - Authenticated but onboarding incomplete: shows `OnboardingView`.
   - Authenticated and onboarding complete: shows `MainTabView`.
3. **Signup** -- Creates a Firebase Auth user, then writes a user profile document to Firestore via `FirestoreService.createUserProfile()`.
4. **Onboarding** -- Collects name, birthday, school, major. Saves to Firestore and sets `hasCompletedOnboarding = true`.
5. **Main App** -- `MainTabView` initializes five ViewModels and starts Firestore snapshot listeners. The user navigates between 7 tabs.
6. **CRUD Operations** -- All create/read/update/delete operations go through `FirestoreService`. ViewModels use optimistic local removal for deletes (item disappears immediately, Firestore delete happens async).

---

## Views

### Authentication

- **`AuthFlowView`** -- Container that toggles between `LoginView` and `SignUpView` with a slide animation.
- **`LoginView`** -- Gradient background, styled text fields for email/password, gradient login button.
- **`SignUpView`** -- Matching design with name field, password confirmation, and a password strength indicator bar.
- **`OnboardingView`** -- 3-page `TabView` (Welcome, About You, All Set) using `.page` style.

### Main Tabs

- **`HomeView`** -- Dashboard with greeting, 4 tappable gradient summary cards, horizontal quick-action buttons, and a recent transactions list. Transactions support swipe-to-delete and tap-to-detail.
- **`BudgetView`** -- List of budget cards with month, total, progress bar, spent/remaining amounts. FAB to add. Swipe to delete.
- **`TransactionsView`** -- Date-grouped transaction list with category icons. FAB to add. Swipe to delete (also rolls back budget spent). Tap to view detail.
- **`GoalsView`** -- Compact emoji-based goal cards with progress bars. FAB to add. Swipe to delete. Menu to add funds.
- **`DocumentsView`** -- Row-based document list with file-type icons. FAB to upload. Swipe to delete. Tap link to open.
- **`SemesterCalcView`** -- Segmented picker switching between `GPACalculatorView` and `CostCalculatorView`. Both have FABs and swipe-to-delete.
- **`OpportunitiesTabView`** -- Segmented picker switching between `OpportunityDiscoverView` and `SavedOpportunitiesView`.
- **`OpportunityDiscoverView`** -- Tinder-style card stack with swipeable cards. Includes a type filter (All/Scholarships/Internships), action buttons (dismiss, undo, save), and pagination. Cards show title, employer, location, type badge, and description.
- **`SwipeableCardView`** -- Individual card with `DragGesture` tracking. Rotates proportionally to horizontal drag. Green "SAVE" and red "PASS" overlays appear based on drag direction. Flies off screen when swipe threshold is exceeded.
- **`SavedOpportunitiesView`** -- List of saved opportunities with swipe-to-unfavorite. Tap a row to open the application URL in Safari.

### Detail / Add Sheets

- **`AddBudgetView`** -- Month picker and amount field.
- **`AddTransactionView`** -- Amount, category picker, note, and `PhotosPicker` for receipt capture. Auto-updates the current month's budget.
- **`AddGoalView`** -- Title, emoji picker (horizontal scroll), target amount, and deadline.
- **`AddDocumentView`** -- Title field and `.fileImporter` for PDFs/images. Shows upload progress.
- **`TransactionDetailView`** -- Full transaction info (category, amount, date, note) with receipt image via `AsyncImage`. Includes delete button.
- **`ProfileView`** -- Editable name, school, major. Notification/dark mode toggles. Sign-out button.

---

## ViewModels

All ViewModels use the `@Observable` macro and `@MainActor` isolation. They are injected into the SwiftUI environment via `.environment()`.

| ViewModel | Responsibilities |
|-----------|-----------------|
| `AuthViewModel` | Auth state listener, login, signup, profile fetch, sign out, error mapping |
| `BudgetViewModel` | Budget CRUD, `addSpending(amount:)` and `subtractSpending(amount:)` for syncing with transactions, snapshot listener |
| `TransactionViewModel` | Transaction CRUD, date grouping, recent transactions (last 5), total spent, snapshot listener |
| `GoalViewModel` | Goal CRUD, progress updates (`updateProgress`), total saved/target, snapshot listener |
| `DocumentViewModel` | Document upload/delete via Firebase Storage + Firestore metadata, snapshot listener |
| `OpportunityViewModel` | Fetches opportunities from JSearch API, manages card stack, save/dismiss/undo, Firestore sync for saved & dismissed, pagination |

**Optimistic Deletion:** All ViewModels remove items from the local array immediately before awaiting the async Firestore delete. If the delete fails, the data is re-fetched to restore state. Debug print statements log nil-ID guards and failures.

---

## Services

### `FirestoreService`

Singleton (`FirestoreService.shared`) that handles all backend communication. Organized into sections:

- **User Profile** -- create, fetch, update profile/settings/name, complete onboarding
- **Budgets** -- add, fetch, delete, update spent
- **Transactions** -- add, fetch, delete
- **Receipts** -- upload image to Storage, delete from Storage
- **Goals** -- add, fetch, delete, update progress
- **Documents** -- upload file to Storage + save metadata, fetch, delete (Storage + Firestore)
- **Saved Opportunities** -- save, fetch, unsave, listen to saved opportunities
- **Dismissed Opportunities** -- dismiss, fetch dismissed IDs, undismiss
- **Snapshot Listeners** -- real-time listeners for budgets, transactions, goals, documents, and saved opportunities

All methods use `async/await` and throw on failure. The service resolves the current user's UID from `Auth.auth().currentUser?.uid` and scopes all data under `users/{uid}/`.

### `OpportunityService`

Singleton (`OpportunityService.shared`) that handles API communication with the RapidAPI JSearch endpoint. Reads the API key from `Secrets.plist` at runtime. Methods:

- **`fetchOpportunities(query:type:page:perPage:)`** -- Queries the JSearch API for internships, scholarships, or both. Parses the JSON response into `[Opportunity]` models. Handles pagination, rate limiting, and network errors.
- Infers opportunity type (scholarship vs internship) based on title/description keywords when not explicitly filtered.

---

## Theming

Defined in `AppTheme.swift`:

- **`AppColors`** -- Vibrant color palette (coral, peach, teal, mint, purple, lavender, skyBlue, green, yellow) plus semantic colors (cardBackground, secondaryBackground).
- **`AppGradients`** -- Predefined linear gradients (primary coral-to-orange, teal, purple, blue, discover purple-to-skyBlue, auth background).
- **`GradientButtonStyle`** -- Reusable `ButtonStyle` with gradient fill, rounded corners, and press animation.
- **`StyledTextField`** -- Custom text field component with SF Symbol icon, rounded background, and keyboard configuration.
- **`CardModifier`** -- View modifier (`.cardStyle()`) adding padding, background, rounded corners, and shadow.
- **`GradientCard`** -- Generic gradient-background card container.
- **`TransactionCategory`** -- Enum with 8 categories, each mapped to an SF Symbol icon and color.

---

## Setup

### Prerequisites

- Xcode 15+ (Swift 5.9+)
- iOS 17+ deployment target
- A Firebase project with Auth, Firestore, and Storage enabled

### Steps

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd Helpful
   ```

2. Open the project in Xcode:
   ```bash
   open Helpful.xcodeproj
   ```

3. Add your own `GoogleService-Info.plist` from the [Firebase Console](https://console.firebase.google.com/):
   - Create an iOS app in your Firebase project
   - Download the config file
   - Replace `Helpful/GoogleService-Info.plist`

4. Enable Firebase services in the console:
   - **Authentication** -- enable Email/Password sign-in
   - **Cloud Firestore** -- create a database (start in test mode or configure security rules)
   - **Storage** -- enable Firebase Storage

5. Set up the RapidAPI key for Opportunity Discovery:
   - Sign up at [rapidapi.com](https://rapidapi.com) (free)
   - Subscribe to the [JSearch API](https://rapidapi.com/letscrape-6bRBa3QguO5/api/jsearch) free tier (500 requests/month)
   - Copy your API key from the RapidAPI dashboard
   - Open `Helpful/Secrets.plist` and replace `YOUR_RAPIDAPI_KEY_HERE` with your key
   - Note: `Secrets.plist` is gitignored to keep your key private

6. Build and run on a simulator or device.

### Firestore Security Rules (Recommended)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Storage Security Rules (Recommended)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

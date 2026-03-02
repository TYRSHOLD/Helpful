import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
final class AuthViewModel {

    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    var userName: String = ""
    var currentUser: AppUser?

    @ObservationIgnored
    private var authHandle: AuthStateDidChangeListenerHandle?

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth State Listener

    func startListening() {
        guard authHandle == nil else { return }
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if user != nil {
                    self.isAuthenticated = true
                    await self.fetchUserProfile()
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.userName = ""
                }
            }
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = friendlyError(error)
        }

        isLoading = false
    }

    // MARK: - Sign Up

    func signUp(
        name: String,
        email: String,
        password: String,
        confirm: String
    ) async {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == confirm else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth()
                .createUser(withEmail: email, password: password)

            let uid = result.user.uid
            try await FirestoreService.shared.createUserProfile(
                uid: uid,
                name: name,
                email: email
            )
            self.userName = name
        } catch {
            errorMessage = friendlyError(error)
        }

        isLoading = false
    }

    // MARK: - Fetch Profile

    func fetchUserProfile() async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        let uid = firebaseUser.uid

        do {
            if let user = try await FirestoreService.shared.fetchUser(uid: uid) {
                self.currentUser = user
                self.userName = user.name
            } else {
                let name = firebaseUser.displayName ?? ""
                let email = firebaseUser.email ?? ""
                try await FirestoreService.shared.createUserProfile(
                    uid: uid,
                    name: name,
                    email: email
                )
                self.currentUser = AppUser(name: name, email: email)
                self.userName = name
            }
        } catch {
            print("Failed to fetch profile:", error)
        }
    }

    // MARK: - Logout

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Friendly Errors

    private func friendlyError(_ error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain else {
            return error.localizedDescription
        }
        switch AuthErrorCode(rawValue: nsError.code) {
        case .invalidEmail:
            return "That email address isn't valid."
        case .emailAlreadyInUse:
            return "An account with that email already exists."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .wrongPassword, .invalidCredential:
            return "Incorrect email or password."
        case .userNotFound:
            return "No account found with that email."
        case .networkError:
            return "Network error. Check your connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        default:
            return error.localizedDescription
        }
    }
}

import AppKit
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var user: User?
    @Published private(set) var isWorking = false
    @Published var lastError: String?

    private var authHandle: AuthStateDidChangeListenerHandle?

    private init() {
        self.user = Auth.auth().currentUser
        self.authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }

    /// Call once at app launch, after `FirebaseApp.configure()`.
    static func bootstrap() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            assertionFailure("Missing Firebase clientID — check GoogleService-Info.plist")
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    func signInWithGoogle() {
        guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
            lastError = "No window available to present sign-in."
            return
        }
        isWorking = true
        lastError = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: window) { [weak self] result, error in
            // Extract Sendable values before hopping to the main actor.
            let errorMessage = error?.localizedDescription
            let nsErr = error as NSError?
            let errorCode = nsErr.map { "\($0.domain):\($0.code)" }
            let hasResult = result != nil
            let idToken = result?.user.idToken?.tokenString
            let accessToken = result?.user.accessToken.tokenString

            Task { @MainActor in
                guard let self else { return }
                defer { self.isWorking = false }

                if let errorMessage {
                    print("[Auth] GIDSignIn error: \(errorMessage) [\(errorCode ?? "?")]")
                    self.lastError = "Google: \(errorMessage)"
                    return
                }
                guard let idToken, let accessToken else {
                    print("[Auth] GIDSignIn completed with no tokens (hasResult=\(hasResult))")
                    self.lastError = "No tokens returned from Google."
                    return
                }
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: accessToken
                )
                do {
                    _ = try await Auth.auth().signIn(with: credential)
                    print("[Auth] Firebase sign-in succeeded")
                } catch {
                    print("[Auth] Firebase sign-in failed: \(error)")
                    self.lastError = "Firebase: \(error.localizedDescription)"
                }
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Forward URL scheme callbacks from `AppDelegate.application(_:open:)`.
    func handle(url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

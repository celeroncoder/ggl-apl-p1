import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @ObservedObject private var auth = AuthService.shared

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let user = auth.user {
                    signedInRow(user: user)
                } else {
                    signedOutRow
                }
            }

            if let err = auth.lastError, auth.user == nil {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(err)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }

    private var signedOutRow: some View {
        HStack {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .foregroundColor(.secondary)
            Text("Not signed in")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                auth.signInWithGoogle()
            } label: {
                if auth.isWorking {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Text("Sign in with Google")
                }
            }
            .controlSize(.small)
            .disabled(auth.isWorking)
        }
    }

    private func signedInRow(user: User) -> some View {
        HStack(spacing: 8) {
            AvatarView(urlString: user.photoURL?.absoluteString)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(user.displayName ?? user.email ?? "Signed in")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                if let email = user.email, user.displayName != nil {
                    Text(email)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button("Sign out") { auth.signOut() }
                .controlSize(.small)
        }
    }
}

private struct AvatarView: View {
    let urlString: String?
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.secondary)
            }
        }
        .task(id: urlString) {
            guard let urlString, let url = URL(string: urlString) else { return }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = NSImage(data: data) {
                await MainActor.run { self.image = img }
            }
        }
    }
}

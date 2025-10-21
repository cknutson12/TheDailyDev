import SwiftUI
import Supabase

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task { await signIn() }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Sign In")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            
        }
        .padding()
    }
    
    
    // MARK: - Supabase Sign In
    func signIn() async {
        isLoading = true
        message = ""
        defer { isLoading = false }

        do {
            let session = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )

            // Successfully logged in
            isLoggedIn = true
            // Optionally, access session details
            let accessToken = session.accessToken
            // Store or use the access token as needed
        } catch {
            isLoggedIn = false
            message = "Sign-in failed: \(error.localizedDescription)"
        }
    }


}

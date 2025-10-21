import SwiftUI

struct SignUpView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var dateOfBirth = Date()
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .bold()
            
            TextField("Full Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.words)
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                .datePickerStyle(.wheel)
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task { await signUp() }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Create Account")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .padding()
    }
    
    // MARK: - Supabase Sign Up with Profile Data
    func signUp() async {
        isLoading = true
        message = ""
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
            
            // If sign-up was successful, create user profile
            let user = session.user
            isLoggedIn = true
            
            // Create user profile in the background
            Task {
                do {
                    try await createUserProfile(userId: user.id, name: name, dateOfBirth: dateOfBirth)
                } catch {
                    print("Failed to create user profile: \(error)")
                }
            }
            
            message = "Account created successfully!"
        } catch {
            isLoggedIn = false
            message = "Sign-up failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Create User Profile
    func createUserProfile(userId: UUID, name: String, dateOfBirth: Date) async throws {
        let formatter = ISO8601DateFormatter()
        let profileData = UserProfile(
            id: userId.uuidString,
            name: name,
            dateOfBirth: formatter.string(from: dateOfBirth),
            createdAt: formatter.string(from: Date())
        )
        
        // Use the authenticated client to insert the profile
        let response = try await SupabaseManager.shared.client
            .from("user_profiles")
            .insert(profileData)
            .execute()
    }
}

// MARK: - User Profile Model
struct UserProfile: Codable {
    let id: String
    let name: String
    let dateOfBirth: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case dateOfBirth = "date_of_birth"
        case createdAt = "created_at"
    }
}

import SwiftUI


struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            if isLoggedIn {
                HomeView(isLoggedIn: $isLoggedIn)
            } else {
                VStack(spacing: 20) {
                    Text("The Daily Dev")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 20)
                    
                    if showSignUp {
                        SignUpView(isLoggedIn: $isLoggedIn)
                    } else {
                        LoginView(isLoggedIn: $isLoggedIn)
                    }
                    
                    Button(action: {
                        showSignUp.toggle()
                    }) {
                        Text(showSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

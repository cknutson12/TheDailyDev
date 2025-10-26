//
//  ProfileView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/15/25.
//

import SwiftUI
import Supabase

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isSigningOut = false
    @State private var signOutError: String?
    @State private var progressHistory: [UserProgressWithQuestion] = []
    @State private var isLoadingHistory = false
    @State private var userName: String = ""
    @State private var categoryPerformances: [CategoryPerformance] = []
    @State private var isLoadingCategories = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // User Stats Header
                    if !userName.isEmpty {
                        Text("\(userName) Stats")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }

                    // Contributions Tracker (no duplicate header)
                    if isLoadingHistory {
                        VStack {
                            ProgressView("Loading your progress...")
                                .frame(maxWidth: .infinity, maxHeight: 200)
                        }
                    } else {
                        ContributionsTracker(progressHistory: progressHistory)
                            .padding(.horizontal)
                    }
                    
                    // Category Performance
                    if isLoadingCategories {
                        VStack {
                            ProgressView("Loading category performance...")
                                .frame(maxWidth: .infinity, maxHeight: 100)
                        }
                    } else {
                        CategoryPerformanceView(categoryPerformances: categoryPerformances)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            
            // Sign Out Button at Bottom
            VStack(spacing: 12) {
                if let error = signOutError {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(role: .destructive) {
                    Task { await signOut() }
                } label: {
                    if isSigningOut {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Signing Out...")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(isSigningOut)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await loadUserData()
            }
        }
    }
    
    // MARK: - Load User Data
    private func loadUserData() async {
        // Load user display name (prioritizes profile name over email)
        let displayName = await QuestionService.shared.getUserDisplayName()
        await MainActor.run {
            self.userName = displayName
        }
        
        // Load progress history and category performance
        await loadProgressHistory()
        await loadCategoryPerformance()
    }
    
    // MARK: - Load Progress History
    private func loadProgressHistory() async {
        isLoadingHistory = true
        
        let history = await QuestionService.shared.fetchUserProgressHistory()
        
        await MainActor.run {
            self.progressHistory = history
            self.isLoadingHistory = false
        }
    }
    
    // MARK: - Load Category Performance
    private func loadCategoryPerformance() async {
        isLoadingCategories = true
        
        let performances = await QuestionService.shared.calculateCategoryPerformance()
        
        await MainActor.run {
            self.categoryPerformances = performances
            self.isLoadingCategories = false
        }
    }
    
    // MARK: - Sign Out Function
    private func signOut() async {
        print("🔄 Starting sign out process...")
        isSigningOut = true
        signOutError = nil
        
        do {
            // Sign out from Supabase
            print("🔐 Calling Supabase sign out...")
            try await SupabaseManager.shared.client.auth.signOut()
            print("✅ Supabase sign out successful")
            
            // Update local state to return to login screen
            await MainActor.run {
                print("🔄 Updating UI state...")
                isLoggedIn = false
                isSigningOut = false
                print("📱 Dismissing ProfileView...")
                // Dismiss the ProfileView to return to HomeView, which will then show LoginView
                dismiss()
                print("✅ Sign out process completed")
            }
        } catch {
            print("❌ Sign out failed: \(error.localizedDescription)")
            await MainActor.run {
                signOutError = "Sign out failed: \(error.localizedDescription)"
                isSigningOut = false
            }
        }
    }
}


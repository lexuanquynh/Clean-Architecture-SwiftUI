//
//  BazelAppApp.swift
//  BazelApp
//
//  Created by Prank on 15/9/25.
//

import SwiftUI
import CoreDomain
import CoreData
import CorePresentation
import AuthenticationPresentation
import HomeFeedPresentation

@main
struct BazelApp: App {
    @StateObject private var sessionManager = SessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}



struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeFeedView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)
            
            Text("Search")
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            Text("Create")
                .tabItem {
                    Label("Create", systemImage: "plus.square.fill")
                }
                .tag(2)
            
            Text("Notifications")
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    HStack {
                        AsyncImage(url: URL(string: sessionManager.currentUser?.avatarURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        // test@example.com    password,
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionManager.currentUser?.name ?? "User")
                                .font(.headline)
                            Text(sessionManager.currentUser?.email ?? "email@example.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Settings Section
                Section("Settings") {
                    HStack {
                        Label("Edit Profile", systemImage: "person.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Privacy", systemImage: "lock")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Notifications", systemImage: "bell")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Content Section
                Section("Content") {
                    HStack {
                        Label("Your Posts", systemImage: "doc.text")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Saved Posts", systemImage: "bookmark")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Liked Posts", systemImage: "heart")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Support Section
                Section("Support") {
                    HStack {
                        Label("Help Center", systemImage: "questionmark.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("About", systemImage: "info.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Logout Section
                Section {
                    Button(role: .destructive, action: { showLogoutAlert = true }) {
                        HStack {
                            Spacer()
                            Text("Logout")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    sessionManager.clearSession()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

// MARK: - App Configuration
//extension BazelApp {
//    init() {
//        // Configure app appearance
//        setupAppearance()
//    }
//    
//    private func setupAppearance() {
//        // Navigation bar appearance
//        let navigationBarAppearance = UINavigationBarAppearance()
//        navigationBarAppearance.configureWithDefaultBackground()
//        
//        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
//        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
//        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
//        
//        // Tab bar appearance
//        let tabBarAppearance = UITabBarAppearance()
//        tabBarAppearance.configureWithDefaultBackground()
//        
//        UITabBar.appearance().standardAppearance = tabBarAppearance
//        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
//    }
//}


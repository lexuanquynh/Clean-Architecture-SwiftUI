//
//  ContentView.swift
//  BazelApp
//
//  Created by Prank on 15/9/25.
//

import SwiftUI
import CoreData
import AuthenticationPresentation

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        if sessionManager.isLoggedIn {
            // Main app with tab bar
            MainTabView()
        } else {
            // Authentication flow
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}

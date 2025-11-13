//
//  ContentView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI

/// Main entry view for the application.
/// Contains tab navigation and ensures full-screen display.
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        // Main tab-based layout
        TabView {
            // Dashboard tab
            NavigationStack {
                ModernDashboardView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("Dashboard")
                    // Extend background beyond safe areas
                    .ignoresSafeArea(.all, edges: .all)
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.pie.fill")
            }
            
            // Scan tab
            NavigationStack {
                ModernScanView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("Scan")
                    // Extend background beyond safe areas
                    .ignoresSafeArea(.all, edges: .all)
            }
            .tabItem {
                Label("Scan", systemImage: "camera.viewfinder")
            }
        }
        // Accent color for selected tab
        .accentColor(.blue)
        // Makes sure entire view (including status bar & bottom areas) is visible
        .ignoresSafeArea(.all, edges: .all)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

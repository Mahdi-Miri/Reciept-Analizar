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
        // 1. Wrap in a ZStack to layer the background
        ZStack {
            // 2. Add the animated background as the bottom-most layer
            // This provides the blue/white theme you requested
            AnimatedBackgroundView()
            
            // 3. Your TabView now sits on top of the background
            TabView {
                // Dashboard tab
                NavigationStack {
                    ModernDashboardView()
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Dashboard")
                    // 4. We remove ignoresSafeArea from here
                }
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                
                // Scan tab
                NavigationStack {
                    ModernScanView()
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Scan")
                    // 4. We remove ignoresSafeArea from here too
                }
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
            }
            // Accent color for selected tab
            .accentColor(.blue)
            // 5. We removed the ignoresSafeArea from the TabView itself
        }
        // 6. Apply ONE ignoresSafeArea to the outer ZStack
        // This ensures the background stretches edge-to-edge
        .ignoresSafeArea(.all, edges: .all)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

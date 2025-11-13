//
//  ContentView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//
//  *** THIS FILE FIXES THE LAYOUT AND TAB BAR ***
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    // 1. State to manage the selected tab
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        // 2. ZStack to layer everything
        ZStack {
            
            // 3. LAYER 1: THE BACKGROUND
            // This view ignores the safe area and fills
            // the entire screen, including behind the status bar
            // and home indicator.
            AnimatedBackgroundView()
                .ignoresSafeArea(.all, edges: .all)

            // 4. LAYER 2: THE CONTENT + TAB BAR
            // This VStack RESPECTS the safe area by default.
            VStack(spacing: 0) {
                
                // 5. The main content (Dashboard or Scan)
                switch selectedTab {
                case .dashboard:
                    NavigationStack {
                        ModernDashboardView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("Dashboard")
                    }
                case .scan:
                    NavigationStack {
                        // Assuming ModernScanView exists
                        ModernScanView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("Scan")
                    }
                }
                
                // 6. Spacer pushes the tab bar to the bottom
                // of the VStack's available space.
                Spacer()
                
                // 7. The tab bar sits AT THE BOTTOM of the
                // SAFE AREA, so it will not be cut off.
                FloatingTabBar(selectedTab: $selectedTab)
            }
            // 8. We DO NOT apply .ignoresSafeArea to this VStack
        }
        // 9. We DO NOT apply .ignoresSafeArea to the ZStack
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}

//
//  ContentView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//
//  *** THIS IS THE CORRECTED LAYOUT FILE ***
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
            // ONLY the background ignores the safe area
            // and fills the entire screen.
            AnimatedBackgroundView()
                .ignoresSafeArea(.all, edges: .all)

            // 4. LAYER 2: THE CONTENT + TAB BAR
            // This VStack RESPECTS the safe area by default.
            VStack(spacing: 0) {
                
                // 5. The main content
                switch selectedTab {
                case .dashboard:
                    NavigationStack {
                        ModernDashboardView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("Dashboard")
                    }
                case .scan:
                    NavigationStack {
                        ModernScanView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("Scan")
                    }
                }
                
                // 6. Spacer pushes the tab bar to the bottom
                Spacer()
                
                // 7. The tab bar sits AT THE BOTTOM of the
                // SAFE AREA, so it won't be cut off.
                FloatingTabBar(selectedTab: $selectedTab)
            }
            // 8. NO .ignoresSafeArea modifier on this VStack
        }
        // 9. NO .ignoresSafeArea modifier on the ZStack
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}

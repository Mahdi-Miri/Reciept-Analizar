// ContentView.swift
// ScontrinoSmartApp
// Modern fullscreen root with floating tab bar and global animated background.
// Replace existing ContentView with this file.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .dashboard

    // small enum to manage tabs
    enum Tab {
        case dashboard, scan
    }

    var body: some View {
        ZStack {
            // LAYER 1: Global animated gradient background covers whole screen
            AnimatedBackgroundView()
                .ignoresSafeArea() // ensure full-screen background (fixes black bars)

            // LAYER 2: Main content area
            VStack(spacing: 0) {
                // Use safe area inset for top spacing so content doesn't collide with notch
                Spacer(minLength: 0)
                
                Group {
                    switch selectedTab {
                    case .dashboard:
                        ModernDashboardView()
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    case .scan:
                        ModernScanView()
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .animation(.interactiveSpring(response: 0.45, dampingFraction: 0.8), value: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // LAYER 3: FloatingTabBar
                FloatingTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12) // leave space for home indicator
            }
            .ignoresSafeArea(.keyboard) // keep tab bar visible above keyboard
        }
        .preferredColorScheme(.light) // pick a scheme (optional)
    }
}

// Preview
#Preview {
    ContentView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}

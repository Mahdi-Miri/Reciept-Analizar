//
//  ScontrinoSmartApp.swift
//  ScontrinoSmartApp
//
//  Main App Entry Point
//

import SwiftUI

@main
struct ScontrinoSmartApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//
//  ContentView.swift
//  Main tab view with floating scan button
//

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    @State private var showingScanner = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                
                // Receipts Tab
                NavigationView {
                    ReceiptsListView()
                }
                .tabItem {
                    Label("Receipts", systemImage: "doc.text.fill")
                }
                .tag(1)
            }
            .environmentObject(appState)
            
            // Floating Action Button (Scan Button)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingScanner = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            ScannerView()
                .environmentObject(appState)
        }
    }
}

#Preview {
    ContentView()
}

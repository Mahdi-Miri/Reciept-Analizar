//
//  ContentView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // Main TabView navigation
        TabView {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
            
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }
        }
        // Use a consistent blue theme (from user memory)
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}

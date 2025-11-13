//
//  GroceryScanLiteApp.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI

/// Main App entry point.
/// Creates a single shared instance of AppState and injects it into all views.
@main
struct GroceryScanLiteApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                // Ensures the root view takes the full screen on all devices
                .ignoresSafeArea(.all, edges: .all)
        }
    }
}

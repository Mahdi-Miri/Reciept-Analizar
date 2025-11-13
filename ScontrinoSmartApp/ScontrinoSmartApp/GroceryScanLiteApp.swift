//
//  GroceryScanLiteApp.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//
import SwiftUI

@main
struct GroceryScanLiteApp: App {
    // Create the shared app state object once here
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the shared state into the environment
                .environmentObject(appState)
        }
    }
}

//
//  ScontrinoSmartApp.swift
//  
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import SwiftData

@main
struct ScontrinoSmartApp: App {

    // 1. Setup the SwiftData Container
    // This creates the database for our models
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Tell the container WHICH models it needs to manage
            modelContainer = try ModelContainer(for: Receipt.self, ReceiptItem.self, Budget.self)
        } catch {
            // If the database fails to load, we stop.
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            
            // --- This is the main TabView ---
            // It will create a tab bar at the bottom of the screen
            TabView {
                
                // --- Tab 1: Dashboard ---
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.pie.fill")
                    }
                
                // --- Tab 2: Budgets ---
                BudgetView()
                    .tabItem {
                        Label("Budgets", systemImage: "creditcard.fill")
                    }
                
                // --- Tab 3: Insights ---
                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "lightbulb.fill")
                    }
            }
            // 2. Inject the SwiftData Container
            // This line makes the database available to ALL views
            // inside the TabView (Dashboard, Budget, Insights).
            // This is why @Query and @Environment(\.modelContext) work.
            .modelContainer(modelContainer)
        }
    }
}

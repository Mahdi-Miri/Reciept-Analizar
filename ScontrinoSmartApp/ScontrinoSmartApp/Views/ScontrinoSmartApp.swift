//
//  Created by Mahdi Miri on 13/11/25.
//
//  *** THIS IS YOUR MAIN APP FILE ***
//

import SwiftUI

@main
struct ScontrinoSmartApp: App {
    
    // 1. Create a single instance of your AppState here.
    // This @StateObject will manage all your app's data.
    @StateObject private var appState = AppState(receipts: SampleData.receipts)

    var body: some Scene {
        WindowGroup {
            // 2. Load ContentView as the starting view
            ContentView()
                // 3. Pass the appState into the environment
                // so all other views (like ModernDashboardView) can access it.
                .environmentObject(appState)
        }
    }
}

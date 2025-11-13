//
//  AppState.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import Foundation
import Combine

// This is the shared state for the entire app.
// It holds all scanned receipts and provides computed properties for the dashboard.
class AppState: ObservableObject {
    
    // @Published notifies all views when the receipts array changes
    @Published var receipts: [ScannedReceipt]

    init(receipts: [ScannedReceipt] = SampleData.receipts) {
        self.receipts = receipts
    }
    var totalSpend: Double {
        // This sums up the 'total' from every receipt in the array
        receipts.reduce(0) { $0 + $1.total }
    }
    
    var categorySpendingData: [CategorySpending] {
        // Flatten all items from all receipts
        let allItems = receipts.flatMap { $0.items }
        
        // Group items by category
        let groupedItems = Dictionary(grouping: allItems) { $0.category }
        
        // Sum the prices for each category
        let spending = groupedItems.map { (category, items) in
            let totalAmount = items.reduce(0) { $0 + $1.price }
            return CategorySpending(category: category, amount: totalAmount)
        }
        
        return spending.sorted { $0.amount > $1.amount }
    }
    
    // --- Public Methods ---
    
    func addReceipt(_ receipt: ScannedReceipt) {
        // Insert at the top for chronological order
        receipts.insert(receipt, at: 0)
    }
    
}

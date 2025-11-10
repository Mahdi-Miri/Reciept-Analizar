//
//  DataModels.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//

import Foundation
import SwiftData

// --- Receipt Data Model ---
// This class holds the main information for each scanned receipt.
@Model
final class Receipt {
    
    // A unique identifier for each receipt
    @Attribute(.unique) var id: UUID
    
    // Store name (extracted by ML/Logic)
    var storeName: String
    
    // The final total amount (extracted by ML/Logic)
    var totalAmount: Double
    
    // The transaction date (extracted by ML/Logic)
    var transactionDate: Date
    
    // The category (predicted by ML, e.g., "Groceries")
    var category: String
    
    // The raw OCR text, for search or debug
    var rawText: String
    
    // A list of items in the receipt
    // .cascade means if the receipt is deleted, its items are also deleted.
    @Relationship(deleteRule: .cascade) var items: [ReceiptItem]?
    
    // Initializer
    init(id: UUID = UUID(),
         storeName: String,
         totalAmount: Double,
         transactionDate: Date,
         category: String,
         rawText: String,
         items: [ReceiptItem]? = nil) {
        
        self.id = id
        self.storeName = storeName
        self.totalAmount = totalAmount
        self.transactionDate = transactionDate
        self.category = category
        self.rawText = rawText
        self.items = items
    }
}


// --- Receipt Item Data Model ---
// This class holds each line item from the receipt.
@Model
final class ReceiptItem {
    
    // Product name (extracted by ML)
    var name: String
    
    // Quantity (extracted by ML)
    var quantity: Int
    
    // Price (extracted by ML)
    var price: Double
    
    // Initializer
    init(name: String, quantity: Int, price: Double) {
        self.name = name
        self.quantity = quantity
        self.price = price
    }
}


// --- Budget Data Model ---
// This class holds the user's budget for a specific category/month.
@Model
final class Budget {
    
    // The category this budget applies to (e.g., "Groceries")
    var category: String
    
    // The total amount for this budget
    var amount: Double
    
    // The month and year this budget is for
    var month: Int // 1-12
    var year: Int
    
    // A unique ID to prevent duplicate budgets
    // e.g., "Groceries-2025-11"
    @Attribute(.unique) var id: String
    
    // This is inside your 'Budget' class in DataModels.swift
        
        init(category: String, amount: Double, date: Date) {
            // 1. Assign the simple properties first
            self.category = category
            self.amount = amount
            
            // 2. Calculate month and year, storing them in
            //    *local* variables, not 'self'.
            let calendar = Calendar.current
            let monthComponent = calendar.component(.month, from: date)
            let yearComponent = calendar.component(.year, from: date)
            
            // 3. Now assign the calculated components to 'self'
            self.month = monthComponent
            self.year = yearComponent
            
            // 4. *After* all other properties are set,
            //    we can safely build the 'id'.
            self.id = "\(category)-\(yearComponent)-\(monthComponent)"
        }
}

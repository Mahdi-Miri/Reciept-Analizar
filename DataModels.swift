import Foundation
import SwiftData

@Model
final class Receipt {
    
    @Attribute(.unique) var id: UUID
    
    var storeName: String
    
    var totalAmount: Double
    
    var transactionDate: Date
    
    var category: String
    
    var rawText: String
    
    @Relationship(deleteRule: .cascade) var items: [ReceiptItem]?
    
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




@Model
final class ReceiptItem {
    
    var name: String
    
    var quantity: Int
    
    var price: Double
    
    init(name: String, quantity: Int, price: Double) {
        self.name = name
        self.quantity = quantity
        self.price = price
    }
}
// --- Budget Data Model ---
// Add this class to your DataModels.swift file

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
    
    init(category: String, amount: Double, date: Date) {
        self.category = category
        self.amount = amount
        
        let calendar = Calendar.current
        self.month = calendar.component(.month, from: date)
        self.year = calendar.component(.year, from: date)
        
        // Create the unique ID
        self.id = "\(category)-\(self.year)-\(self.month)"
    }
}

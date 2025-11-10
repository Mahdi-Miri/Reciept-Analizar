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

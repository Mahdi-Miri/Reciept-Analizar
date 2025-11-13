//
//  GroceryModels.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//
import SwiftUI

// Enum for food categories, used for classification and charting
enum Category: String, CaseIterable, Identifiable, Hashable {
    case fruits = "Fruits"
    case dairy = "Dairy"
    case snacks = "Snacks"
    case pantry = "Pantry"
    case meat = "Meat"
    case beverages = "Beverages"
    case other = "Other"
    
    var id: String { self.rawValue }

    // Color used for charts
    var color: Color {
        switch self {
        case .fruits: return .green
        case .dairy: return .blue
        case .snacks: return .orange
        case .pantry: return .brown
        case .meat: return .red
        case .beverages: return .purple
        case .other: return .gray
        }
    }
}

// Represents a single item on a receipt
struct GroceryItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let price: Double
    let category: Category
    
    init(id: UUID = UUID(), name: String, price: Double, category: Category) {
        self.id = id
        self.name = name
        self.price = price
        self.category = category
    }
}

// Represents a fully scanned and parsed receipt
struct ScannedReceipt: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let items: [GroceryItem]
    
    var total: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    init(id: UUID = UUID(), date: Date = .now, items: [GroceryItem]) {
        self.id = id
        self.date = date
        self.items = items
    }
}

// A simple model for passing aggregated data to the chart view
struct CategorySpending: Identifiable {
    let id = UUID()
    let category: Category
    let amount: Double
}

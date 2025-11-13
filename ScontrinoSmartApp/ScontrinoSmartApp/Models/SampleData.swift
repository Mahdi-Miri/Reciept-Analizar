//
//  SampleData.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import Foundation

// Static sample data to populate the app on first launch
// This ensures the dashboard charts have something to display
struct SampleData {
    
    static let receipts: [ScannedReceipt] = [
        ScannedReceipt(
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
            items: [
                GroceryItem(name: "Organic Milk", price: 4.29, category: .dairy),
                GroceryItem(name: "Bananas", price: 1.89, category: .fruits),
                GroceryItem(name: "Tortilla Chips", price: 3.50, category: .snacks),
                GroceryItem(name: "Ground Beef 1lb", price: 5.99, category: .meat),
                GroceryItem(name: "Sourdough Bread", price: 4.49, category: .pantry)
            ]
        ),
        ScannedReceipt(
            date: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
            items: [
                GroceryItem(name: "Cheddar Cheese", price: 3.89, category: .dairy),
                GroceryItem(name: "Apples (Gala)", price: 2.99, category: .fruits),
                GroceryItem(name: "Orange Juice", price: 4.19, category: .beverages),
                GroceryItem(name: "Cookies", price: 3.29, category: .snacks)
            ]
        )
    ]
}

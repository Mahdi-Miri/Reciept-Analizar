//
//  CategoryClassifier.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import Foundation
import CoreML

// A simple rule-based classifier.
// This can be swapped out with a Core ML model.
struct CategoryClassifier {
    
    // --- Rule-Based Method (Fallback) ---
    
    static func classify(itemName: String) -> Category {
        let name = itemName.lowercased()
        
        // This is a simple keyword-based approach
        // A real-world app would use a more robust system or ML model
        
        if name.contains("apple") || name.contains("banana") || name.contains("orange") || name.contains("grapes") {
            return .fruits
        }
        if name.contains("milk") || name.contains("cheese") || name.contains("yogurt") || name.contains("butter") {
            return .dairy
        }
        if name.contains("chips") || name.contains("cookie") || name.contains("soda") || name.contains("cracker") {
            return .snacks
        }
        if name.contains("bread") || name.contains("pasta") || name.contains("flour") || name.contains("rice") {
            return .pantry
        }
        if name.contains("beef") || name.contains("chicken") || name.contains("pork") || name.contains("fish") {
            return .meat
        }
        if name.contains("juice") || name.contains("water") || name.contains("tea") || name.contains("coffee") {
            return .beverages
        }
        
        return .other
    }
    
    /*
    // --- Core ML Method (How to replace) ---
    
    static func classifyWithCoreML(itemName: String) -> Category {
        // 1. Ensure 'FoodCategoryClassifier.mlmodel' is added to the project target
        // 2. Generate the Swift model class (Xcode does this automatically)
        
        do {
            let config = MLModelConfiguration()
            let model = try FoodCategoryClassifier(configuration: config)
            
            // 3. Get prediction. Input name must match the model's expected input.
            let input = FoodCategoryClassifierInput(text: itemName)
            let prediction = try model.prediction(input: input)
            
            // 4. Map the output label (e.g., "Fruits") to the Category enum
            let categoryLabel = prediction.label
            return Category(rawValue: categoryLabel) ?? .other
            
        } catch {
            print("Error using Core ML classifier: \(error.localizedDescription)")
            // Fallback to rule-based if ML fails
            return classify(itemName: itemName)
        }
    }
    */
}

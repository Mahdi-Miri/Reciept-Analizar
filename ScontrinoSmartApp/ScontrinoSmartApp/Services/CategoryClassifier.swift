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
    
    // --- Core ML Method (How to replace) ---
    
    static func classify(itemName: String) -> Category {
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
}

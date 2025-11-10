//
//  AutoCategorizer.swift
//  
//
//  Created by Mahdi Miri on 10/11/25.
//

import Foundation
import CoreML
import NaturalLanguage // Apple's framework for NLP tasks

// MARK: - Auto-Categorizer
// This class is responsible for loading a custom Core ML model
// and using it to predict the category of a receipt.

class AutoCategorizer {
    
    // This holds our trained ML model.
    private let mlModel: NLModel
    
    // MARK: - Initializer
    // The initializer attempts to load the ML model when the class is created.
    init?() {
        do {
            // 1. Load the compiled Core ML model
            // IMPORTANT: You must create this "ReceiptCategoryClassifier.mlmodel" file
            // yourself using Apple's Create ML tool and your custom dataset.
            let compiledModelURL = Bundle.main.url(forResource: "ReceiptCategoryClassifier", withExtension: "mlmodelc")
            
            guard let modelURL = compiledModelURL else {
                print("Error: mlmodelc file not found. Did you add it to the project?")
                return nil
            }
            
            // 2. Initialize the NLModel with the compiled model
            self.mlModel = try NLModel(contentsOf: modelURL)
            
        } catch {
            print("Error loading NLModel: \(error.localizedDescription)")
            return nil // Initialization failed
        }
    }
    
    // MARK: - Categorization Function
    // This function takes text from the receipt (e.g., store name + items)
    // and returns a predicted category string.
    func categorize(text: String) -> String {
        
        // 1. Predict the label for the given text
        guard let predictedLabel = mlModel.predictedLabel(for: text) else {
            // If the model fails to predict, return a default category
            return "Pending"
        }
        
        // 2. Return the predicted category
        // The model will return "Groceries", "Restaurant", etc.
        return predictedLabel
    }
}

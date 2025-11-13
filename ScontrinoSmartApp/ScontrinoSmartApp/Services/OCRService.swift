//
//  OCRService.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import Vision
import UIKit

// This service handles the text recognition and parsing logic.
class OCRService {
    
    // Public function to recognize text from an array of images
    public func recognizeText(from images: [CGImage],
                              completion: @escaping (Result<ScannedReceipt, Error>) -> Void) {
        
        var allText = ""
        let textRequest = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("Text recognition error: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            // Collect text from all observations
            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            allText += recognizedText + "\n"
        }
        
        textRequest.recognitionLevel = .accurate
        
        // Process each image
        let requests = [textRequest]
        let dispatchGroup = DispatchGroup()

        for image in images {
            dispatchGroup.enter()
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                defer { dispatchGroup.leave() }
                try? handler.perform(requests)
            }
        }
        
        // After all images are processed, parse the collected text
        dispatchGroup.notify(queue: .main) {
            if allText.isEmpty {
                completion(.failure(NSError(domain: "OCRService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No text found."])))
                return
            }
            
            // Parse the text into GroceryItem objects
            let items = self.parseTextToItems(allText)
            
            if items.isEmpty {
                completion(.failure(NSError(domain: "OCRService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not parse any items."])))
            } else {
                // Create a new receipt and return it
                let receipt = ScannedReceipt(items: items)
                completion(.success(receipt))
            }
        }
    }
    
    // Simple rule-based parser
    // This looks for lines ending in a price (e.g., "Item Name 1.23" or "Item Name $1.23")
    private func parseTextToItems(_ text: String) -> [GroceryItem] {
        var items: [GroceryItem] = []
        let lines = text.split(separator: "\n")
        
        // Regex to find a price (e.g., 1.99 or $1.99) at the end of a line
        let priceRegex = try! NSRegularExpression(pattern: #"(.+?)\s+[$]?(\d+\.\d{2})$"#, options: .caseInsensitive)

        for line in lines {
            let lineStr = String(line)
            let range = NSRange(location: 0, length: lineStr.utf16.count)
            
            if let match = priceRegex.firstMatch(in: lineStr, options: [], range: range) {
                // Extract item name (Group 1)
                let nameRange = match.range(at: 1)
                let itemName = (lineStr as NSString).substring(with: nameRange).trimmingCharacters(in: .whitespaces)
                
                // Extract price (Group 2)
                let priceRange = match.range(at: 2)
                let priceString = (lineStr as NSString).substring(with: priceRange)
                
                if let price = Double(priceString), !itemName.isEmpty {
                    // Classify the item
                    let category = CategoryClassifier.classify(itemName: itemName)
                    let item = GroceryItem(name: itemName, price: price, category: category)
                    items.append(item)
                }
            }
        }
        
        // Avoid "TOTAL" or "SUBTOTAL" lines
        items.removeAll {
            let upperName = $0.name.uppercased()
            return upperName.contains("TOTAL") || upperName.contains("SUBTOTAL") || upperName.contains("TAX")
        }
        
        return items
    }
}

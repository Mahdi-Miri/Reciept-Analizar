//
//  ReceiptExtractor.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//

// FILE: ReceiptExtractor.swift (REPLACE THE ENTIRE FILE)

// FILE: ReceiptExtractor.swift (REPLACED)

import Foundation
import CoreML
import NaturalLanguage // We need this for NER

class ReceiptExtractor {
    
    // --- NEW: Load the NER (Word Tagger) model ---
    private let nerModel: NLModel?
    
    init() {
        // Try to load our custom Word Tagger model
        // Make sure you've trained and added "ItemTagger.mlmodel"
        do {
            let compiledModelURL = Bundle.main.url(forResource: "ItemTagger", withExtension: "mlmodelc")
            
            if let modelURL = compiledModelURL {
                self.nerModel = try NLModel(contentsOf: modelURL)
            } else {
                print("NER Model (ItemTagger.mlmodelc) not found.")
                self.nerModel = nil
            }
        } catch {
            print("Error loading NER model: \(error)")
            self.nerModel = nil
        }
    }

    // Main function to extract all data
    func extractData(from rawText: String) -> (storeName: String, total: Double?, date: Date?, items: [ReceiptItem]) {
        
        let lines = rawText.split(separator: "\n").map { String($0) }
        
        // Use Regex for these, as they are still reliable
        let storeName = findStoreName(from: lines)
        let total = findTotalAmount(from: rawText)
        let date = findTransactionDate(from: rawText)
        
        // --- NEW: Use NER to find items ---
        let items = findItems(from: lines)
        
        return (storeName, total, date, items)
    }
    
    // --- NEW: findItems using the NER Model ---
    private func findItems(from lines: [String]) -> [ReceiptItem] {
        guard let nerModel = self.nerModel else {
            print("NER model is not available. Skipping item extraction.")
            return [] // Return empty if model didn't load
        }
        
        var foundItems: [ReceiptItem] = []
        
        // 1. Get the list of labels the model knows (e.g., "PRODUCT_NAME", "QUANTITY")
        let labels = nerModel.labels
        
        // 2. Process each line of the receipt
        for line in lines {
            // We create a "tagger" for each line
            let tagger = NLTagger(tagSchemes: [.nameType])
            tagger.string = line
            tagger.setModels([nerModel], forTagScheme: .nameType)
            
            // 3. Find all the tagged words in that line
            let tags = tagger.tags(in: line.startIndex..<line.endIndex,
                                   unit: .word,
                                   scheme: .nameType,
                                   options: [.omitWhitespace, .omitPunctuation])
            
            // 4. Parse the tagged words
            var currentItemName = ""
            var currentQuantity = 1 // Default to 1
            var currentPrice: Double?
            
            for (tag, range) in tags {
                let word = String(line[range])
                
                guard let label = tag?.rawValue else { continue }
                
                switch label {
                case "PRODUCT_NAME":
                    // Append to product name (e.g., "Pizza" + "Margherita")
                    currentItemName += word + " "
                case "QUANTITY":
                    // Try to parse the quantity
                    if let intQty = Int(word) {
                        currentQuantity = intQty
                    } else if let doubleQty = Double(word) {
                        // Handle quantities like 1.5 (e.g., for kg)
                        currentQuantity = Int(doubleQty) // Or store as Double
                    }
                case "ITEM_PRICE":
                    // Try to parse the price
                    let priceString = word.replacingOccurrences(of: ",", with: ".")
                    currentPrice = Double(priceString)
                default:
                    // This is an "O" tag (Outside), so we ignore it
                    break
                }
            }
            
            // 5. After checking a full line, if we found a product and a price,
            // create the ReceiptItem object.
            if let price = currentPrice, !currentItemName.isEmpty {
                foundItems.append(ReceiptItem(
                    name: currentItemName.trimmingCharacters(in: .whitespaces),
                    quantity: currentQuantity,
                    price: price
                ))
            }
        }
        
        return foundItems
    }
    
    // --- (The Regex functions for Total, Date, and Store Name remain unchanged) ---
    
    private func findStoreName(from lines: [String]) -> String {
        return lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "Unknown Store"
    }
    
    private func findTotalAmount(from text: String) -> Double? {
        let pattern = #"(?i)(?:total|totale|amount|importo|balance due|pagato|net total)\s*[:=\s]?\s*(\d+([,\.]\d{1,2})?)"#
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            var potentialTotals: [Double] = []
            for match in matches {
                if match.numberOfRanges > 1 {
                    let amountRange = match.range(at: 1)
                    if let swiftRange = Range(amountRange, in: text) {
                        let amountString = String(text[swiftRange]).replacingOccurrences(of: ",", with: ".")
                        if let amount = Double(amountString) {
                            potentialTotals.append(amount)
                        }
                    }
                }
            }
            return potentialTotals.max()
        } catch {
            print("Regex error finding total: \(error)")
            return nil
        }
    }
    
    private func findTransactionDate(from text: String) -> Date? {
        let pattern = #"\b(\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})\b"#
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            let dateFormats = [
                "dd/MM/yyyy", "dd.MM.yyyy", "dd-MM-yyyy",
                "MM/dd/yyyy", "MM.dd.yyyy", "MM-dd-yyyy",
                "yyyy-MM-dd", "yyyy/MM/dd", "yyyy.MM.dd",
                "dd/MM/yy", "dd.MM.yy", "dd-MM-yy",
                "MM/dd/yy", "MM.dd.yy", "MM-dd-yy"
            ]
            let formatter = DateFormatter()
            for match in matches {
                let dateRange = match.range(at: 1)
                if let swiftRange = Range(dateRange, in: text) {
                    let dateString = String(text[swiftRange])
                    for format in dateFormats {
                        formatter.dateFormat = format
                        if let date = formatter.date(from: dateString) {
                            return date
                        }
                    }
                }
            }
            return nil
        } catch {
            print("Regex error finding date: \(error)")
            return nil
        }
    }
}

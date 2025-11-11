//
//  ReceiptExtractor.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//


import Foundation
import CoreML
import NaturalLanguage

class ReceiptExtractor {
    
    private let nerModel: NLModel?
    
    init() {
        // Try to load our custom Word Tagger model
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
        
        // --- Use the new, smarter functions ---
        let storeName = findStoreName(from: lines)
        let total = findTotalAmount(from: rawText)
        let date = findTransactionDate(from: rawText)
        
        let items = findItems(from: lines)
        
        return (storeName, total, date, items)
    }
    
    // --- (findItems function remains the same) ---
    private func findItems(from lines: [String]) -> [ReceiptItem] {
        guard let nerModel = self.nerModel else {
            return []
        }
        
        var foundItems: [ReceiptItem] = []
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.setModels([nerModel], forTagScheme: .nameType)
        
        for line in lines {
            tagger.string = line
            let tags = tagger.tags(in: line.startIndex..<line.endIndex,
                                   unit: .word,
                                   scheme: .nameType,
                                   options: [.omitWhitespace, .omitPunctuation])
            
            var currentItemName = ""
            var currentQuantity = 1
            var currentPrice: Double?
            
            for (tag, range) in tags {
                let word = String(line[range])
                guard let label = tag?.rawValue else { continue }
                
                switch label {
                case "PRODUCT_NAME":
                    currentItemName += word + " "
                case "QUANTITY":
                    if let intQty = Int(word) {
                        currentQuantity = intQty
                    } else if let doubleQty = Double(word) {
                        currentQuantity = Int(doubleQty)
                    }
                case "ITEM_PRICE":
                    let priceString = word.replacingOccurrences(of: ",", with: ".")
                                        .replacingOccurrences(of: "$", with: "") // Remove currency symbols
                    currentPrice = Double(priceString)
                default:
                    break
                }
            }
            
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
    
    // --- UPDATED: Smarter findStoreName ---
    private func findStoreName(from lines: [String]) -> String {
        // Get the first 5 non-empty lines
        let topLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.prefix(5)
        
        // This regex looks for date-like strings
        let datePattern = #"\b(\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})\b"#
        
        for line in topLines {
            // Trim whitespace
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Ignore if it's just "DATE" or a day "WED"
            if trimmedLine.uppercased() == "DATE" || trimmedLine.uppercased() == "WED" {
                continue
            }
            // Ignore if it's just a date
            if trimmedLine.range(of: datePattern, options: .regularExpression) != nil {
                continue
            }
            // Ignore if it's just asterisks
            if trimmedLine.trimmingCharacters(in: CharacterSet(charactersIn: "*")) == "" {
                continue
            }
            
            // If it's none of the above, it's our best guess for the store name
            return trimmedLine
        }
        
        // If we can't find anything, return "Unknown Store"
        return "Unknown Store"
    }
    
    // --- UPDATED: Smarter findTotalAmount ---
    private func findTotalAmount(from text: String) -> Double? {
        // --- FIX: Added optional currency symbols like \$ (escaped) or € ---
        // We look for keywords, then optional symbols, *then* the number.
        let pattern = #"(?i)(?:total|totale|celkem|amount|importo)\s*[:=\s]?\s*[\$€]?\s*(\d+([,\.]\d{1,2})?)"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            var potentialTotals: [Double] = []
            
            for match in matches {
                if match.numberOfRanges > 1 {
                    let amountRange = match.range(at: 1)
                    if let swiftRange = Range(amountRange, in: text) {
                        // Get the string (e.g., "24.20")
                        let amountString = String(text[swiftRange])
                            .replacingOccurrences(of: ",", with: ".") // Standardize comma
                        
                        if let amount = Double(amountString) {
                            potentialTotals.append(amount)
                        }
                    }
                }
            }
            // Return the largest number found (e.g., TOTAL, not SUBTOTAL)
            return potentialTotals.max()
            
        } catch {
            print("Regex error finding total: \(error)")
            return nil
        }
    }

    // --- (findTransactionDate remains the same) ---
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

//
//  ReceiptExtractor.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//

// FILE: ReceiptExtractor.swift (REPLACE THE ENTIRE FILE)

import Foundation

class ReceiptExtractor {
    
    func extractData(from rawText: String) -> (storeName: String, total: Double?, date: Date?) {
        
        let lines = rawText.split(separator: "\n").map { String($0) }
        
        let storeName = findStoreName(from: lines)
        let total = findTotalAmount(from: rawText) // Use the whole text for total
        let date = findTransactionDate(from: rawText) // Use the whole text for date
        
        return (storeName, total, date)
    }
    
    // --- Private Helper Functions ---

    private func findStoreName(from lines: [String]) -> String {
        // Heuristic: The store name is often the first non-empty line.
        // This is still weak but is the simplest approach.
        return lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "Unknown Store"
    }
    
    
    // --- IMPROVED: findTotalAmount ---
    private func findTotalAmount(from text: String) -> Double? {
        
        // This is a much stronger Regex.
        // (?i) = Case-insensitive
        // (total|totale|...|pagato) = Looks for any of these keywords
        // \s*[:=\s]?\s* = Looks for a space, colon, equals sign, or just more space
        // (\d+[,\.]\d{1,2}) = Captures a number like 10.50 or 10,50
        // (\d+) = Captures a whole number like 10
        let pattern = #"(?i)(?:total|totale|amount|importo|balance due|pagato|net total)\s*[:=\s]?\s*(\d+([,\.]\d{1,2})?)"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            var potentialTotals: [Double] = []
            
            for match in matches {
                // The captured group is at index 1 (the number itself)
                if match.numberOfRanges > 1 {
                    let amountRange = match.range(at: 1)
                    if let swiftRange = Range(amountRange, in: text) {
                        
                        // Get the string (e.g., "10,50")
                        let amountString = String(text[swiftRange])
                            // Standardize by replacing comma with dot
                            .replacingOccurrences(of: ",", with: ".")
                        
                        if let amount = Double(amountString) {
                            potentialTotals.append(amount)
                        }
                    }
                }
            }
            
            // Heuristic: The largest number found near a "total" keyword
            // is *probably* the final total (as opposed to subtotal).
            return potentialTotals.max()
            
        } catch {
            print("Regex error finding total: \(error)")
            return nil
        }
    }

    
    // --- IMPROVED: findTransactionDate ---
    private func findTransactionDate(from text: String) -> Date? {
        
        // This regex looks for:
        // dd/mm/yyyy, dd.mm.yyyy, dd-mm-yyyy
        // mm/dd/yyyy
        // yyyy-mm-dd (ISO)
        let pattern = #"\b(\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})\b"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            // We define all common formats to try
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
                    
                    // Try to parse the found string with different formats
                    for format in dateFormats {
                        formatter.dateFormat = format
                        if let date = formatter.date(from: dateString) {
                            // As soon as we find a valid date, return it
                            return date
                        }
                    }
                }
            }
            
            // No valid date found
            return nil
            
        } catch {
            print("Regex error finding date: \(error)")
            return nil
        }
    }
    
    // (findItems is still a stub, as it's the most complex part)
    func findItems(from rawText: String) -> [ReceiptItem] {
        return []
    }
}

//
//  ReceiptExtractor.swift
//  
//
//  Created by Mahdi Miri on 10/11/25.
//

import Foundation

// This class is responsible for parsing the raw OCR text
// into structured data (Store Name, Total, Date).
// This is a non-trivial task that relies on finding common patterns.

class ReceiptExtractor {
    
    // The main function to extract all possible data.
    // It returns a 'draft' tuple, not a final Receipt object,
    // as it might fail to find some pieces of information.
    func extractData(from rawText: String) -> (storeName: String, total: Double?, date: Date?) {
        
        // We split the text into lines for easier processing.
        let lines = rawText.split(separator: "\n").map { String($0) }
        
        let storeName = findStoreName(from: lines)
        let total = findTotalAmount(from: rawText)
        let date = findTransactionDate(from: rawText)
        
        return (storeName, total, date)
    }
    
    // --- Private Helper Functions ---

    // 1. Find Store Name
    // Heuristic: The store name is often the first non-empty line of the receipt.
    // This is a simple guess and can be improved later.
    private func findStoreName(from lines: [String]) -> String {
        // Find the first line that isn't just whitespace
        return lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "Unknown Store"
    }
    
    // 2. Find Total Amount
    // This function searches for keywords (Total, Totale) and then looks
    // for the largest number near them.
    private func findTotalAmount(from text: String) -> Double? {
        // This regex looks for keywords (case-insensitive)
        // followed by numbers (handling both 10.50 and 10,50)
        let pattern = #"(?i)(?:total|totale|amount|importo)\s*[:]?\s*(\d+[,.]\d{2})"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            var potentialTotals: [Double] = []
            
            for match in matches {
                if match.numberOfRanges > 1 {
                    // Get the captured group (the number itself)
                    let amountRange = match.range(at: 1)
                    if let swiftRange = Range(amountRange, in: text) {
                        
                        // Convert text to a Double, replacing comma with dot for decimals
                        let amountString = String(text[swiftRange]).replacingOccurrences(of: ",", with: ".")
                        if let amount = Double(amountString) {
                            potentialTotals.append(amount)
                        }
                    }
                }
            }
            
            // Often, the receipt shows Subtotal, Tax, and Total.
            // The largest value is usually the final total.
            return potentialTotals.max()
            
        } catch {
            print("Regex error finding total: \(error)")
            return nil
        }
    }
    
    // 3. Find Transaction Date
    // This searches for common date formats (dd/mm/yyyy, dd.mm.yyyy, mm/dd/yyyy)
    private func findTransactionDate(from text: String) -> Date? {
        // This regex looks for common date formats
        let pattern = #"\b(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})\b"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            let dateFormats = [
                "dd/MM/yyyy",
                "dd.MM.yyyy",
                "MM/dd/yyyy",
                "dd/MM/yy",
                "dd.MM.yy",
                "MM/dd/yy"
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
    
    // 4. Find Items (Placeholder)
    // NOTE: Extracting line items is the *hardest* part of this process
    // and is a full "Named Entity Recognition" (NER) task.
    // A simple Regex is very brittle. We will stub this for now
    // and can implement a real ML model for it later.
    func findItems(from rawText: String) -> [ReceiptItem] {
        // TODO: Implement line item extraction (Advanced ML/NER task)
        return [] // Return an empty array for now
    }
}

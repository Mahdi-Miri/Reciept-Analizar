//
//  OCRProcessor.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//

import Foundation
import Vision
import UIKit

// MARK: - OCR Error
// Defines a custom error for when OCR fails.
enum OCRError: Error {
    case processingFailed
    case noTextFound
}

// MARK: - OCR Processor
// This class is responsible for performing Optical Character Recognition (OCR)
// on a given UIImage using Apple's Vision framework.

class OCRProcessor {
    
    // The main function to process an image.
    // It's 'async' because OCR takes time and shouldn't block the main thread.
    // It can 'throw' an error if processing fails.
    func processImage(_ image: UIImage) async throws -> String {
        
        // 1. Get the CGImage
        // Vision framework works with CGImage, not UIImage.
        guard let cgImage = image.cgImage else {
            throw OCRError.processingFailed
        }
        
        // 2. Create the Vision Request
        // VNRecognizeTextRequest is the specific tool for finding text.
        let request = VNRecognizeTextRequest()
        
        // 3. Set languages
        // We tell Vision to look for both English and Italian.
        request.recognitionLanguages = ["en-US", "it-IT"]
        
        // 4. Use accurate mode
        // We prefer accuracy over speed for receipts.
        request.recognitionLevel = .accurate
        
        // 5. Create the Request Handler
        // The handler manages running the request on the image.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 6. Perform the request
        // We 'try await' to perform the request asynchronously.
        do {
            try requestHandler.perform([request])
        } catch {
            throw OCRError.processingFailed
        }
        
        // 7. Get the results
        // 'request.results' now contains all the text Vision found.
        guard let observations = request.results,
              !observations.isEmpty else {
            // If Vision found no text at all.
            throw OCRError.noTextFound
        }
        
        // 8. Process and combine the results
        // We loop through all the found text blocks and combine them
        // into one single string, separated by newlines.
        let recognizedText = observations.compactMap { observation in
            // Get the best candidate (most confident result) for each text block
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n") // Join all lines with a newline
        
        return recognizedText
    }
}

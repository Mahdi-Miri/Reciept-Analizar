//
//  DashboardView.swift
//  
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import SwiftData // To fetch data
import Charts     // For Pie and Bar charts

struct DashboardView: View {
    
    // 1. SwiftData Setup
    // Access the database context
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all Receipt objects, sorted by date (newest first)
    @Query(sort: \Receipt.transactionDate, order: .reverse) private var receipts: [Receipt]
    
    // 2. State Variables
    // This will show/hide the ScanView sheet
    @State private var isShowingScanner = false
    
    // To show loading/processing indicator
    @State private var isProcessing = false
    
    // To show error messages
    @State private var errorMessage: String?
    @State private var isShowingError = false
    
    // 3. Processors
    // We instantiate our processing classes
    private let ocrProcessor = OCRProcessor()
    private let extractor = ReceiptExtractor()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                
                // Main content
                VStack {
                    // Check if there are receipts
                    if receipts.isEmpty {
                        ContentUnavailableView(
                            "No Receipts",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Tap the + button to scan your first receipt.")
                        )
                    } else {
                        // If there are receipts, show the dashboard
                        List {
                            // TODO: Add Chart sections here
                            // We will add these in the next step
                            // (Charts need data aggregation first)
                            
                            // Section for recent transactions
                            Section(header: Text("Recent Transactions")) {
                                ForEach(receipts.prefix(10)) { receipt in
                                    ReceiptRowView(receipt: receipt)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Dashboard")
                
                // --- Floating Action Button (FAB) ---
                Button(action: {
                    isShowingScanner = true
                }) {
                    Image(systemName: "plus")
                        .font(.title.weight(.semibold))
                        .padding()
                        .background(Color.blue) // This will be our PrimaryBlue
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .padding()
                
                // --- Loading Overlay ---
                if isProcessing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Processing Receipt...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                }
            }
        }
        .sheet(isPresented: $isShowingScanner) {
            // Present the ScanView as a modal sheet
            ScanView { (capturedImage) in
                // This is the completion handler
                // It runs when ScanView returns a captured image
                processCapturedImage(capturedImage)
            }
        }
        .alert("Error", isPresented: $isShowingError, actions: {
            Button("OK") { }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
    }
    
    // --- Main Logic: Processing Pipeline ---
    private func processCapturedImage(_ image: UIImage) {
        // 1. Start loading indicator
        isProcessing = true
        
        // 2. Run the full pipeline asynchronously
        Task {
            do {
                // Step 1: Run OCR
                let rawText = try await ocrProcessor.processImage(image)
                
                // Step 2: Extract data
                let extractedData = extractor.extractData(from: rawText)
                
                // Step 3: Run Auto-Categorization (We'll add this next)
                // For now, we'll use a placeholder category
                let category = "Pending" // TODO: Replace with real categorization
                
                // Step 4: Create and save the new Receipt object
                // We use 'await MainActor.run' to safely update the database
                // from a background task.
                await MainActor.run {
                    saveReceipt(
                        storeName: extractedData.storeName,
                        total: extractedData.total,
                        date: extractedData.date,
                        rawText: rawText,
                        category: category
                    )
                    
                    // 5. Stop loading
                    isProcessing = false
                }
                
            } catch {
                // Handle any errors from OCR or Extraction
                showError(error.localizedDescription)
                isProcessing = false
            }
        }
    }
    
    // Helper to save the new receipt to SwiftData
    @MainActor
    private func saveReceipt(storeName: String, total: Double?, date: Date?, rawText: String, category: String) {
        // Use default values if extraction failed
        let finalTotal = total ?? 0.0
        let finalDate = date ?? Date() // Use today's date if not found
        
        let newReceipt = Receipt(
            storeName: storeName,
            totalAmount: finalTotal,
            transactionDate: finalDate,
            category: category,
            rawText: rawText,
            items: [] // We still need to implement item extraction
        )
        
        // Insert into the database
        modelContext.insert(newReceipt)
    }
    
    // Helper to show an error alert
    private func showError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}


// MARK: - Receipt Row View
// A helper view to show a single receipt in the list
// (You can move this to its own file later)
struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            // TODO: Add an icon based on category
            Image(systemName: "doc.text.fill") // Placeholder icon
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(receipt.storeName)
                    .font(.headline)
                Text(receipt.transactionDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(receipt.totalAmount, format: .currency(code: "EUR")) // Assuming Euro for Italy
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

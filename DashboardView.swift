//
//  DashboardView.swift
//  
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import SwiftData
import Charts // We will now use this

struct DashboardView: View {
    
    // 1. SwiftData Setup
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.transactionDate, order: .reverse) private var receipts: [Receipt]
    
    // 2. State Variables
    @State private var isShowingScanner = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var isShowingError = false
    
    // 3. Processors and Categorizer
    private let ocrProcessor = OCRProcessor()
    private let extractor = ReceiptExtractor()
    
    // --- NEW: Load the AutoCategorizer ---
    // We try to initialize our model.
    // If it fails (e.g., model file not found), it will be 'nil'.
    private let categorizer = AutoCategorizer()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                
                // Main content
                VStack {
                    if receipts.isEmpty {
                        ContentUnavailableView(
                            "No Receipts",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Tap the + button to scan your first receipt.")
                        )
                    } else {
                        // If there are receipts, show the dashboard
                        List {
                            
                            // --- NEW: Charts Section ---
                            Section(header: Text("Spending Overview")) {
                                // 1. Pie Chart for Spending by Category
                                if !categorySpendingData.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Spending by Category")
                                            .font(.headline)
                                        
                                        // This is the Pie Chart
                                        Chart(categorySpendingData, id: \.category) { item in
                                            SectorMark(
                                                angle: .value("Amount", item.amount),
                                                innerRadius: .ratio(0.618), // Creates a donut chart
                                                angularInset: 2.0
                                            )
                                            .foregroundStyle(by: .value("Category", item.category))
                                            .cornerRadius(5)
                                        }
                                        .frame(height: 250)
                                    }
                                    .padding(.vertical)
                                }
                                
                                // 2. Bar Chart for Monthly Trend
                                if !monthlySpendingData.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Monthly Trend")
                                            .font(.headline)
                                        
                                        // This is the Bar Chart
                                        Chart(monthlySpendingData, id: \.month) { item in
                                            BarMark(
                                                x: .value("Month", item.month, unit: .month),
                                                y: .value("Total Amount", item.amount)
                                            )
                                            // Use the blue theme color
                                            .foregroundStyle(Color.blue)
                                            .cornerRadius(5)
                                        }
                                        .chartXAxis {
                                            AxisMarks(values: .stride(by: .month)) { _ in
                                                AxisGridLine()
                                                AxisTick()
                                                AxisValueLabel(format: .dateTime.month(.narrow))
                                            }
                                        }
                                        .frame(height: 200)
                                    }
                                    .padding(.vertical)
                                }
                            }
                            
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
                        .background(Color.blue) // Our PrimaryBlue theme color
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
            ScanView { (capturedImage) in
                processCapturedImage(capturedImage)
            }
        }
        .alert("Error", isPresented: $isShowingError, actions: {
            Button("OK") { }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
    }
    
    // --- Main Logic: Processing Pipeline (UPDATED) ---
    private func processCapturedImage(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                // Step 1: Run OCR
                let rawText = try await ocrProcessor.processImage(image)
                
                // Step 2: Extract data
                let extractedData = extractor.extractData(from: rawText)
                
                // --- NEW: Step 3: Run Auto-Categorization ---
                // We use our 'categorizer'. If it's nil or fails,
                // we default to "Pending".
                // We use the raw text as input for the model.
                let category = categorizer?.categorize(text: rawText) ?? "Pending"
                
                // Step 4: Create and save the new Receipt object
                await MainActor.run {
                    saveReceipt(
                        storeName: extractedData.storeName,
                        total: extractedData.total,
                        date: extractedData.date,
                        rawText: rawText,
                        category: category // Use the ML-predicted category
                    )
                    
                    isProcessing = false
                }
                
            } catch {
                showError(error.localizedDescription)
                isProcessing = false
            }
        }
    }
    
    // Helper to save the new receipt to SwiftData
    @MainActor
    private func saveReceipt(storeName: String, total: Double?, date: Date?, rawText: String, category: String) {
        let finalTotal = total ?? 0.0
        let finalDate = date ?? Date()
        
        let newReceipt = Receipt(
            storeName: storeName,
            totalAmount: finalTotal,
            transactionDate: finalDate,
            category: category, // The category is now smart!
            rawText: rawText,
            items: []
        )
        modelContext.insert(newReceipt)
    }
    
    // Helper to show an error alert
    private func showError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
    
    // --- NEW: Computed properties for Chart data ---
    
    // 1. Data for Pie Chart (Category Spending)
    private var categorySpendingData: [(category: String, amount: Double)] {
        // Group receipts by category and sum their totals
        let spending = Dictionary(grouping: receipts, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.totalAmount } }
        
        // Sort to show largest categories first
        return spending.sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $1.value) }
    }
    
    // 2. Data for Bar Chart (Monthly Spending)
    private var monthlySpendingData: [(month: Date, amount: Double)] {
        let calendar = Calendar.current
        
        // Group receipts by the first day of their month/year
        let groups = Dictionary(grouping: receipts, by: {
            calendar.date(from: calendar.dateComponents([.year, .month], from: $0.transactionDate))!
        })
        
        // Sum the totals for each group
        let spending = groups.mapValues { $0.reduce(0) { $0 + $1.totalAmount } }
        
        // Sort by date to show a proper trend
        return spending.sorted { $0.key < $1.key }
            .map { (month: $0.key, amount: $1.value) }
    }
}


// MARK: - Receipt Row View (UPDATED)
// We'll update the icon to be smarter
struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            // NEW: Smart icon based on category
            Image(systemName: categoryIcon(for: receipt.category))
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
                .foregroundColor(.blue) // Use our theme color
            
            VStack(alignment: .leading) {
                Text(receipt.storeName)
                    .font(.headline)
                // Show category if it's not pending
                if receipt.category != "Pending" {
                    Text(receipt.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(receipt.totalAmount, format: .currency(code: "EUR")) // TODO: Make currency dynamic
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(receipt.transactionDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to get an icon based on the category string
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Groceries":
            return "cart.fill"
        case "Restaurant":
            return "fork.knife"
        case "Transport":
            return "car.fill"
        case "Clothing":
            return "bag.fill"
        case "Health":
            return "heart.fill"
        default:
            return "doc.text.fill" // Default icon
        }
    }
}

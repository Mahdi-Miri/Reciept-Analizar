//
//  DashboardView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import SwiftData
import Charts

// --- Helper structs for Chart data ---
// These structs fix the '...has no member 'key'/'value'' errors.
// Charts work better with Identifiable structs than Tuples.

struct CategorySpending: Identifiable {
    let category: String
    let amount: Double
    var id: String { category } // Use category as the unique ID
}

struct MonthlySpending: Identifiable {
    let month: Date
    let amount: Double
    var id: Date { month } // Use month as the unique ID
}


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
                            
                            // --- Charts Section ---
                            Section(header: Text("Spending Overview")) {
                                // 1. Pie Chart for Spending by Category
                                if !categorySpendingData.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Spending by Category")
                                            .font(.headline)
                                        
                                        // Chart now uses the new CategorySpending struct
                                        Chart(categorySpendingData) { item in // No 'id' needed here
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
                                        
                                        // Chart now uses the new MonthlySpending struct
                                        Chart(monthlySpendingData) { item in // No 'id' needed here
                                            BarMark(
                                                x: .value("Month", item.month, unit: .month),
                                                y: .value("Total Amount", item.amount)
                                            )
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
                        .background(Color.blue)
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
    
    // --- Main Logic: Processing Pipeline (Unchanged) ---
    // FILE: DashboardView.swift (Updated function)

        private func processCapturedImage(_ image: UIImage) {
            isProcessing = true
            
            Task {
                do {
                    guard let resizedImage = image.resize(toWidth: 1500) else {
                        throw OCRError.processingFailed
                    }
                    
                    let rawText = try await ocrProcessor.processImage(resizedImage)
                    
                    // --- DEBUG ---
                    print("--- OCR RAW TEXT ---")
                    print(rawText)
                    print("----------------------")
                    
                    // Step 2: Extract data (Now includes items!)
                    let extractedData = extractor.extractData(from: rawText)
                    
                    // Step 3: Run Auto-Categorization
                    let category = categorizer?.categorize(text: extractedData.storeName) ?? "Pending"
                    
                    // Step 4: Create and save the new Receipt object
                    await MainActor.run {
                        saveReceipt(
                            storeName: extractedData.storeName,
                            total: extractedData.total,
                            date: extractedData.date,
                            rawText: rawText,
                            category: category,
                            items: extractedData.items // --- PASS THE ITEMS ---
                        )
                        isProcessing = false
                    }
                    
                } catch {
                    showError(error.localizedDescription)
                    isProcessing = false
                }
            }
        }
    
    @MainActor
    // FILE: DashboardView.swift (Updated function)

    
    private func saveReceipt(storeName: String, total: Double?, date: Date?, rawText: String, category:String, items: [ReceiptItem]){ // <-- ADDED ITEMS
            let finalTotal = total ?? 0.0
            let finalDate = date ?? Date()
            
            let newReceipt = Receipt(
                storeName: storeName,
                totalAmount: finalTotal,
                transactionDate: finalDate,
                category: category,
                rawText: rawText,
                items: items // --- SAVE THE ITEMS ---
            )
            modelContext.insert(newReceipt)
        }
    
    private func showError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
    
    // --- Computed properties for Chart data (UPDATED) ---
    
    // 1. Data for Pie Chart (Category Spending)
    private var categorySpendingData: [CategorySpending] {
        let spending = Dictionary(grouping: receipts, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.totalAmount } }
        
        // Return an array of CategorySpending structs
        return spending.sorted { $0.value > $1.value }
            .map { CategorySpending(category: $0.key, amount: $0.value) } // FIX: Changed $1.value to $0.value
    }
    
    // 2. Data for Bar Chart (Monthly Spending)
    private var monthlySpendingData: [MonthlySpending] {
        let calendar = Calendar.current
        
        let groups = Dictionary(grouping: receipts, by: {
            calendar.date(from: calendar.dateComponents([.year, .month], from: $0.transactionDate))!
        })
        
        let spending = groups.mapValues { $0.reduce(0) { $0 + $1.totalAmount } }
        
        // Return an array of MonthlySpending structs
        return spending.sorted { $0.key < $1.key }
            .map { MonthlySpending(month: $0.key, amount: $0.value) } // FIX: Changed $1.value to $0.value
    }
}


// MARK: - Receipt Row View
struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            Image(systemName: categoryIcon(for: receipt.category))
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(receipt.storeName)
                    .font(.headline)
                if receipt.category != "Pending" {
                    Text(receipt.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                // --- FIX: Use a reliable currency formatter ---
                Text(formatCurrency(receipt.totalAmount))
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(receipt.transactionDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to get an icon
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Groceries": return "cart.fill"
        case "Restaurant": return "fork.knife"
        case "Transport": return "car.fill"
        case "Clothing": return "bag.fill"
        case "Health": return "heart.fill"
        default: return "doc.text.fill"
        }
    }
    
    // --- FIX: Add this reliable currency formatter function ---
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR" // Or you can make this dynamic
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

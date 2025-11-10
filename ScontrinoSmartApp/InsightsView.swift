//
//  InsightsView.swift
//  
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import SwiftData

// MARK: - Insight Data Structure
// A simple struct to hold a single piece of insight
struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
}

// MARK: - Insights Engine
// A 'struct' that contains static functions to analyze receipt data.
// We pass it the data, and it returns an array of insights.
struct InsightsEngine {
    
    // Main function to generate all insights
    static func generate(from receipts: [Receipt]) -> [Insight] {
        // We create an array to hold all the insights we find
        var insights: [Insight] = []
        
        // --- 1. Month-over-Month Comparison ---
        if let momInsight = compareMonthOverMonth(receipts: receipts) {
            insights.append(momInsight)
        }
        
        // --- 2. Top Spending Category ---
        if let topCategoryInsight = findTopCategory(receipts: receipts) {
            insights.append(topCategoryInsight)
        }
        
        // --- 3. Large Transaction Alert ---
        if let largeTxInsight = findLargeTransaction(receipts: receipts) {
            insights.append(largeTxInsight)
        }
        
        return insights
    }
    
    // --- Private Helper Functions for Analysis ---
    
    // Compares spending this month to last month
    private static func compareMonthOverMonth(receipts: [Receipt]) -> Insight? {
        let calendar = Calendar.current
        let today = Date()
        
        guard let thisMonthComponents = calendar.dateComponents([.year, .month], from: today),
              let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: today),
              let lastMonthComponents = calendar.dateComponents([.year, .month], from: lastMonthDate)
        else { return nil }
        
        // Calculate spending for this month
        let thisMonthSpending = receipts.filter {
            let components = calendar.dateComponents([.year, .month], from: $0.transactionDate)
            return components == thisMonthComponents
        }.reduce(0) { $0 + $1.totalAmount }
        
        // Calculate spending for last month
        let lastMonthSpending = receipts.filter {
            let components = calendar.dateComponents([.year, .month], from: $0.transactionDate)
            return components == lastMonthComponents
        }.reduce(0) { $0 + $1.totalAmount }
        
        // Only show if we have data for both months
        guard thisMonthSpending > 0 && lastMonthSpending > 0 else { return nil }
        
        let percentageChange = ((thisMonthSpending - lastMonthSpending) / lastMonthSpending) * 100
        
        if percentageChange > 10 { // If spending increased by more than 10%
            return Insight(
                title: "Spending Increase",
                description: String(format: "Your spending is up %.0f%% compared to last month.", percentageChange),
                iconName: "chart.line.uptrend.xyaxis",
                iconColor: .red
            )
        } else if percentageChange < -10 { // If spending decreased
            let positiveChange = abs(percentageChange)
            return Insight(
                title: "Great Job!",
                description: String(format: "Your spending is down %.0f%% compared to last month.", positiveChange),
                iconName: "chart.line.downtrend.xyaxis",
                iconColor: .green
            )
        }
        
        return nil
    }
    
    // Finds the category with the most spending this month
    private static func findTopCategory(receipts: [Receipt]) -> Insight? {
        let calendar = Calendar.current
        let today = Date()
        let thisMonthComponents = calendar.dateComponents([.year, .month], from: today)

        // Filter for receipts from this month
        let thisMonthReceipts = receipts.filter {
            let components = calendar.dateComponents([.year, .month], from: $0.transactionDate)
            return components == thisMonthComponents
        }
        
        guard !thisMonthReceipts.isEmpty else { return nil }
        
        // Group by category and sum the totals
        let categorySpending = Dictionary(grouping: thisMonthReceipts, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.totalAmount } }
        
        // Find the category with the highest spending
        if let topCategory = categorySpending.max(by: { $0.value < $1.value }) {
            return Insight(
                title: "Top Category",
                description: "Your highest spending this month was in \(topCategory.key) with \(topCategory.value, format: .currency(code: "EUR")).",
                iconName: "star.fill",
                iconColor: .yellow
            )
        }
        
        return nil
    }
    
    // Finds any single transaction that is unusually large
    private static func findLargeTransaction(receipts: [Receipt]) -> Insight? {
        // Calculate average spending
        let totalSpending = receipts.reduce(0) { $0 + $1.totalAmount }
        let averageSpending = totalSpending / Double(receipts.count)
        
        // Find a transaction that is 5x larger than average
        // (This is a simple anomaly detection)
        if let largeReceipt = receipts.first(where: { $0.totalAmount > (averageSpending * 5) && $0.totalAmount > 100 }) { // and over 100
            return Insight(
                title: "Large Transaction",
                description: "You had an unusually large purchase of \(largeReceipt.totalAmount, format: .currency(code: "EUR")) at \(largeReceipt.storeName).",
                iconName: "exclamationmark.triangle.fill",
                iconColor: .orange
            )
        }
        return nil
    }
}


// MARK: - Insights View
// The main SwiftUI view to display the insights
struct InsightsView: View {
    
    // Get all receipts from SwiftData
    @Query(sort: \Receipt.transactionDate, order: .reverse) private var receipts: [Receipt]
    
    // State to hold the generated insights
    @State private var insights: [Insight] = []
    
    var body: some View {
        NavigationStack {
            List {
                if insights.isEmpty {
                    // Show a message if no insights were found
                    ContentUnavailableView(
                        "Not Enough Data",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Scan more receipts to generate smart insights.")
                    )
                } else {
                    // Loop over the found insights and show them as cards
                    ForEach(insights) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            }
            .navigationTitle("Insights")
            .onAppear {
                // When the view appears, run the engine
                self.insights = InsightsEngine.generate(from: receipts)
            }
            // Add a refresh button
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.insights = InsightsEngine.generate(from: receipts)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Insight Card View
// A helper view to make each insight look nice
struct InsightCardView: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: insight.iconName)
                .font(.title)
                .foregroundColor(insight.iconColor)
                .frame(width: 40)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        // Here you could use the blue/white theme
        .background(Color(.systemGray6)) // A light gray background
        .cornerRadius(12)
        .listRowSeparator(.hidden) // Hide the default list lines
    }
}

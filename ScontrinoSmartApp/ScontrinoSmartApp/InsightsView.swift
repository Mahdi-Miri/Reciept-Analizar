//
//  InsightsView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import SwiftData

// MARK: - Insight Data Structure
struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
}

// MARK: - Insights Engine
struct InsightsEngine {
    
    static func generate(from receipts: [Receipt]) -> [Insight] {
        var insights: [Insight] = []
        
        if let momInsight = compareMonthOverMonth(receipts: receipts) {
            insights.append(momInsight)
        }
        
        if let topCategoryInsight = findTopCategory(receipts: receipts) {
            insights.append(topCategoryInsight)
        }
        
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
        
        // --- FIX: 'guard let' is not needed for DateComponents ---
        let thisMonthComponents = calendar.dateComponents([.year, .month], from: today)
        
        // This 'guard let' is correct because .date(byAdding:) returns an optional
        guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: today) else { return nil }
        
        // --- FIX: 'guard let' is not needed for DateComponents ---
        let lastMonthComponents = calendar.dateComponents([.year, .month], from: lastMonthDate)
        
        
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
        
        guard thisMonthSpending > 0 && lastMonthSpending > 0 else { return nil }
        
        let percentageChange = ((thisMonthSpending - lastMonthSpending) / lastMonthSpending) * 100
        
        if percentageChange > 10 {
            return Insight(
                title: "Spending Increase",
                description: String(format: "Your spending is up %.0f%% compared to last month.", percentageChange),
                iconName: "chart.line.uptrend.xyaxis",
                iconColor: .red
            )
        } else if percentageChange < -10 {
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

        let thisMonthReceipts = receipts.filter {
            let components = calendar.dateComponents([.year, .month], from: $0.transactionDate)
            return components == thisMonthComponents
        }
        
        guard !thisMonthReceipts.isEmpty else { return nil }
        
        let categorySpending = Dictionary(grouping: thisMonthReceipts, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.totalAmount } }
        
        if let topCategory = categorySpending.max(by: { $0.value < $1.value }) {
            // --- FIX: Use reliable currency formatter ---
            let description = "Your highest spending this month was in \(topCategory.key) with \(formatCurrency(topCategory.value))."
            return Insight(
                title: "Top Category",
                description: description,
                iconName: "star.fill",
                iconColor: .yellow
            )
        }
        
        return nil
    }
    
    // Finds any single transaction that is unusually large
    private static func findLargeTransaction(receipts: [Receipt]) -> Insight? {
        guard !receipts.isEmpty else { return nil }
        
        let totalSpending = receipts.reduce(0) { $0 + $1.totalAmount }
        let averageSpending = totalSpending / Double(receipts.count)
        
        if let largeReceipt = receipts.first(where: { $0.totalAmount > (averageSpending * 5) && $0.totalAmount > 100 }) {
            // --- FIX: Use reliable currency formatter ---
            let description = "You had an unusually large purchase of \(formatCurrency(largeReceipt.totalAmount)) at \(largeReceipt.storeName)."
            return Insight(
                title: "Large Transaction",
                description: description,
                iconName: "exclamationmark.triangle.fill",
                iconColor: .orange
            )
        }
        return nil
    }
    
    // --- FIX: Add this reliable currency formatter function ---
    private static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR" // Or make this dynamic
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}


// MARK: - Insights View
struct InsightsView: View {
    
    @Query(sort: \Receipt.transactionDate, order: .reverse) private var receipts: [Receipt]
    @State private var insights: [Insight] = []
    
    var body: some View {
        NavigationStack {
            List {
                if insights.isEmpty {
                    ContentUnavailableView(
                        "Not Enough Data",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Scan more receipts to generate smart insights.")
                    )
                } else {
                    ForEach(insights) { insight in
                        InsightCardView(insight: insight)
                    }
                }
            }
            .navigationTitle("Insights")
            .onAppear {
                self.insights = InsightsEngine.generate(from: receipts)
            }
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
struct InsightCardView: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: insight.iconName)
                .font(.title)
                .foregroundColor(insight.iconColor)
                .frame(width: 40)
            
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .listRowSeparator(.hidden)
    }
}

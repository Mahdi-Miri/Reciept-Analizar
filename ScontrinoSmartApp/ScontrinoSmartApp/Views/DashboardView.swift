//
//  DashboardView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                // --- TOTAL SPENDING SUMMARY ---
                Section("Summary") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(appState.totalSpent, format: .currency(code: "USD"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 8)
                }
                
                // --- CATEGORY SPENDING CHART ---
                Section("Spending by Category") {
                    if appState.categorySpendingData.isEmpty {
                        Text("Scan a receipt to see your spending breakdown.")
                            .foregroundColor(.secondary)
                    } else {
                        // Pass the aggregated data to the chart view
                        CategoryPieChartView(spendingData: appState.categorySpendingData)
                            .frame(height: 250)
                            .padding(.vertical, 8)
                    }
                }
                
                // --- RECENT RECEIPTS LIST ---
                Section("Recent Receipts") {
                    if appState.receipts.isEmpty {
                        Text("No receipts scanned yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(appState.receipts) { receipt in
                            NavigationLink(destination: ReceiptDetailView(receipt: receipt).padding()) {
                                HStack {
                                    Text(receipt.date, style: .date)
                                    Spacer()
                                    Text(receipt.total, format: .currency(code: "USD"))
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}

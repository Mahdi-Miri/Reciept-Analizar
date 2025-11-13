//
//  DashboardView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//  Modern minimal dashboard with spending overview
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    statsHeader
                    
                    // Spending Chart
                    spendingChart
                    
                    // Recent Receipts
                    recentReceiptsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Stats Header
    private var statsHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Spend",
                    value: String(format: "€%.2f", appState.totalSpend),
                    icon: "eurosign.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Receipts",
                    value: "\(appState.receipts.count)",
                    icon: "doc.text.fill",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Spending Chart
    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(.primary)
            
            if appState.categorySpendingData.isEmpty {
                emptyChartState
            } else {
                Chart(appState.categorySpendingData) { item in
                    BarMark(
                        x: .value("Amount", item.amount),
                        y: .value("Category", item.category.rawValue)
                    )
                    .foregroundStyle(item.category.color.gradient)
                    .cornerRadius(8)
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var emptyChartState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("No data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Recent Receipts
    private var recentReceiptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Receipts")
                    .font(.headline)
                Spacer()
                NavigationLink("See All", destination: ReceiptsListView())
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if appState.receipts.isEmpty {
                emptyReceiptsState
            } else {
                ForEach(appState.receipts.prefix(3)) { receipt in
                    NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                        ReceiptRowView(receipt: receipt)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var emptyReceiptsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("Scan your first receipt")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Receipt Row Component
struct ReceiptRowView: View {
    let receipt: ScannedReceipt
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(receipt.items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "€%.2f", receipt.total))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}

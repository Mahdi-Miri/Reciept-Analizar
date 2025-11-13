//
//  ReceiptsListView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//  Complete list of all scanned receipts
//

import SwiftUI

struct ReceiptsListView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    
    var filteredReceipts: [ScannedReceipt] {
        if searchText.isEmpty {
            return appState.receipts
        }
        return appState.receipts.filter { receipt in
            receipt.items.contains { item in
                item.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredReceipts) { receipt in
                NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                    receiptRow(receipt)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search receipts")
        .navigationTitle("All Receipts")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if filteredReceipts.isEmpty {
                emptyState
            }
        }
    }
    
    private func receiptRow(_ receipt: ScannedReceipt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(receipt.date, style: .date)
                    .font(.headline)
                Spacer()
                Text(String(format: "€%.2f", receipt.total))
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("\(receipt.items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Category badges
                ForEach(uniqueCategories(receipt), id: \.self) { category in
                    CategoryBadge(category: category)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func uniqueCategories(_ receipt: ScannedReceipt) -> [Category] {
        Array(Set(receipt.items.map { $0.category })).prefix(3).sorted { $0.rawValue < $1.rawValue }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "doc.badge.plus" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(searchText.isEmpty ? "No receipts yet" : "No results found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Text("Tap the scan button to add your first receipt")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: Category
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(category.color.opacity(0.2))
            .foregroundColor(category.color)
            .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        ReceiptsListView()
            .environmentObject(AppState())
    }
}

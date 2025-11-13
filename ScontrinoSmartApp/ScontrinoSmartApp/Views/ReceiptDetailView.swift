//
//  ReceiptDetailView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//  Detailed view of a single receipt
//

import SwiftUI

struct ReceiptDetailView: View {
    let receipt: ScannedReceipt
    @State private var selectedCategory: Category?
    
    var filteredItems: [GroceryItem] {
        if let category = selectedCategory {
            return receipt.items.filter { $0.category == category }
        }
        return receipt.items
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Receipt Header
                receiptHeader
                
                // Category Filter
                categoryFilter
                
                // Items List
                itemsList
                
                // Total
                totalSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Receipt Header
    private var receiptHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(receipt.date, style: .date)
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(.green)
                Text("\(receipt.items.count) items")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(Category.allCases) { category in
                    if receipt.items.contains(where: { $0.category == category }) {
                        FilterChip(
                            title: category.rawValue,
                            color: category.color,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Items List
    private var itemsList: some View {
        VStack(spacing: 12) {
            ForEach(filteredItems) { item in
                ItemRow(item: item)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Total Section
    private var totalSection: some View {
        HStack {
            Text("Total")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Text(String(format: "€%.2f", receipt.total))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Item Row
struct ItemRow: View {
    let item: GroceryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Category indicator
            Circle()
                .fill(item.category.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(item.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "€%.2f", item.price))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

#Preview {
    NavigationView {
        ReceiptDetailView(receipt: SampleData.receipts[0])
    }
}

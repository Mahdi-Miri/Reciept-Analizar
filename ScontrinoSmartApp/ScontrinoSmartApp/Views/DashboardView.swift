//
//  DashboardView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//
//  --- MASTER REDESIGN ---
//  This is the main screen of the app.
//  It displays all information in a card-based layout.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    // Get the local currency for formatting
    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
    
    var body: some View {
        // A ScrollView allows for adding many cards
        ScrollView {
            VStack(spacing: 20) {
                
                // --- CARD 1: TOTAL SPEND (Hero Card) ---
                VStack(alignment: .leading, spacing: 5) {
                    Text("TOTAL SPEND")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(appState.totalSpend, format: .currency(code: currencyCode))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.blue) // Use blue theme color
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground)) // White card
                .cornerRadius(15) // Rounded corners
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3) // Soft shadow
                
                // --- CARD 2: SPENDING BY CATEGORY (The Pie Chart) ---
                VStack(alignment: .leading, spacing: 10) {
                    Text("SPENDING BY CATEGORY")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    if appState.categorySpendingData.isEmpty {
                        Text("Scan a receipt to see your spending categories.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        // We use the Pie Chart you already built!
                        CategoryPieChartView(spendingData: appState.categorySpendingData)
                            .frame(height: 250)
                            .padding(.top, 10)
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                
                // --- CARD 3: RECENT RECEIPTS ---
                VStack(alignment: .leading, spacing: 10) {
                    Text("RECENT RECEIPTS")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    if appState.receipts.isEmpty {
                        Text("Your scanned receipts will appear here.")
                            .foregroundColor(.secondary)
                    } else {
                        // We'll show the 5 most recent receipts
                        ForEach(appState.receipts.prefix(5)) { receipt in
                            ReceiptRowView(receipt: receipt, currencyCode: currencyCode)
                            if receipt.id != appState.receipts.prefix(5).last?.id {
                                Divider() // Add a line between items
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                
            }
            .padding() // Padding for the whole VStack
            // --- FIX FOR FAB PADDING ---
            // Add 80 points of padding to the bottom so the last
            // card isn't hidden by the floating scan button.
            .padding(.bottom, 80)
        }
        .navigationTitle("Dashboard")
        // --- FIX FOR TOP SPACE ---
        // This makes the top title bar small and compact
        .navigationBarTitleDisplayMode(.inline)
        // This is the key to the "Card" look
        // It sets the background of the ScrollView to a light gray
        .background(Color(.systemGroupedBackground))
    }
}

// --- A NEW HELPER VIEW ---
// We create a small, reusable view for each receipt row
// This keeps the DashboardView code clean
struct ReceiptRowView: View {
    let receipt: ScannedReceipt
    let currencyCode: String
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon for the row
            Image(systemName: "scroll.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                // Show the first item or a generic name
                Text(receipt.items.first?.name ?? "Scanned Receipt")
                    .font(.headline)
                    .lineLimit(1)
                
                // Show the date
                Text(receipt.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer() // Pushes total to the right
            
            // Show the total
            Text(receipt.total, format: .currency(code: currencyCode))
                .font(.headline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8) // Add space to each row
    }
}

// MARK: - Previews
#Preview {
    // Wrap the preview in a ContentView to see the FAB
    ContentView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}

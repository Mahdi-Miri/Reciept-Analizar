//
//  AllReceiptsView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//


import SwiftUI

/// Displays all scanned receipts in a scrollable list.
struct AllReceiptsView: View {
    @EnvironmentObject var appState: AppState
    let currencyCode: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(appState.receipts) { receipt in
                    ReceiptRowView(receipt: receipt, currencyCode: currencyCode)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("All Receipts")
        .navigationBarTitleDisplayMode(.inline)
        // .background(Color(.systemGroupedBackground)) // <-- This line was removed
    }
}

#Preview {
    AllReceiptsView(currencyCode: "EUR")
        .environmentObject(AppState())
}

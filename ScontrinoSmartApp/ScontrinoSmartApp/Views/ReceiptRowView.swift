//
//  ReceiptRowView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI

/// Displays a single scanned receipt row in the dashboard list.
struct ReceiptRowView: View {
    let receipt: ScannedReceipt
    let currencyCode: String

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
            }

            // Receipt details
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.date, style: .date)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(receipt.items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }



            // Total price
            Text(receipt.total, format: .currency(code: currencyCode))
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
    }
}

#Preview {
    ReceiptRowView(
        receipt: SampleData.receipts.first!,
        currencyCode: "EUR"
    )
    .previewLayout(.sizeThatFits)
    .padding()
}



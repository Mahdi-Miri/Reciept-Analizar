//
//  ReceiptRowView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

// ReceiptRowView.swift
// Small reusable row to display a scanned receipt summary.

import SwiftUI

struct ReceiptRowView: View {
    let receipt: ScannedReceipt
    let currencyCode: String

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail / icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
            }

            // Receipt info
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.storeName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(receipt.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            Text(receipt.total, format: .currency(code: currencyCode))
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    ReceiptRowView(
        receipt: SampleData.receipts.first!,
        currencyCode: "EUR"
    )
    .previewLayout(.sizeThatFits)
    .padding()
}


//
//  StatusToastView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

// StatusToastView.swift
// Small top toast for scan status messages (success / error / processing)

import SwiftUI

struct StatusToastView: View {
    var isProcessing: Bool
    var errorMessage: String?
    var lastScanMessage: String?

    var body: some View {
        VStack {
            if isProcessing {
                labelView(icon: "hourglass.circle.fill", text: "Processing...", color: .blue)
            } else if let errorMessage = errorMessage {
                labelView(icon: "xmark.octagon.fill", text: errorMessage, color: .red)
            } else if let lastScanMessage = lastScanMessage {
                labelView(icon: "checkmark.circle.fill", text: lastScanMessage, color: .green)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        .padding(.top, 10)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func labelView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18, weight: .semibold))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    VStack {
        StatusToastView(isProcessing: false, errorMessage: nil, lastScanMessage: "Success! Receipt added.")
        StatusToastView(isProcessing: false, errorMessage: "Failed to scan", lastScanMessage: nil)
        StatusToastView(isProcessing: true, errorMessage: nil, lastScanMessage: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}


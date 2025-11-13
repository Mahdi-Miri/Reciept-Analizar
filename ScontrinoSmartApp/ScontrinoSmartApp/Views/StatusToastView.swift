//
//  StatusToastView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI

/// Displays a status banner for scan process (processing, success, or error).
struct StatusToastView: View {
    let isProcessing: Bool
    let errorMessage: String?
    let lastScanMessage: String?

    var body: some View {
        VStack {
            if isProcessing {
                Label("Processing receipt...", systemImage: "hourglass")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else if let errorMessage = errorMessage {
                Label(errorMessage, systemImage: "xmark.octagon.fill")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else if let lastScanMessage = lastScanMessage {
                Label(lastScanMessage, systemImage: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: isProcessing)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusToastView(isProcessing: true, errorMessage: nil, lastScanMessage: nil)
        StatusToastView(isProcessing: false, errorMessage: "Scan failed.", lastScanMessage: nil)
        StatusToastView(isProcessing: false, errorMessage: nil, lastScanMessage: "Success! Receipt added.")
    }
    .padding()
}

//
//  ModernScanView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

// ModernScanView.swift
// Dedicated scanning screen with large glassy button and inline status messages.
// Replace old ScanView with this file.

import SwiftUI

struct ModernScanView: View {
    @EnvironmentObject var appState: AppState
    @State private var isShowingScanner = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var lastScanMessage: String?

    private let ocrService = OCRService()

    var body: some View {
        ZStack {
            // Background already provided globally — keep content transparent
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Scan a receipt")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Convert paper receipts into organized data.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)


            
                // Large circular scan button with micro animation
                Button(action: startScan) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 220, height: 220)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                                .shadow(radius: 18)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        Text("Scan Receipt")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 40)

            }

            // Status toast at top
            if isProcessing || errorMessage != nil || lastScanMessage != nil {
                VStack {
                    StatusToastView(isProcessing: isProcessing, errorMessage: errorMessage, lastScanMessage: lastScanMessage)
                        .padding(Edge.Set.top, 10)
                }
                .transition(.move(edge: Edge.top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $isShowingScanner) {
            DocumentScanner(onFinish: { cgImages in
                self.isShowingScanner = false
                withAnimation { self.isProcessing = true }

                ocrService.recognizeText(from: cgImages) { result in
                    withAnimation {
                        self.isProcessing = false
                        switch result {
                        case .success(let receipt):
                            self.appState.addReceipt(receipt)
                            self.lastScanMessage = "Success! Receipt added."
                        case .failure(let error):
                            self.errorMessage = "Scan Failed: \(error.localizedDescription)"
                        }
                    }
                }
            })
            .ignoresSafeArea()
        }
    }

    private func startScan() {
        self.errorMessage = nil
        self.lastScanMessage = nil
        self.isShowingScanner = true
    }
}

// Previews
#Preview {
    ModernScanView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}


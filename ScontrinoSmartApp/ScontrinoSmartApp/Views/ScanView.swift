//
//  ScanView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var isShowingScanner = false
    @State private var isProcessing = false
    @State private var lastScannedReceipt: ScannedReceipt?
    @State private var errorMessage: String?
    
    private let ocrService = OCRService()
    
    var body: some View {
        NavigationStack {
            List {
                // --- SCAN BUTTON ---
                Section {
                    Button(action: {
                        errorMessage = nil
                        isShowingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.headline)
                            Text("Scan New Receipt")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                // --- STATUS INDICATOR ---
                if isProcessing {
                    Section {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Parsing receipt, please wait...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // --- ERROR MESSAGE ---
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                // --- LAST SCANNED RECEIPT ---
                if let receipt = lastScannedReceipt {
                    Section("Last Scan Results") {
                        ReceiptDetailView(receipt: receipt)
                    }
                } else if !isProcessing {
                    Section {
                        Text("Tap the button to start scanning a receipt.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Scan")
            .listStyle(.insetGrouped)
            // The sheet that presents the VisionKit Document Scanner
            .sheet(isPresented: $isShowingScanner) {
                DocumentScanner(onFinish: { cgImages in
                    // When scanner finishes, dismiss it
                    self.isShowingScanner = false
                    // Set processing state
                    self.isProcessing = true
                    
                    // Start OCR
                    ocrService.recognizeText(from: cgImages) { result in
                        self.isProcessing = false
                        switch result {
                        case .success(let receipt):
                            // On success, add to global state and show locally
                            self.appState.addReceipt(receipt)
                            self.lastScannedReceipt = receipt
                        case .failure(let error):
                            // On failure, show error
                            self.errorMessage = error.localizedDescription
                        }
                    }
                })
                .ignoresSafeArea()
            }
        }
    }
}

// A reusable view to show the details of a single receipt
struct ReceiptDetailView: View {
    let receipt: ScannedReceipt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(receipt.date, style: .date)
                Spacer()
                Text(receipt.total, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 8)
            .border(width: 1, edges: [.bottom], color: .secondary.opacity(0.2))

            ForEach(receipt.items) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    Text(item.price, format: .currency(code: "USD"))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Custom ViewModifier for borders
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat = 0, y: CGFloat = 0, x2: CGFloat = 0, y2: CGFloat = 0
            switch edge {
            case .top:    x = rect.minX; y = rect.minY; x2 = rect.maxX; y2 = rect.minY
            case .bottom: x = rect.minX; y = rect.maxY; x2 = rect.maxX; y2 = rect.maxY
            case .leading:  x = rect.minX; y = rect.minY; x2 = rect.minX; y2 = rect.maxY
            case .trailing: x = rect.maxX; y = rect.minY; x2 = rect.maxX; y2 = rect.maxY
            }
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x2, y: y2))
        }
        return path.stroked(with: .init(lineWidth: width))
    }
}

#Preview {
    ScanView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}

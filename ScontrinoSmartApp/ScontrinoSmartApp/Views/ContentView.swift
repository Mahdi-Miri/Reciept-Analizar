//
//  ContentView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//
//  --- MASTER REDESIGN ---
//  This is the root view. It manages the Dashboard,
//  the Floating Action Button (FAB), and the scan logic.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    // All scanning logic now lives here
    @State private var isShowingScanner = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var lastScanMessage: String?
    
    private let ocrService = OCRService()
    
    var body: some View {
        // ZStack allows us to place the button ON TOP of the dashboard
        ZStack(alignment: .bottomTrailing) {
            
            // --- LAYER 1: THE DASHBOARD ---
            // We wrap the dashboard in a NavigationStack
            // to give it a title bar.
            NavigationStack {
                DashboardView()
            }
            // --- FIX FOR BOTTOM SPACE ---
            // This makes the dashboard's background
            // extend all the way to the bottom edge.
            .ignoresSafeArea(edges: .bottom)
            
            // --- LAYER 2: THE FLOATING SCAN BUTTON (FAB) ---
            Button(action: {
                self.errorMessage = nil
                self.lastScanMessage = nil
                self.isShowingScanner = true
            }) {
                Image(systemName: "camera.fill")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(width: 60, height: 60) // Circular button
                    .background(Color.blue) // Your blue theme
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 5, y: 3) // Soft shadow
            }
            .padding(20) // Padding from the corner of the screen
            
            // --- LAYER 3: (Optional) Processing Overlay ---
            // This shows a small "Processing" toast at the top
            if isProcessing || errorMessage != nil || lastScanMessage != nil {
                StatusToastView(
                    isProcessing: isProcessing,
                    errorMessage: errorMessage,
                    lastScanMessage: lastScanMessage
                )
                .onAppear {
                    // Automatically hide the message after a few seconds
                    if !isProcessing {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                self.errorMessage = nil
                                self.lastScanMessage = nil
                            }
                        }
                    }
                }
            }
        }
        // The sheet for the document scanner
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
        // Apply the accent color globally
        .accentColor(.blue)
    }
}

// --- A NEW HELPER VIEW ---
// We create this new view to show status messages
// at the top of the screen in a clean way.
struct StatusToastView: View {
    let isProcessing: Bool
    let errorMessage: String?
    let lastScanMessage: String?

    var body: some View {
        VStack {
            HStack {
                if isProcessing {
                    ProgressView()
                        .padding(.trailing, 5)
                    Text("Parsing receipt...")
                } else if let errorMessage {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .lineLimit(2)
                } else if let lastScanMessage {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(lastScanMessage)
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial) // Modern "glass" effect
            .cornerRadius(100) // Pill shape
            .shadow(radius: 5)
            .transition(.move(edge: .top).combined(with: .opacity))
            
            Spacer() // Pushes the toast to the top
        }
        .padding(.top, 10)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState(receipts: SampleData.receipts))
}

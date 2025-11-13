//
//  ModernDashboardView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//
//  *** THIS FILE FIXES THE WHITE BACKGROUND + RESTORES ALL CONTENT ***
//

import SwiftUI
import Charts

struct ModernDashboardView: View {
    @EnvironmentObject var appState: AppState

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                
                // --- ALL YOUR CONTENT IS RESTORED HERE ---
                
                // 1. Top greeting + quick actions row
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Good afternoon,")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Your Wallet")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Button {
                        // Notification action
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.title3)
                            .padding(8)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                }
                .padding(.horizontal, 6)

                // 2. Card: Total Spend
                VStack(alignment: .leading, spacing: 10) {
                    Text("TOTAL SPEND")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(appState.totalSpend, format: .currency(code: currencyCode))
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.08), radius: 18, y: 8)

                // 3. Card: Categories (chart)
                VStack(alignment: .leading, spacing: 12) {
                    Text("SPENDING BY CATEGORY") // This is the category tag
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if appState.categorySpendingData.isEmpty {
                        Text("No category data yet.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
                    } else {
                         // This requires CategoryPieChartView.swift
                         CategoryPieChartView(spendingData: appState.categorySpendingData)
                           .frame(height: 240)
                           .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)

                // 4. Card: Recent receipts condensed
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("RECENT RECEIPTS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    if appState.receipts.isEmpty {
                        Text("Your scanned receipts will appear here.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                    } else {
                        // This requires ReceiptRowView.swift
                        ForEach(appState.receipts.prefix(4), id: \.id) { receipt in
                            ReceiptRowView(receipt: receipt, currencyCode: currencyCode)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
                
                // 5. Spacer so content doesn't scroll under the tab bar
                Spacer(minLength: 120)
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        
        // ----------------------------------------------------
        // *** THIS IS THE CRITICAL FIX FOR THE WHITE BACKGROUND ***
        // This modifier makes the ScrollView's default
        // white background transparent, letting the
        // AnimatedBackgroundView from ContentView show through.
        .scrollContentBackground(.hidden)
        // ----------------------------------------------------
    }
}

#Preview {
    ZStack {
        AnimatedBackgroundView()
            .ignoresSafeArea()
        
        ModernDashboardView()
            .environmentObject(AppState(receipts: SampleData.receipts))
    }
}

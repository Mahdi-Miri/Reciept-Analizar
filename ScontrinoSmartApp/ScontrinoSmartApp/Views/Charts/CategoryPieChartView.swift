//
//  CategoryPieChartView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//
//  --- CREATIVE UPGRADE ---
//  We add an annotation to the center of the
//  donut chart to show the total amount.
//

import SwiftUI
import Charts

struct CategoryPieChartView: View {
    let spendingData: [CategorySpending]
    
    // Calculate the total spend
    private var totalSpend: Double {
        spendingData.reduce(0) { $0 + $1.amount }
    }
    
    // Get the local currency
    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        Chart(spendingData) { item in
            // Create a SectorMark for the pie chart
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.618), // Creates the donut hole
                angularInset: 1.5 // Adds spacing between slices
            )
            .foregroundStyle(by: .value("Category", item.category.rawValue))
            .cornerRadius(5)
        }
        // Use the custom colors defined in the enum
        .chartForegroundStyleScale(
            domain: spendingData.map { $0.category.rawValue },
            range: spendingData.map { $0.category.color }
        )
        // Add a legend
        .chartLegend(position: .bottom, alignment: .center)
        // --- THIS IS THE UPGRADE (FINAL FIX) ---
        // We use a GeometryReader to find the center of the space
        // provided by the chartBackground modifier.
        .chartBackground { chartProxy in // We must accept chartProxy, even if unused
            GeometryReader { geometry in
                // Get the frame of the GeometryReader itself
                let frame = geometry.frame(in: .local)
                
                VStack {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalSpend, format: .currency(code: currencyCode))
                        .font(.headline)
                        .fontWeight(.bold)
                }
                // Use the GeometryReader's frame properties
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }
}

#Preview {
    CategoryPieChartView(spendingData: AppState(receipts: SampleData.receipts).categorySpendingData)
        .padding()
}

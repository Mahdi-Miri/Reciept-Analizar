//
//  CategoryPieChartView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI
import Charts

struct CategoryPieChartView: View {
    let spendingData: [CategorySpending]

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
            .annotation(position: .overlay, alignment: .center) {
                // This annotation is for the center, but we'll leave it blank
                // to show the donut hole.
            }
        }
        // Use the custom colors defined in the enum
        .chartForegroundStyleScale(
            domain: spendingData.map { $0.category.rawValue },
            range: spendingData.map { $0.category.color }
        )
        // Add a legend
        .chartLegend(position: .bottom, alignment: .center)
    }
}

#Preview {
    CategoryPieChartView(spendingData: AppState(receipts: SampleData.receipts).categorySpendingData)
        .padding()
}

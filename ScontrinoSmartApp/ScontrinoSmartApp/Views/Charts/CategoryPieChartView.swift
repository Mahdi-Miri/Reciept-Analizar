//
//  CategoryPieChartView.swift
//  ScontrinoSmartApp
//
//  Created by Gemini (Generated) on 13/11/25.
//
//  *** THIS FILE IS REQUIRED for ModernDashboardView ***
//

import SwiftUI
import Charts

struct CategoryPieChartView: View {
    let spendingData: [CategorySpending]
    
    var body: some View {
        Chart(spendingData) { item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.6), // This makes it a donut chart
                angularInset: 2
            )
            .foregroundStyle(item.category.color) // Uses the color from your GroceryModels
            .cornerRadius(4)
        }
    }
}

#Preview {
    CategoryPieChartView(spendingData: AppState(receipts: SampleData.receipts).categorySpendingData)
        .padding()
}

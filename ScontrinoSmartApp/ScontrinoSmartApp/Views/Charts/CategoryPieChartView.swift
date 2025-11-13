// CategoryPieChartView.swift
// Pie chart with donut center showing total and modern slice styling.
// Replace the previous CategoryPieChartView content with this file.

import SwiftUI
import Charts

struct CategoryPieChartView: View {
    let spendingData: [CategorySpending]

    private var totalSpend: Double {
        spendingData.reduce(0) { $0 + $1.amount }
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        Chart(spendingData) { item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.62),
                angularInset: 1.2
            )
            .foregroundStyle(by: .value("Category", item.category.rawValue))
            // .cornerRadius is allowed on Chart marks (as of modern Charts), but keep subtle
            .cornerRadius(6)
            .annotation(position: .overlay, alignment: .center) {
                // center annotation is handled globally; keep slices clean
                EmptyView()
            }
        }
        .chartForegroundStyleScale(
            domain: spendingData.map { $0.category.rawValue },
            range: spendingData.map { $0.category.color }
        )
        .chartLegend(position: .bottom, alignment: .center)
        .chartBackground { proxy in
            GeometryReader { geo in
                let frame = geo.frame(in: .local)
                VStack(spacing: 6) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalSpend, format: .currency(code: currencyCode))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
            }
        }
        .padding(.vertical, 6)
    }
}

// Preview
#Preview {
    CategoryPieChartView(spendingData: AppState(receipts: SampleData.receipts).categorySpendingData)
        .frame(height: 260)
        .padding()
}


//
//  BudgetView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    
    // 1. SwiftData Queries
    @Environment(\.modelContext) private var modelContext
    @Query private var receipts: [Receipt]
    @Query private var budgets: [Budget]
    
    // 2. State Variables
    @State private var budgetStatusList: [BudgetStatus] = []
    @State private var isShowingBudgetAlert = false
    @State private var selectedCategory = ""
    @State private var budgetAmountString = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Monthly Budgets")) {
                    if budgetStatusList.isEmpty {
                        Text("No spending or budgets for this month.")
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(budgetStatusList, id: \.category) { status in
                        BudgetRowView(status: status)
                            .onTapGesture {
                                presentBudgetAlert(for: status)
                            }
                    }
                }
            }
            .navigationTitle("Budgets")
            .onAppear {
                calculateBudgetStatus()
            }
            .alert("Set Budget for \(selectedCategory)", isPresented: $isShowingBudgetAlert) {
                TextField("Amount (e.g., 500)", text: $budgetAmountString)
                    .keyboardType(.decimalPad)
                
                Button("Save") {
                    saveBudget()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    // MARK: - Logic Functions
    
    private func calculateBudgetStatus() {
        let calendar = Calendar.current
        let currentDate = Date()
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let (currentMonth, currentYear) = (components.month ?? 1, components.year ?? 2025)

        let categoriesFromReceipts = Set(receipts.map { $0.category })
        let categoriesFromBudgets = Set(budgets.map { $0.category })
        let allCategories = Array(categoriesFromReceipts.union(categoriesFromBudgets)).sorted()
        
        var newStatusList: [BudgetStatus] = []
        
        for category in allCategories {
            
            let budgetAmount = budgets.first {
                $0.category == category && $0.month == currentMonth && $0.year == currentYear
            }?.amount ?? 0.0
            
            let spentAmount = receipts.filter {
                let receiptComponents = calendar.dateComponents([.year, .month], from: $0.transactionDate)
                return $0.category == category &&
                       receiptComponents.year == currentYear &&
                       receiptComponents.month == currentMonth
            }.reduce(0) { $0 + $1.totalAmount }
            
            if budgetAmount > 0 || spentAmount > 0 {
                newStatusList.append(BudgetStatus(
                    category: category,
                    budgetedAmount: budgetAmount,
                    spentAmount: spentAmount
                ))
            }
        }
        
        self.budgetStatusList = newStatusList
    }
    
    private func presentBudgetAlert(for status: BudgetStatus) {
        selectedCategory = status.category
        if status.budgetedAmount > 0 {
            budgetAmountString = String(format: "%.0f", status.budgetedAmount)
        } else {
            budgetAmountString = ""
        }
        isShowingBudgetAlert = true
    }
    
    private func saveBudget() {
        guard let amount = Double(budgetAmountString) else { return }
        
        let calendar = Calendar.current
        let currentDate = Date()
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let (currentMonth, currentYear) = (components.month ?? 1, components.year ?? 2025)

        let id = "\(selectedCategory)-\(currentYear)-\(currentMonth)"
        
        if let existingBudget = budgets.first(where: { $0.id == id }) {
            existingBudget.amount = amount
        } else {
            let newBudget = Budget(category: selectedCategory, amount: amount, date: currentDate)
            modelContext.insert(newBudget)
        }
        
        calculateBudgetStatus()
    }
}

// MARK: - Helper Structs
struct BudgetStatus {
    let category: String
    let budgetedAmount: Double
    let spentAmount: Double
    
    var remainingAmount: Double { budgetedAmount - spentAmount }
    
    var progress: Double {
        guard budgetedAmount > 0 else { return 0 }
        return max(0, min(spentAmount / budgetedAmount, 1.0))
    }
    
    var progressColor: Color {
        if progress > 0.9 { return .red }
        else if progress > 0.7 { return .orange }
        return .blue
    }
}

// A view for showing a single budget row
struct BudgetRowView: View {
    let status: BudgetStatus
    
    // Helper to get an icon
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Groceries": return "cart.fill"
        case "Restaurant": return "fork.knife"
        case "Transport": return "car.fill"
        case "Clothing": return "bag.fill"
        case "Health": return "heart.fill"
        default: return "doc.text.fill"
        }
    }
    
    // --- FIX: Add this reliable currency formatter function ---
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR" // Or make this dynamic
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Row 1: Category Name and Icon
            HStack {
                Image(systemName: categoryIcon(for: status.category))
                    .foregroundColor(status.progressColor)
                Text(status.category)
                    .font(.headline)
                Spacer()
            }
            
            // Row 2: Progress Bar
            ProgressView(value: status.progress)
                .tint(status.progressColor)
            
            // Row 3: Text labels
            HStack {
                // --- FIX: Use reliable currency formatter ---
                Text(formatCurrency(status.spentAmount))
                    .font(.subheadline)
                    .foregroundColor(status.progressColor)
                Spacer()
                if status.budgetedAmount > 0 {
                    // --- FIX: Use reliable currency formatter ---
                    Text("of \(formatCurrency(status.budgetedAmount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

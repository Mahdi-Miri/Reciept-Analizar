//
//  BudgetView.swift
//  
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    
    // 1. SwiftData Queries
    @Environment(\.modelContext) private var modelContext
    
    // We fetch ALL receipts and ALL budgets
    // The view's logic will filter them for the current month.
    @Query private var receipts: [Receipt]
    @Query private var budgets: [Budget]
    
    // 2. State Variables
    // These will hold the data calculated for the *current* month
    @State private var budgetStatusList: [BudgetStatus] = []
    
    // For showing the "Set Budget" alert
    @State private var isShowingBudgetAlert = false
    @State private var selectedCategory = ""
    @State private var budgetAmountString = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Monthly Budgets")) {
                    // Check if there is anything to show
                    if budgetStatusList.isEmpty {
                        Text("No spending or budgets for this month.")
                            .foregroundColor(.secondary)
                    }
                    
                    // Loop over the calculated budget statuses
                    ForEach(budgetStatusList, id: \.category) { status in
                        BudgetRowView(status: status)
                            .onTapGesture {
                                // Show alert to set/update budget for this category
                                presentBudgetAlert(for: status)
                            }
                    }
                }
            }
            .navigationTitle("Budgets")
            .onAppear {
                // When the view appears, calculate the current month's status
                calculateBudgetStatus()
            }
            .alert("Set Budget for \(selectedCategory)", isPresented: $isShowingBudgetAlert) {
                // Alert UI
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
    
    // This is the main logic engine for this view
    private func calculateBudgetStatus() {
        let calendar = Calendar.current
        let currentDate = Date() // Today's date
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let (currentMonth, currentYear) = (components.month ?? 1, components.year ?? 2025)

        // 1. Get all unique categories from receipts
        let categoriesFromReceipts = Set(receipts.map { $0.category })
        let categoriesFromBudgets = Set(budgets.map { $0.category })
        let allCategories = Array(categoriesFromReceipts.union(categoriesFromBudgets)).sorted()
        
        var newStatusList: [BudgetStatus] = []
        
        for category in allCategories {
            
            // 2. Find the budget for this category THIS month
            let budgetAmount = budgets.first {
                $0.category == category && $0.month == currentMonth && $0.year == currentYear
            }?.amount ?? 0.0
            
            // 3. Calculate spending for this category THIS month
            let spentAmount = receipts.filter {
                let receiptComponents = calendar.dateComponents([.year, .month], from: $0.transactionDate)
                return $0.category == category &&
                       receiptComponents.year == currentYear &&
                       receiptComponents.month == currentMonth
            }.reduce(0) { $0 + $1.totalAmount }
            
            // 4. Only show categories that have a budget or spending
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
    
    // Pre-fill and show the alert
    private func presentBudgetAlert(for status: BudgetStatus) {
        selectedCategory = status.category
        if status.budgetedAmount > 0 {
            budgetAmountString = String(format: "%.0f", status.budgetedAmount)
        } else {
            budgetAmountString = ""
        }
        isShowingBudgetAlert = true
    }
    
    // Save the new budget amount to SwiftData
    private func saveBudget() {
        guard let amount = Double(budgetAmountString) else { return }
        
        let calendar = Calendar.current
        let currentDate = Date()
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let (currentMonth, currentYear) = (components.month ?? 1, components.year ?? 2025)

        // Create the unique ID for this budget
        let id = "\(selectedCategory)-\(currentYear)-\(currentMonth)"
        
        // Check if a budget for this category/month already exists
        if let existingBudget = budgets.first(where: { $0.id == id }) {
            // Update existing
            existingBudget.amount = amount
        } else {
            // Create new
            let newBudget = Budget(category: selectedCategory, amount: amount, date: currentDate)
            modelContext.insert(newBudget)
        }
        
        // Recalculate everything to update the UI
        calculateBudgetStatus()
    }
}

// MARK: - Helper Structs

// A simple struct to hold the calculated status
struct BudgetStatus {
    let category: String
    let budgetedAmount: Double
    let spentAmount: Double
    
    var remainingAmount: Double { budgetedAmount - spentAmount }
    
    // Calculate progress from 0.0 to 1.0 (for the Progress Bar)
    var progress: Double {
        guard budgetedAmount > 0 else { return 0 }
        return max(0, min(spentAmount / budgetedAmount, 1.0)) // Cap between 0 and 1
    }
    
    var progressColor: Color {
        if progress > 0.9 {
            return .red // Over 90%
        } else if progress > 0.7 {
            return .orange // Over 70%
        }
        return .blue // Use our theme color
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
        case: "Transport": return "car.fill"
        case "Clothing": return "bag.fill"
        case "Health": return "heart.fill"
        default: return "doc.text.fill"
        }
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
                .tint(status.progressColor) // Use our theme-aware color
            
            // Row 3: Text labels (e.g., "$150 spent of $400")
            HStack {
                Text(status.spentAmount, format: .currency(code: "EUR"))
                    .font(.subheadline)
                    .foregroundColor(status.progressColor)
                Spacer()
                if status.budgetedAmount > 0 {
                    Text("of \(status.budgetedAmount, format: .currency(code: "EUR"))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

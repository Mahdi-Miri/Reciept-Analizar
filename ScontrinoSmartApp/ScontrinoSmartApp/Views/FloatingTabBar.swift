//
//  FloatingTabBar.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI

// 1. Define the Tab enum here (or in its own file)
// This makes it available to both ContentView and FloatingTabBar.
enum Tab: CaseIterable {
    case dashboard
    case scan
    // Add other tabs here if you need them
}

struct FloatingTabBar: View {
    
    // 2. Create a namespace property for the animation
    @Namespace private var animationNamespace

    // 3. Bind to the independent 'Tab' enum, not 'ContentView.Tab'
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 24) {
            // Pass the namespace to each button
            tabButton(icon: "chart.pie.fill", title: "Dashboard", tab: .dashboard)
            tabButton(icon: "camera.fill", title: "Scan", tab: .scan)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 8)
        .overlay(
            Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .frame(maxWidth: 420)
        .padding(.horizontal, 10)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    // 4. Update the function to accept the independent 'Tab' enum
    private func tabButton(icon: String, title: String, tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 28)
                
                if selectedTab == tab {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            // Using .blue here matches your white/blue theme preference
            .foregroundColor(selectedTab == tab ? .blue : Color.primary.opacity(0.7))
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .background(
                Group {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 12)
                            // Using .blue here matches your white/blue theme preference
                            .fill(Color.blue.opacity(0.12))
                            // 5. Use the shared 'animationNamespace'
                            // (Using Namespace() here creates a new one every time, breaking the animation)
                            .matchedGeometryEffect(id: "tabBackground", in: animationNamespace)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


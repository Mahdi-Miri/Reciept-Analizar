//
//  FloatingTabBar.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

// FloatingTabBar.swift
// A modern floating pill-shaped tab bar with subtle blur and shadow.
// Add this as a new file and import where needed.

import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        HStack(spacing: 24) {
            tabButton(icon: "chart.pie.fill", title: "Dashboard", tab: .dashboard)
            Spacer(minLength: 12)
            tabButton(icon: "camera.fill", title: "Scan", tab: .scan)
        }
        .padding(.vertical, 12)
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
    private func tabButton(icon: String, title: String, tab: ContentView.Tab) -> some View {
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
            .foregroundColor(selectedTab == tab ? .blue : Color.primary.opacity(0.7))
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                Group {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.12))
                            .matchedGeometryEffect(id: "tabBackground", in: Namespace().wrappedValue, properties: .frame)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// View+Extensions.swift
// Helpful view extensions used across the app.

import SwiftUI

// Custom shape drawing borders for specific edges
struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat = 0, y: CGFloat = 0, x2: CGFloat = 0, y2: CGFloat = 0
            switch edge {
            case .top:
                x = rect.minX; y = rect.minY; x2 = rect.maxX; y2 = rect.minY
            case .bottom:
                x = rect.minX; y = rect.maxY; x2 = rect.maxX; y2 = rect.maxY
            case .leading:
                x = rect.minX; y = rect.minY; x2 = rect.minX; y2 = rect.maxY
            case .trailing:
                x = rect.maxX; y = rect.minY; x2 = rect.maxX; y2 = rect.maxY
            }
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x2, y: y2))
        }
        return path
    }
}

extension View {
    // Apply border on selected edges only
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(
            EdgeBorder(width: width, edges: edges)
                .stroke(color, lineWidth: width)
        )
    }
}

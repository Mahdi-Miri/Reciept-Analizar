// AnimatedBackgroundView.swift
// Improved animated gradient background — softer blur, more vibrant hues.
// Replace or update your existing AnimatedBackgroundView.

import SwiftUI
import Combine

struct AnimatedBackgroundView: View {
    @State private var start = UnitPoint(x: -1, y: -0.5)
    @State private var end = UnitPoint(x: 1.5, y: 1)
    let timer = Timer.publish(every: 3.2, on: .main, in: .common).autoconnect()

    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color("AccentBlue").opacity(0.95), location: 0.0),
                .init(color: Color.blue.opacity(0.12), location: 0.35),
                .init(color: Color.cyan.opacity(0.18), location: 0.6),
                .init(color: Color("AccentPurple").opacity(0.9), location: 1.0)
            ]),
            startPoint: start,
            endPoint: end
        )
        .blendMode(.overlay)
        .blur(radius: 80)
        .overlay(
            // subtle noise/soft white overlay to add depth
            Color.white.opacity(0.02).blendMode(.screen)
        )
        .ignoresSafeArea()
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 4.2)) {
                start = UnitPoint(x: Double.random(in: -1.2...0.2), y: Double.random(in: -1.0...0.2))
                end = UnitPoint(x: Double.random(in: 0.8...2.2), y: Double.random(in: -0.1...1.5))
            }
        }
    }
}

// If you prefer to rely solely on system colors, remove Color("AccentBlue") and Color("AccentPurple")
// or define them in Assets. Using named assets makes it easy to tweak the palette.
#Preview {
    AnimatedBackgroundView()
}

//
//  RetroComponents.swift
//  Antidote
//
//  Created by Codex on 2025-03-17.
//

import SwiftUI

struct RetroButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case warning
        case danger
    }
    
    var kind: Kind = .primary
    var cornerRadius: CGFloat = 28
    var shadowRadius: CGFloat = 18
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RetroTheme.Typography.body(20))
            .foregroundColor(RetroTheme.Palette.text)
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(backgroundColor(isPressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: RetroTheme.Palette.highlight.opacity(0.25), radius: shadowRadius, x: 0, y: 10)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        let base: Color
        switch kind {
        case .primary:
            base = RetroTheme.Palette.primaryAccent
        case .secondary:
            base = RetroTheme.Palette.secondaryAccent
        case .warning:
            base = RetroTheme.Palette.warning
        case .danger:
            base = RetroTheme.Palette.locked
        }
        
        return isPressed ? base.opacity(0.7) : base
    }
}

struct RetroToggle: View {
    @Binding var isOn: Bool
    var label: String? = nil
    var trackSize: CGSize = CGSize(width: 220, height: 64)
    var knobSize: CGSize = CGSize(width: 52, height: 52)
    
    var body: some View {
        let knobTravel = max((trackSize.width - knobSize.width) / 2 - 6, 0)
        let trackGradient = LinearGradient(
            colors: isOn
            ? [RetroTheme.Palette.primaryAccent, RetroTheme.Palette.primaryAccent.opacity(0.75)]
            : [Color.gray.opacity(0.7), Color.gray.opacity(0.35)],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }) {
            HStack(spacing: 16) {
                if let label {
                    Text(label.uppercased())
                        .font(RetroTheme.Typography.body(18))
                        .foregroundColor(RetroTheme.Palette.text)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Capsule()
                    .fill(trackGradient)
                    .frame(width: trackSize.width, height: trackSize.height)
                    .overlay(
                        HStack {
                            Text("OFF")
                                .font(RetroTheme.Typography.body(14))
                                .foregroundColor(isOn ? RetroTheme.Palette.text.opacity(0.45) : RetroTheme.Palette.text)
                            Spacer()
                            Text("ON")
                                .font(RetroTheme.Typography.body(14))
                                .foregroundColor(isOn ? RetroTheme.Palette.text : RetroTheme.Palette.text.opacity(0.45))
                        }
                        .padding(.horizontal, 28)
                    )
                    .overlay(
                        Circle()
                            .fill(RetroTheme.Palette.text)
                            .frame(width: knobSize.width, height: knobSize.height)
                            .overlay(
                                Circle()
                                    .stroke(RetroTheme.Palette.highlight.opacity(0.35), lineWidth: 1.5)
                            )
                            .offset(x: isOn ? knobTravel : -knobTravel)
                            .shadow(color: RetroTheme.Palette.highlight.opacity(0.4), radius: 8, x: 0, y: 2),
                        alignment: .center
                    )
                    .animation(.easeInOut(duration: 0.25), value: isOn)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

struct RetroPanel<Content: View>: View {
    var title: String?
    var content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title, !title.isEmpty {
                Text(title.uppercased())
                    .font(RetroTheme.Typography.title(16))
                    .foregroundColor(RetroTheme.Palette.secondaryAccent)
                    .padding(.bottom, 8)
                    .overlay(
                        Rectangle()
                            .fill(RetroTheme.Palette.panelBorder)
                            .frame(height: 1)
                            .offset(y: 12),
                        alignment: .bottom
                    )
            }
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(RetroTheme.Palette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(RetroTheme.Palette.panelBorder, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 12)
        )
    }
}

struct GlitchOverlay: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.clear,
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                NoiseTexture()
                    .blendMode(.screen)
                ScanlineOverlay()
            }
        }
        .allowsHitTesting(false)
        .opacity(0.65)
    }
}

private struct NoiseTexture: View {
    @State private var seed = Double.random(in: 0...1)
    
    var body: some View {
        Canvas { context, size in
            let stripes = 40
            for index in 0..<stripes {
                let randomHeight = CGFloat.random(in: 1...4)
                let y = CGFloat(index) / CGFloat(stripes) * size.height
                var rect = CGRect(x: 0, y: y, width: size.width, height: randomHeight)
                rect.origin.x += CGFloat.random(in: -4...4)
                context.fill(Path(rect), with: .color(Color.white.opacity(Double.random(in: 0.02...0.08))))
            }
        }
        .drawingGroup()
        .onAppear {
            seed = Double.random(in: 0...1)
        }
    }
}

private struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let count = Int(proxy.size.height / 2)
            VStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { _ in
                    Color.white.opacity(0.05)
                        .frame(height: 1)
                    Color.clear.frame(height: 1)
                }
            }
        }
    }
}

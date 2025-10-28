//
//  ChallengeView.swift
//  Antidote
//
//  Created by Codex on 2025-03-17.
//

import SwiftUI

struct ChallengeView: View {
    enum Outcome {
        case success
        case failure
        case cancelled
    }
    
    var onComplete: (Outcome) -> Void
    
    @State private var leftOperand = Int.random(in: 4...18)
    @State private var rightOperand = Int.random(in: 4...18)
    @State private var options: [Int] = []
    @State private var timeRemaining = 30
    @State private var selectionFeedback: String?
    @State private var isResolved = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 22) {
            Text("BOOSTER CHALLENGE")
                .font(RetroTheme.Typography.title(18))
                .foregroundColor(RetroTheme.Palette.warning)
                .padding(.top, 16)
            
            Text("Solve before the timer hits zero to earn a 5 minute booster dose.")
                .font(RetroTheme.Typography.body(13))
                .foregroundColor(RetroTheme.Palette.text.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(RetroTheme.Palette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(RetroTheme.Palette.secondaryAccent, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 10)
                VStack(spacing: 18) {
                    Text("TIME LEFT")
                        .font(RetroTheme.Typography.body(12))
                        .foregroundColor(RetroTheme.Palette.text.opacity(0.7))
                    
                    Text("\(timeRemaining)s")
                        .font(RetroTheme.Typography.title(26))
                        .foregroundColor(RetroTheme.Palette.primaryAccent)
                        .shadow(color: RetroTheme.Palette.primaryAccent.opacity(0.6), radius: 10)
                }
                .padding(32)
            }
            
            Text("\(leftOperand) + \(rightOperand) = ?")
                .font(RetroTheme.Typography.title(24))
                .foregroundColor(RetroTheme.Palette.text)
                .padding(.vertical, 6)
            
            VStack(spacing: 16) {
                ForEach(options, id: \.self) { value in
                    Button(action: {
                        evaluate(answer: value)
                    }) {
                        Text("\(value)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RetroButtonStyle(kind: .primary))
                }
            }
            .padding(.horizontal, 24)
            
            if let feedback = selectionFeedback {
                Text(feedback)
                    .font(RetroTheme.Typography.body(12))
                    .foregroundColor(RetroTheme.Palette.secondaryAccent)
                    .transition(.opacity.combined(with: .scale))
            }
            
            Button("Abort Mission") {
                onComplete(.cancelled)
            }
            .buttonStyle(RetroButtonStyle(kind: .secondary))
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(RetroTheme.Palette.background.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(RetroTheme.Palette.panelBorder, lineWidth: 2)
                )
        )
        .padding(40)
        .background(
            LinearGradient(
                colors: [
                    RetroTheme.Palette.background,
                    RetroTheme.Palette.locked.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear(perform: generateOptions)
        .onReceive(timer) { _ in
            guard !isResolved else { return }
            guard timeRemaining > 0 else {
                isResolved = true
                onComplete(.failure)
                return
            }
            timeRemaining -= 1
        }
    }
    
    private func generateOptions() {
        let correct = leftOperand + rightOperand
        var generated = Set<Int>()
        generated.insert(correct)
        
        while generated.count < 3 {
            let offset = Int.random(in: -4...4)
            let candidate = max(0, correct + offset)
            generated.insert(candidate)
        }
        
        options = Array(generated).shuffled()
    }
    
    private func evaluate(answer: Int) {
        let correct = leftOperand + rightOperand
        if answer == correct {
            selectionFeedback = "BOOSTER GRANTED!"
            isResolved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onComplete(.success)
            }
        } else {
            selectionFeedback = "Try again..."
            isResolved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onComplete(.failure)
            }
        }
    }
}

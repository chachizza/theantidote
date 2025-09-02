import SwiftUI

struct StroopChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var challengeState = StorageManager.shared.loadChallengeState()
    @State private var currentWord = ""
    @State private var currentColor: Color = .blue
    @State private var options: [String] = []
    @State private var score = 0
    @State private var maxScore = 10
    @State private var timeRemaining = 60
    @State private var isActive = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    private let colorNames = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange"]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Text("\(score)/\(maxScore)")
                    .font(.title2.bold())
                Spacer()
                Text("\(timeRemaining)s")
                    .font(.title2.bold())
                    .foregroundColor(timeRemaining <= 10 ? .red : .primary)
            }
            .padding()
            
            // Instructions
            Text("Tap the color that matches the word's meaning, not the color it's written in!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Stroop Test
            VStack(spacing: 24) {
                Text(currentWord)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(currentColor)
                    .frame(height: 60)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            handleAnswer(option)
                        }) {
                            Text(option)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(getColor(for: option))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .onAppear {
            startChallenge()
        }
        .onReceive(timer) { _ in
            if isActive && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 {
                handleTimeUp()
            }
        }
        .alert("Challenge Complete!", isPresented: .constant(score == maxScore)) {
            Button("Continue", role: .cancel) {
                completeChallenge()
            }
        } message: {
            Text("Great job! You completed the Stroop challenge.")
        }
        .alert("Time's Up!", isPresented: .constant(timeRemaining == 0 && isActive)) {
            Button("Try Again", role: .cancel) {
                resetChallenge()
            }
            Button("Cancel", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("You scored \(score)/\(maxScore) points.")
        }
    }
    
    private func startChallenge() {
        challengeState.startChallenge(type: "Stroop")
        StorageManager.shared.saveChallengeState(challengeState)
        
        score = 0
        timeRemaining = 60
        isActive = true
        generateNewWord()
    }
    
    private func generateNewWord() {
        let wordIndex = Int.random(in: 0..<colorNames.count)
        let colorIndex = Int.random(in: 0..<colors.count)
        
        currentWord = colorNames[wordIndex]
        currentColor = colors[colorIndex]
        
        // Generate options
        var availableOptions = colorNames
        availableOptions.remove(at: wordIndex)
        options = Array(availableOptions.shuffled().prefix(3))
        options.append(colorNames[wordIndex])
        options.shuffle()
    }
    
    private func handleAnswer(_ answer: String) {
        let wordIndex = colorNames.firstIndex(of: currentWord) ?? 0
        let correctAnswer = colorNames[wordIndex]
        
        if answer == correctAnswer {
            score += 1
            if score >= maxScore {
                isActive = false
            } else {
                generateNewWord()
            }
        } else {
            // Incorrect answer
            timeRemaining -= 5 // Penalty
        }
    }
    
    private func handleTimeUp() {
        isActive = false
        if score >= maxScore {
            completeChallenge()
        }
    }
    
    private func completeChallenge() {
        challengeState.completeChallenge()
        StorageManager.shared.saveChallengeState(challengeState)
        dismiss()
    }
    
    private func resetChallenge() {
        startChallenge()
    }
    
    private func getColor(for name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
    }
}

struct StroopChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        StroopChallengeView()
    }
}
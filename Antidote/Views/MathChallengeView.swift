import SwiftUI

struct MathChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var challengeState = StorageManager.shared.loadChallengeState()
    @State private var currentProblem = ""
    @State private var correctAnswer = 0
    @State private var userAnswer = ""
    @State private var score = 0
    @State private var maxScore = 10
    @State private var timeRemaining = 120
    @State private var isActive = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showingProblem = true
    @FocusState private var isTextFieldFocused: Bool
    
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
                    .foregroundColor(timeRemaining <= 30 ? .red : .primary)
            }
            .padding()
            
            // Instructions
            Text("Solve the math problems as quickly as possible!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if showingProblem {
                // Problem Display
                VStack(spacing: 24) {
                    Text(currentProblem)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .transition(.opacity)
                    
                    HStack(spacing: 16) {
                        Text("=")
                            .font(.system(size: 36, weight: .bold))
                        
                        TextField("Answer", text: $userAnswer)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 24, weight: .bold))
                            .keyboardType(.numberPad)
                            .frame(width: 100)
                            .focused($isTextFieldFocused)
                    }
                    
                    Button("Submit") {
                        submitAnswer()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userAnswer.isEmpty)
                }
                .padding(.horizontal)
                .onAppear {
                    isTextFieldFocused = true
                }
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
            Text("Great job! You completed the Math challenge.")
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
        challengeState.startChallenge(type: "Math")
        StorageManager.shared.saveChallengeState(challengeState)
        
        score = 0
        timeRemaining = 120
        isActive = true
        userAnswer = ""
        generateNewProblem()
    }
    
    private func generateNewProblem() {
        let operations = ["+", "-", "×"]
        let operation = operations.randomElement() ?? "+"
        
        let num1: Int
        let num2: Int
        
        switch operation {
        case "+":
            num1 = Int.random(in: 1...99)
            num2 = Int.random(in: 1...99)
            correctAnswer = num1 + num2
        case "-":
            num1 = Int.random(in: 10...99)
            num2 = Int.random(in: 1...num1)
            correctAnswer = num1 - num2
        case "×":
            num1 = Int.random(in: 1...12)
            num2 = Int.random(in: 1...12)
            correctAnswer = num1 * num2
        default:
            num1 = 0
            num2 = 0
            correctAnswer = 0
        }
        
        currentProblem = "\(num1) \(operation) \(num2)"
        userAnswer = ""
        showingProblem = true
    }
    
    private func submitAnswer() {
        guard let userAnswerInt = Int(userAnswer) else {
            userAnswer = ""
            return
        }
        
        if userAnswerInt == correctAnswer {
            score += 1
            if score >= maxScore {
                isActive = false
            } else {
                withAnimation {
                    showingProblem = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        generateNewProblem()
                        showingProblem = true
                    }
                }
            }
        } else {
            // Incorrect answer
            timeRemaining -= 10 // Penalty
            userAnswer = ""
        }
    }
    
    private func handleTimeUp() {
        isActive = false
        if score >= maxScore {
            completeChallenge()
        }
    }
    
    private func completeChallenge() {
        // Grant a 15-minute bypass for completing the challenge.
        BypassManager.shared.grantBypass(for: 15)
        
        challengeState.completeChallenge()
        StorageManager.shared.saveChallengeState(challengeState)
        dismiss()
    }
    
    private func resetChallenge() {
        startChallenge()
    }
}

struct MathChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        MathChallengeView()
    }
}
import SwiftUI

struct BreathChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isBreathing = false
    @State private var breathPhase = "Inhale"
    @State private var progress: CGFloat = 0
    @State private var cycleCount = 0
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let maxCycles = 5
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 8) {
                Text("Mindful Breathing")
                    .font(.largeTitle.bold())
                Text("Follow the circle to breathe mindfully")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Progress
            Text("Cycle \(cycleCount)/\(maxCycles)")
                .font(.headline)
                .foregroundColor(.blue)
            
            // Breathing Circle
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .scaleEffect(isBreathing ? 2.0 : 1.0)
                    .animation(.easeInOut(duration: 4), value: isBreathing)
                
                VStack {
                    Text(breathPhase)
                        .font(.title.bold())
                    Text(isBreathing ? "Hold" : "Release")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Instructions
            VStack(spacing: 16) {
                if !isBreathing {
                    Button("Start Breathing Exercise") {
                        startBreathing()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .onReceive(timer) { _ in
            if isBreathing {
                updateBreathing()
            }
        }
        .alert("Exercise Complete!", isPresented: .constant(cycleCount >= maxCycles)) {
            Button("Finish", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("You've completed the mindful breathing exercise. Great job!")
        }
    }
    
    private func startBreathing() {
        isBreathing = true
        cycleCount = 0
        startBreathingCycle()
    }
    
    private func startBreathingCycle() {
        breathPhase = "Inhale"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            breathPhase = "Hold"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                breathPhase = "Exhale"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    cycleCount += 1
                    if cycleCount < maxCycles {
                        startBreathingCycle()
                    } else {
                        isBreathing = false
                    }
                }
            }
        }
    }
    
    private func updateBreathing() {
        // This could be expanded with more sophisticated breathing patterns
    }
}

struct BreathChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        BreathChallengeView()
    }
}
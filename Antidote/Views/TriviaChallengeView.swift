import SwiftUI

struct TriviaChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Trivia Challenge")
                .font(.largeTitle.bold())
            
            Text("This challenge is coming soon!")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("You'll be able to test your knowledge with general trivia questions to unlock your apps.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Return to Dashboard") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct TriviaChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        TriviaChallengeView()
    }
}
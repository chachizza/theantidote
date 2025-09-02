import SwiftUI

struct ChallengeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.load()
    @State private var challengeState = StorageManager.shared.loadChallengeState()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Choose Your Challenge")
                    .font(.title2.bold())
                    .padding(.top, 32)
                
                if challengeState.isLocked {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Challenge Locked")
                            .font(.headline)
                        
                        Text("Please wait before trying again")
                            .foregroundColor(.secondary)
                        
                        Text("Try again in \(timeString(from: challengeState.lockoutEndTime))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 16) {
                        ForEach(ChallengeType.allCases, id: \.self) { challenge in
                            ChallengeCardView(
                                challenge: challenge,
                                isSelected: settings.challengeType == challenge,
                                onSelect: {
                                    navigateToChallenge(challenge)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Challenge")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func navigateToChallenge(_ challenge: ChallengeType) {
        // This would navigate to the specific challenge view
        // For now, we'll dismiss and let the main app handle navigation
        dismiss()
    }
    
    private func timeString(from date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: Date(), to: date) ?? ""
    }
}

struct ChallengeCardView: View {
    let challenge: ChallengeType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: challengeIcon(for: challenge))
                    .font(.system(size: 30))
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.rawValue)
                        .font(.headline)
                    Text(challengeDescription(for: challenge))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 1)
        }
        .buttonStyle(.plain)
    }
    
    private func challengeIcon(for challenge: ChallengeType) -> String {
        switch challenge {
        case .stroop: return "paintpalette"
        case .math: return "number"
        case .trivia: return "questionmark.circle"
        case .breath: return "lungs"
        }
    }
    
    private func challengeDescription(for challenge: ChallengeType) -> String {
        switch challenge {
        case .stroop: return "Test your focus with color-word matching"
        case .math: return "Solve mathematical problems"
        case .trivia: return "Answer general knowledge questions"
        case .breath: return "Practice mindful breathing exercises"
        }
    }
}

struct ChallengeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeSelectionView()
    }
}
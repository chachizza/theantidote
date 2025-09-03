import Foundation

enum ChallengeStatus: String, Codable {
    case notStarted
    case inProgress
    case completed
    case failed
    case locked
}

struct ChallengeState: Codable {
    var currentChallenge: String = ""
    var status: ChallengeStatus = .notStarted
    var startTime: Date? = nil
    var endTime: Date? = nil
    var score: Int = 0
    var maxScore: Int = 0
    var remainingAttempts: Int = 1
    var lockoutEndTime: Date? = nil
    
    var isLocked: Bool {
        if let lockout = lockoutEndTime {
            return Date() < lockout
        }
        return false
    }
    
    var formattedElapsedTime: String {
        guard let start = startTime else { return "00:00" }
        let elapsed = Date().timeIntervalSince(start)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    mutating func startChallenge(type: String) {
        currentChallenge = type
        status = .inProgress
        startTime = Date()
        score = 0
        remainingAttempts = 1
    }
    
    mutating func completeChallenge() {
        status = .completed
        endTime = Date()
    }
    
    mutating func failChallenge() {
        status = .failed
        endTime = Date()
        remainingAttempts -= 1
        if remainingAttempts <= 0 {
            lockoutEndTime = Date().addingTimeInterval(600) // 10 minutes
        }
    }
    
    mutating func reset() {
        status = .notStarted
        startTime = nil
        endTime = nil
        score = 0
        maxScore = 0
        remainingAttempts = 1
        lockoutEndTime = nil
    }
}
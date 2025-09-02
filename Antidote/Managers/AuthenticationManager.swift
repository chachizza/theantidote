import Foundation
import LocalAuthentication

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    
    private init() {}
    
    func authenticateWithBiometrics(reason: String = "Unlock Settings") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return await authenticateWithPasscode(reason: reason)
        }
        
        await MainActor.run {
            isAuthenticating = true
        }
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            await MainActor.run {
                isAuthenticated = success
                isAuthenticating = false
            }
            return success
        } catch {
            await MainActor.run {
                isAuthenticating = false
            }
            return await authenticateWithPasscode(reason: reason)
        }
    }
    
    private func authenticateWithPasscode(reason: String) async -> Bool {
        let context = LAContext()
        
        await MainActor.run {
            isAuthenticating = true
        }
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            await MainActor.run {
                isAuthenticated = success
                isAuthenticating = false
            }
            return success
        } catch {
            await MainActor.run {
                isAuthenticated = false
                isAuthenticating = false
            }
            return false
        }
    }
    
    func lock() {
        isAuthenticated = false
    }
    
    func unlock() {
        isAuthenticated = true
    }
}
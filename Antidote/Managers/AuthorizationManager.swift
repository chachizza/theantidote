import Foundation
import FamilyControls
import ManagedSettings

class AuthorizationManager: ObservableObject {
    static let shared = AuthorizationManager()
    
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    
    private init() {}
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            }
        } catch {
            print("Failed to request authorization: \(error)")
            await MainActor.run {
                self.authorizationStatus = .denied
            }
        }
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .approved
    }
}
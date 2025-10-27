import Foundation
import FamilyControls
import ManagedSettings

@MainActor
class AuthorizationManager: ObservableObject {
    static let shared = AuthorizationManager()
    
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    
    private init() {}
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            print("Failed to request authorization: \(error)")
            authorizationStatus = .denied
        }
    }

    func checkAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .approved
    }
}

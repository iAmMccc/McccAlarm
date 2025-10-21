
import Foundation
import AlarmKit

public struct McccAlarm {
    public static let shared = McccAlarm()
    
    private let alarmManager = AlarmManager.shared
    


}


// MARK: 授权
extension McccAlarm {
    public func requestAuthorization() async -> Bool {

        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                let state = try await alarmManager.requestAuthorization()
                return state == .authorized
            } catch {
                return false
            }
        case .denied: return false
        case .authorized: return true
        @unknown default: return false
        }
    }
}


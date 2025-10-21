//
//  McccAlarm+Authorization.swift
//  McccAlarm
//
//  Created by qixin on 2025/10/21.
//

import Foundation
import AlarmKit
// MARK: 授权
extension McccAlarm {
    
    /// 当前的是否授权了
    public var authorizationState: Bool {
        alarmManager.authorizationState == .authorized
    }
    
    
    @discardableResult
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

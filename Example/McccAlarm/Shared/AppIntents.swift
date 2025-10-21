//
//  AppIntents.swift
//  McccAlarm
//
//  Created by qixin on 2025/10/17.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import AlarmKit
import AppIntents

// MARK: - 暂停 Intent
struct PauseIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        if let uuid = UUID(uuidString: alarmID) {
            try AlarmManager.shared.pause(id: uuid)
        } else {
            print("异常的alarmID = \(alarmID)")
        }
        
        return .result()
    }

    static var title: LocalizedStringResource = "Pause"
    static var description = IntentDescription("Pause a countdown")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}

// MARK: - 停止 Intent
struct StopIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        
        if let uuid = UUID(uuidString: alarmID) {
            try AlarmManager.shared.stop(id: uuid)
        } else {
            print("异常的alarmID = \(alarmID)")
        }
        
        return .result()
    }

    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop an alert")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}

// MARK: - 恢复 Intent
struct ResumeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        if let uuid = UUID(uuidString: alarmID) {
            try AlarmManager.shared.resume(id: uuid)
        } else {
            print("异常的alarmID = \(alarmID)")
        }
        return .result()
    }

    static var title: LocalizedStringResource = "Resume"
    static var description = IntentDescription("Resume a countdown")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}

struct OpenAlarmAppIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        
        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenAlarmAppIntentPerformed"),
            object: nil,
            userInfo: ["alarmID": alarmID]
        )
        
        
        return .result()
    }
    
    static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Opens the Sample app")
    static var openAppWhenRun = true
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

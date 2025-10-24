//
//  AppIntentsTest.swift
//  McccAlarm_Example
//
//  Created by qixin on 2025/10/24.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import Foundation
import AlarmKit
import AppIntents

// MARK: - 暂停 Intent
public struct PauseIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        if let uuid = UUID(uuidString: alarmID) {
            try AlarmManager.shared.pause(id: uuid)
        } else {
            print("异常的alarmID = \(alarmID)")
        }
        
        return .result()
    }

    public static var title: LocalizedStringResource = "Pause"
    static var description = IntentDescription("Pause a countdown")

    @Parameter(title: "alarmID")
    var alarmID: String

    public init(alarmID: String) {
        
        print("执行了 PauseIntent alarmID = \(alarmID)")

        self.alarmID = alarmID
    }

    public init() {
        self.alarmID = ""
    }
}

// MARK: - 停止 Intent
public struct StopIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        
        if let uuid = UUID(uuidString: alarmID) {
            try AlarmManager.shared.stop(id: uuid)
        } else {
            print("异常的alarmID = \(alarmID)")
        }
        
        return .result()
    }

    public static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop an alert")

    @Parameter(title: "alarmID")
    var alarmID: String

    public init(alarmID: String) {
        self.alarmID = alarmID
    }

    public init() {
        self.alarmID = ""
    }
}


public struct RepeatIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        
        if let uuid = UUID(uuidString: alarmID) {
            try AlarmManager.shared.countdown(id: uuid)
        } else {
            print("异常的alarmID = \(alarmID)")
        }
        return .result()
    }
    
    public static var title: LocalizedStringResource = "Repeat"
    static var description = IntentDescription("Repeat a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public init() {
        self.alarmID = ""
    }
}

// MARK: - 恢复 Intent
public struct ResumeIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        if let uuid = UUID(uuidString: alarmID) {
            try AlarmManager.shared.resume(id: uuid)
        } else {
            print("异常的alarmID = \(alarmID)")
        }
        return .result()
    }

    public static var title: LocalizedStringResource = "Resume"
    static var description = IntentDescription("Resume a countdown")

    @Parameter(title: "alarmID")
    var alarmID: String

    public init(alarmID: String) {
        print("执行了 ResumeIntent alarmID = \(alarmID)")
        self.alarmID = alarmID
    }

    public init() {
        self.alarmID = ""
    }
}

public struct OpenAlarmAppIntent: LiveActivityIntent {
    public func perform() throws -> some IntentResult {
        try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        
        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenAlarmAppIntentPerformed"),
            object: nil,
            userInfo: ["alarmID": alarmID]
        )
        
        
        return .result()
    }
    
    public static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Opens the Sample app")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public init() {
        self.alarmID = ""
    }
}

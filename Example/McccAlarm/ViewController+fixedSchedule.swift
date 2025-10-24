//
//  ViewController+fixedSchedule.swift
//  McccAlarm_Example
//
//  Created by qixin on 2025/10/24.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import Foundation
import AlarmKit
import SwiftUI
import McccAlarm


extension ViewController {
    var alarm_fixedSchedule: [String: Any] {
        [
            "title": "绝对时间闹钟",
            "list": [
                ["name": "设置一个绝对时间闹钟"],
            ]
        ]
    }
    
    
    func didSelectSection5(atRow row: Int) {
       

        
        let alertContent = AlarmPresentation.Alert(
            title: "Wake Up",  // アラートのタイトル
            stopButton: .stopButton,  // 停止ボタン
            secondaryButton: .openAppButton,  // セカンダリボタン
            secondaryButtonBehavior: .custom)  // ボタンの動作をカスタム実装
        // .default → ボタンを押すと自動的にアラートが閉じる
        // .custom → ボタンを押した時の動作を自分で実装する (secondaryIntentで指定)

        let attributes = AlarmAttributes<McccEmptyMetadata>(
            presentation: AlarmPresentation(
                alert: alertContent,
                countdown: AlarmPresentation.Countdown(title: "倒计时中", pauseButton: .pauseButton),
                paused: AlarmPresentation.Paused(title: "启动", resumeButton: .resumeButton)
            ),  // アラート設定
//            metadata: CookingData(method: .oven),
            tintColor: Color.accentColor)  // アラートのテーマカラー

        let id = UUID()  // アラームの一意な識別子
        let alarmConfiguration = AlarmConfiguration(
            countdownDuration: Alarm.CountdownDuration(preAlert: 50, postAlert: 10),
            schedule: .oneMinsFromNow,  // いつ鳴らすか
            attributes: attributes,  // 表示設定
            stopIntent: StopIntent(alarmID: id.uuidString),  // 停止ボタンの処理
            secondaryIntent: OpenAlarmAppIntent(alarmID: id.uuidString))  // セカンダリボタンの処理

        scheduleAlarm(id: id, label: "Wake Up", alarmConfiguration: alarmConfiguration)
    }
    
    private func scheduleAlarm(
        id: UUID, label: LocalizedStringResource, alarmConfiguration: AlarmConfiguration
    ) {
        Task {
            let alarm = try await AlarmManager.shared.schedule(
                id: id, configuration: alarmConfiguration)
            print(alarm)
        }
    }
    
}
extension Alarm.Schedule {
    static var fixedDate: Self {
        // 2️⃣ 设定闹钟时间（绝对时间）
        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 24
        components.hour = 10
        components.minute = 30
        components.second = 0

        guard let fireDate = Calendar.current.date(from: components) else {
            fatalError("日期无效")
        }
        
        print("fireDate = \(fireDate)")

        // 相対スケジュールを返す(時刻のみを指定)
        return .fixed(fireDate)
    }
}

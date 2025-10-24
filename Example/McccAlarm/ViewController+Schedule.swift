//
//  ViewController+Alarm.swift
//  McccAlarm_Example
//
//  Created by qixin on 2025/10/20.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import AlarmKit
import SwiftUI
import McccAlarm

typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<McccEmptyMetadata>

extension ViewController {
    var alarm_schedule: [String: Any] {
        [
            "title": "重复性闹钟",
            "list": [
                ["name": "设置重复性闹钟"],
            ]
        ]
    }
    
    
    func didSelectSection4(atRow row: Int) {
       

        
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
    static var oneMinsFromNow: Self {
        // 現在時刻から1分後のアラームスケジュールを生成する
        let oneMinsFromNow = Date().addingTimeInterval(60)
        // 1分後の日付から時間と分を抽出
        let time = Alarm.Schedule.Relative.Time(
            hour: Calendar.current.component(.hour, from: oneMinsFromNow),
            minute: Calendar.current.component(.minute, from: oneMinsFromNow)
        )
        // 相対スケジュールを返す(時刻のみを指定)
        return .relative(.init(time: time))
    }
}

//
//  ViewController+McccAlarm.swift
//  McccAlarm_Example
//
//  Created by qixin on 2025/10/24.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import McccAlarm
import AlarmKit
import SwiftUI



extension ViewController {
    var alarm_McccAlarm: [String: Any] {
        [
            "title": "封装Api",
            "list": [
                ["name": "倒计时 - Countdown方式"]
            ]
        ]
    }
    
    
    func didSelectSection6(atRow row: Int) {
        
        switch row {
        case 0:

            
            let presentation = AlarmPresentation(
                alert: .alert(title: "响铃时标题"),
                countdown: .countDown(title: "倒计时标题"),
                paused: .paused(title: "暂停时标题")
            )
            
            let attributes = AlarmAttributes(
                presentation: presentation,
                metadata: McccEmptyMetadata(),
                tintColor: Color.green
            )
            
            
            let config = AlarmManager.AlarmConfiguration.init(
                countdownDuration: .init(preAlert: 56, postAlert: 10),
                schedule: Alarm.Schedule.fixed(.now.addingTimeInterval(5)),
                attributes: attributes
            )
            
            
            let id = UUID()
            
            Task {
                let alarm = try await AlarmManager.shared.schedule(id: id, configuration: config)
                print("✅ 闹钟已创建: \(alarm)")
            }

            break
            
        case 1:
            break
            
        case 2:
            break
            
        case 3:
            break
            
        default:
            break
        }
    }
}

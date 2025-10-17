//
//  ViewController+Test.swift
//  McccNotify_Example
//
//  Created by qixin on 2025/7/8.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import AlarmKit
import SwiftUI

extension ViewController {
    var alarm_test: [String: Any] {
        [
            "title": "基础测试",
            "list": [
                ["name": "设置一个普通闹钟"],
            ]
        ]
    }
    
    
    func didSelectSection0(atRow row: Int) {

        let stopButton = AlarmButton(text: "结束", textColor: .white, systemImageName: "stop.circle")
        let alert = AlarmPresentation.Alert(title: "你好闹钟", stopButton: stopButton)
        
        let pauseButton = AlarmButton(text: "暂停", textColor: .black, systemImageName: "pause.circle")
        let countdownContent = AlarmPresentation.Countdown(title: "起床中...", pauseButton: pauseButton)
        
        let resumeButton = AlarmButton(text: "恢复", textColor: .black, systemImageName: "play.fill")
        let pausedContent = AlarmPresentation.Paused(title: "暂停", resumeButton: resumeButton)
        
        let presentation = AlarmPresentation(
            alert: alert,
            countdown: countdownContent,
            paused: pausedContent
        )
        
        
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: SimpleMetadata(),
            tintColor: Color.green
        )
        
        let countDown = Alarm.CountdownDuration(preAlert: 300, postAlert: 5)
        
        let config = AlarmManager.AlarmConfiguration.init(
            countdownDuration: countDown,
            attributes: attributes
        )
        
        
        let id = UUID()
        
        Task {
            let alarm = try await AlarmManager.shared.schedule(id: id, configuration: config)
            print("alarm = \(alarm)")
            
            let alarms = try AlarmManager.shared.alarms
            
            print("alarms = \(alarms)")
        }
    }
    
}




struct SimpleMetadata: AlarmMetadata {
    let createdAt: Date
    
    init() {
        self.createdAt = Date()
    }
}

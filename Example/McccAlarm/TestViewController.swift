//
//  TestViewController.swift
//  McccAlarmKit_Example
//
//  Created by qixin on 2025/10/15.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import McccAlarm
import AlarmKit
import SwiftUI
import ActivityKit


class TestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        Task {
//            let state = await McccAlarm.shared.requestAuthorization()
//            print(state)
//        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        let alertContent = AlarmPresentation.Alert(title: "Food Ready",
                                                   stopButton: .stopButton,
                                                   secondaryButton: .repeatButton,
                                                   secondaryButtonBehavior: .countdown)
        
        let countdownContent = AlarmPresentation.Countdown(title: "这是什么", pauseButton: .pauseButton)

        let pausedContent = AlarmPresentation.Paused(title: "Paused", resumeButton: .resumeButton)

        let attributes = AlarmAttributes(presentation: AlarmPresentation(alert: alertContent, countdown: countdownContent, paused: pausedContent),
                                         metadata: CookingData(method: .oven),
                                         tintColor: Color.red)
        
        let id = UUID()
        
        let _ = AlertConfiguration.AlertSound.named("brightEyed.m4a")
        
        let countDown = Alarm.CountdownDuration(preAlert: 5, postAlert: 5)
        
        let config = AlarmManager.AlarmConfiguration.init(countdownDuration: countDown, attributes: attributes)
        
        
        
        Task {
            try await AlarmManager.shared.schedule(id: id, configuration: config)
        }
    }
}

extension AlarmButton {
    static var openAppButton: Self {
        AlarmButton(text: "Open", textColor: .black, systemImageName: "swift")
    }
    
    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .black, systemImageName: "star")
    }
    
    static var resumeButton: Self {
        AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
    }
    
    static var repeatButton: Self {
        AlarmButton(text: "重复", textColor: .black, systemImageName: "repeat.circle")
    }
    
    static var stopButton: Self {
        AlarmButton(text: "结束", textColor: .white, systemImageName: "stop.circle")
    }
}
struct CookingData: AlarmMetadata {
    let createdAt: Date
    let method: Method?
    
    init(method: Method? = nil) {
        self.createdAt = Date.now
        self.method = method
    }
    
    enum Method: String, Codable {
        case stove
        case grill
        case oven
        case fry
        case chill
        
        var icon: String {
            switch self {
            case .stove: "stove"
            case .grill: "fire"
            case .oven: "oven"
            case .fry: "frying.pan"
            case .chill: "snowflake"
            }
        }
    }
}

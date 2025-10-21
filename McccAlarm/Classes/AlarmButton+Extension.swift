//
//  AlarmButton+Extension.swift
//  McccAlarm
//
//  Created by qixin on 2025/10/21.
//

import Foundation
import AlarmKit

extension AlarmButton {
    public static var openAppButton: Self {
        AlarmButton(text: "打开App", textColor: .black, systemImageName: "app")
    }
    
    public static var pauseButton: Self {
        AlarmButton(text: "暂停", textColor: .black, systemImageName: "pause.circle")
    }
    
    public static var resumeButton: Self {
        AlarmButton(text: "开始", textColor: .black, systemImageName: "play.circle")
    }
    
    public static var repeatButton: Self {
        AlarmButton(text: "重复", textColor: .black, systemImageName: "repeat.circle")
    }
    
    public static var stopButton: Self {
        AlarmButton(text: "停止", textColor: .white, systemImageName: "stop.circle")
    }
}

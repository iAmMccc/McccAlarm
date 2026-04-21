//
//  AlarmButton+Extension.swift
//  McccAlarm
//
//  Created by qixin on 2025/10/21.
//

import Foundation
import AlarmKit
import SwiftUI

// MARK: - 按钮文本配置

@available(iOS 26.0, *)
extension McccAlarm {
    /// 按钮文本配置，业务方可在 App 启动时修改
    public struct ButtonText {
        public static var openApp = "打开App"
        public static var pause   = "暂停"
        public static var resume  = "开始"
        public static var `repeat` = "重复"
        public static var sleep   = "小憩"
        public static var stop    = "停止"
    }
}

// MARK: - AlarmButton 便捷构造

@available(iOS 26.0, *)
extension AlarmButton {
    public static var openAppButton: Self {
        AlarmButton(text: "\(McccAlarm.ButtonText.openApp)", textColor: .black, systemImageName: "app.badge")
    }

    public static var pauseButton: Self {
        AlarmButton(text: "\(McccAlarm.ButtonText.pause)", textColor: .black, systemImageName: "pause.fill")
    }

    public static var resumeButton: Self {
        AlarmButton(text: "\(McccAlarm.ButtonText.resume)", textColor: .black, systemImageName: "play.fill")
    }

    public static var repeatButton: Self {
        AlarmButton(text: "\(McccAlarm.ButtonText.repeat)", textColor: .black, systemImageName: "arrow.clockwise")
    }

    public static var sleepButton: Self {
        AlarmButton(text: "\(McccAlarm.ButtonText.sleep)", textColor: .black, systemImageName: "zzz")
    }

    public static var stopButton: Self {
        AlarmButton(text: "\(McccAlarm.ButtonText.stop)", textColor: .white, systemImageName: "xmark")
    }
}

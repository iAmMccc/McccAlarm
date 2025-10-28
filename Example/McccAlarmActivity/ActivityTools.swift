//
//  ActivityTools.swift
//  McccAlarmActivityExtension
//
//  Created by qixin on 2025/10/24.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI
import AlarmKit
import McccAlarm
import AppIntents

struct AlarmControls: View {
    var presentation: AlarmPresentation
    var state: AlarmPresentationState
    var tintColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            switch state.mode {
            case .countdown:
                ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: tintColor)
            case .paused:
                ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: tintColor)
            default:
                EmptyView()
            }

            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: .white)
        }
        .padding(.top, 8)
    }
}



struct ButtonView<I>: View where I: AppIntent {
    var config: AlarmButton
    var intent: I
    var tint: Color
    
    init?(config: AlarmButton?, intent: I, tint: Color) {
        guard let config else { return nil }
        self.config = config
        self.intent = intent
        self.tint = tint
    }
    
    var body: some View {
        Button(intent: intent) {
            Image(systemName: config.systemImageName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint) // 图标颜色
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(tint.gradient) // 圆形背景
                        .opacity(0.25)       // 半透明效果
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle()) // 提高点击区域匹配
    }
}

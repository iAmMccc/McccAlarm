//
//  McccAlarmActivity+Public.swift
//  McccAlarmActivityExtension
//
//  Created by qixin on 2025/10/28.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI
import AlarmKit
import AppIntents
import McccAlarm



/// 操作区域（暂停、恢复、停止）
extension McccAlarmActivity {
    
    // MARK: - 通用闹钟控制区（暂停、恢复、停止）
    @ViewBuilder
    func alarmControlsView(
        presentation: AlarmPresentation,
        state: AlarmPresentationState,
        tint: Color
    ) -> some View {
        HStack(spacing: 12) {
            switch state.mode {
            case .countdown:
                ButtonView(
                    config: presentation.countdown?.pauseButton,
                    intent: PauseIntent(alarmID: state.alarmID.uuidString),
                    tint: tint
                )
            case .paused:
                ButtonView(
                    config: presentation.paused?.resumeButton,
                    intent: ResumeIntent(alarmID: state.alarmID.uuidString),
                    tint: tint
                )
            default:
                EmptyView()
            }

            ButtonView(
                config: presentation.alert.stopButton,
                intent: StopIntent(alarmID: state.alarmID.uuidString),
                tint: .white
            )
        }
        .padding(.top, 8)
    }
    
    // MARK: - 单个按钮构建
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
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(tint.gradient)
                            .opacity(0.25)
                    )
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
        }
    }
}



// 生成标题
extension McccAlarmActivity {
    
    // MARK: - 通用标题视图
    @ViewBuilder
    func alarmTitle(
        attributes: AlarmAttributes<McccAlarmMetadata>,
        state: AlarmPresentationState,
        fontSize: CGFloat = 22,
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        let title: LocalizedStringResource? =
            switch state.mode {
            case .alert:
                attributes.presentation.alert.title
            case .countdown:
                attributes.presentation.countdown?.title
            case .paused:
                attributes.presentation.paused?.title
            @unknown default:
                nil
            }
        
        if let title {
            Text(title)
                .font(.system(size: min(fontSize, 28), weight: .semibold))
                .foregroundStyle(attributes.tintColor)
                .lineLimit(1)
                .frame(maxWidth: maxWidth, alignment: alignment)
        }
    }
}

extension McccAlarmActivity {
    /// 倒计时进度环视图（灵动岛 compact/minimal 用）
    @ViewBuilder
    func countdownProgressView(
        attributes: AlarmAttributes<McccAlarmMetadata>,
        state: AlarmPresentationState,
        scale: CGFloat = 0.8
    ) -> some View {
        let range = getCurrentFireDate(state: state)
        
        ProgressView(
            timerInterval: range,
            countsDown: true,
            label: { EmptyView() },
            currentValueLabel: {
                Image(systemName: "timer")
                    .scaleEffect(scale)
            }
        )
        .progressViewStyle(.circular)
        .tint(attributes.tintColor) // SwiftUI 现代推荐用 tint 替代 foregroundStyle
        .frame(width: 26, height: 26)
        .accessibilityLabel("倒计时进度")
    }
    
    // MARK: - 辅助方法
    private func getCurrentFireDate(state: AlarmPresentationState) -> ClosedRange<Date> {
        switch state.mode {
        case .countdown(let countdown):
            return Date.now...countdown.fireDate
        default:
            return Date.now...Date.now
        }
    }
}

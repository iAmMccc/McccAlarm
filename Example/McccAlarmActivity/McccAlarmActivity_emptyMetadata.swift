//
//  McccAlarmActivity_emptyMetadata.swift
//  McccAlarm_Example
//
//  Created by qixin on 2025/10/24.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit
import AppIntents
import McccAlarm

struct McccAlarmActivity_EmptyMetadata: Widget {
    
    
    /// body属性 - Widget的核心配置
    var body: some WidgetConfiguration {
        
        /// 配置 Live Activity
        ///  - 配置锁屏页面的UI
        ///  - 配置灵动岛界面的UI
        ActivityConfiguration(for: AlarmAttributes<McccEmptyMetadata>.self) { context in
            
            /// 设置锁屏界面的UI
            ///  - context.attributes：闹钟的静态属性（标题、颜色、元数据等）
            ///  - context.state：闹钟的动态状态（倒计时进度、是否暂停等）
            lockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            /// 设置灵动岛界面的UI
            /// 显示模式 3种
            /// 1. 展开模式：用户长按灵动岛时显示的完整页面。
            /// 2. 紧凑模式：灵动岛正常显示时的样子。
            /// 3. 最小模式：当有多个Lvie Activity 时，灵动岛显示最小化。
            ///
            DynamicIsland {
                // 展开时的布局：左侧区域。 标题
                DynamicIslandExpandedRegion(.leading) {
                    alarmTitle(attributes: context.attributes, state: context.state)
                }
                
                // 展开时的布局：右侧区域。 图标
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundStyle(context.attributes.tintColor)
                }
                
                // 展开时的布局：底部区域。
                DynamicIslandExpandedRegion(.bottom) {
                    bottomView(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                // 紧凑状态左侧 - 显示倒计时
                countdown(state: context.state, maxWidth: 44)
                    .foregroundStyle(context.attributes.tintColor)
            } compactTrailing: {
                // 紧凑状态右侧 - 显示进度环
                ProgressView(
                    timerInterval: getCurrentFireDate(state: context.state),
                    countsDown: true,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: "timer")
                            .scaleEffect(0.8)
                    })
                .progressViewStyle(.circular)
                .foregroundStyle(context.attributes.tintColor)
            } minimal: {
                // 最小状态 - 只显示图标
//                Image(systemName: "timer")
//                    .foregroundStyle(context.attributes.tintColor)
                // 紧凑状态右侧 - 显示进度环
                ProgressView(
                    timerInterval: getCurrentFireDate(state: context.state),
                    countsDown: true,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: "timer")
                            .scaleEffect(0.8)
                    })
                .progressViewStyle(.circular)
                .foregroundStyle(context.attributes.tintColor)
            }
            .keylineTint(context.attributes.tintColor)
        }
    }
    
    // MARK: - 锁屏界面
    func lockScreenView(attributes: AlarmAttributes<McccEmptyMetadata>, state: AlarmPresentationState) -> some View {
        VStack(spacing: 16) {
            // 标题
            alarmTitle(attributes: attributes, state: state)
            
            // 倒计时和按钮
            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, 16)
    }
    
    // MARK: - 底部视图
    func bottomView(attributes: AlarmAttributes<McccEmptyMetadata>, state: AlarmPresentationState) -> some View {
        HStack {
            // 倒计时
            countdown(state: state, maxWidth: 150)
                .font(.system(size: 40, design: .rounded))
            
            Spacer()
            
            // 控制按钮
            AlarmControls(presentation: attributes.presentation, state: state, tintColor: attributes.tintColor)
        }
    }
    
    // MARK: - 倒计时显示
    func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
        Group {
            switch state.mode {
            case .alert:
                // ⭐ Alert 状态：显示 "时间到" 或类似文本
                Text("⏰")
                    .font(.system(size: 40))
            case .countdown(let countdown):
                Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
            case .paused(let pausedState):
                let remaining = Duration.seconds(
                    pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration)
                let pattern: Duration.TimeFormatStyle.Pattern =
                    remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                Text(remaining.formatted(.time(pattern: pattern)))
            @unknown default:
                EmptyView()
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: maxWidth, alignment: .leading)
    }
    
    // MARK: - 标题
    @ViewBuilder func alarmTitle(
        attributes: AlarmAttributes<McccEmptyMetadata>,
        state: AlarmPresentationState
    ) -> some View {
        let title: LocalizedStringResource? =
            switch state.mode {
            case .alert:
                attributes.presentation.alert.title              // ⭐ 添加 alert 状态
            case .countdown:
                attributes.presentation.countdown?.title
            case .paused:
                attributes.presentation.paused?.title
            @unknown default:
                nil
            }
        
        Text(title ?? "")
            .font(.title2)
            .fontWeight(.semibold)
            .lineLimit(1)
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



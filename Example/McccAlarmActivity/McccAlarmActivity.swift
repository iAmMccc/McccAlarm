//
//  McccAlarmWidget.swift
//  McccAlarmWidget
//
//  简单的 AlarmKit Live Activity 实现
//

import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit

struct McccAlarmActivity: Widget {
    var body: some WidgetConfiguration {
        // 配置 Live Activity - 使用 SimpleMetadata
        ActivityConfiguration(for: AlarmAttributes<SimpleMetadata>.self) { context in
            // 锁屏界面
            lockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            // 灵动岛界面
            DynamicIsland {
                // 展开时的布局
                DynamicIslandExpandedRegion(.leading) {
                    alarmTitle(attributes: context.attributes, state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundStyle(context.attributes.tintColor)
                }
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
                Image(systemName: "timer")
                    .foregroundStyle(context.attributes.tintColor)
            }
            .keylineTint(context.attributes.tintColor)
        }
    }
    
    // MARK: - 锁屏界面
    func lockScreenView(attributes: AlarmAttributes<SimpleMetadata>, state: AlarmPresentationState) -> some View {
        VStack(spacing: 16) {
            // 标题
            alarmTitle(attributes: attributes, state: state)
            
            // 倒计时和按钮
            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, 16)
    }
    
    // MARK: - 底部视图
    func bottomView(attributes: AlarmAttributes<SimpleMetadata>, state: AlarmPresentationState) -> some View {
        HStack {
            // 倒计时
            countdown(state: state, maxWidth: 150)
                .font(.system(size: 40, design: .rounded))
            
            Spacer()
            
            // 控制按钮
            alarmControls(presentation: attributes.presentation, state: state)
        }
    }
    
    // MARK: - 倒计时显示
    func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
        Group {
            switch state.mode {
            case .countdown(let countdown):
                Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
            case .paused(let pausedState):
                let remaining = Duration.seconds(
                    pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration)
                let pattern: Duration.TimeFormatStyle.Pattern =
                    remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                Text(remaining.formatted(.time(pattern: pattern)))
            default:
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
        attributes: AlarmAttributes<SimpleMetadata>, 
        state: AlarmPresentationState
    ) -> some View {
        let title: LocalizedStringResource? =
            switch state.mode {
            case .countdown:
                attributes.presentation.countdown?.title
            case .paused:
                attributes.presentation.paused?.title
            default:
                nil
            }
        
        Text(title ?? "")
            .font(.title2)
            .fontWeight(.semibold)
            .lineLimit(1)
    }
    
    // MARK: - 控制按钮
    @ViewBuilder func alarmControls(
        presentation: AlarmPresentation, 
        state: AlarmPresentationState
    ) -> some View {
        HStack(spacing: 8) {
            switch state.mode {
            case .countdown:
                if let pauseButton = presentation.countdown?.pauseButton {
                    Button(pauseButton.text.toString()) {
                        // 系统自动处理
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .frame(width: 80, height: 32)
                }
            case .paused:
                if let resumeButton = presentation.paused?.resumeButton {
                    Button(resumeButton.text.toString()) {
                        // 系统自动处理
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .frame(width: 80, height: 32)
                }
            default:
                EmptyView()
            }
        }
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

// MARK: - LocalizedStringResource 扩展
extension LocalizedStringResource {
    func toString() -> String {
        String(localized: self)
    }
}



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
import AppIntents
import McccAlarm

struct McccAlarmActivity: Widget {
    
    
    /// body属性 - Widget的核心配置
    var body: some WidgetConfiguration {
        
        /// 配置 Live Activity
        ///  - 配置锁屏页面的UI
        ///  - 配置灵动岛界面的UI
        ActivityConfiguration(for: AlarmAttributes<McccAlarmMetadata>.self) { context in
            
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
                DynamicIslandExpandedRegion(.center) {
                    expandedRegionView(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                // 紧凑状态左侧 - 显示倒计时
                countdownView(attributes: context.attributes, state: context.state, style: .compact)
                    .padding(.leading, 5)
            } compactTrailing: {
                // 紧凑状态右侧 - 显示进度环
                countdownProgressView(attributes: context.attributes, state: context.state)
                    .padding(.trailing, 1)
            } minimal: {
                // 最小状态 - 显示进度环
                countdownProgressView(attributes: context.attributes, state: context.state)
            }
            .keylineTint(context.attributes.tintColor)
        }
    }
}


extension McccAlarmActivity {
    // MARK: - 锁屏界面
    func lockScreenView(attributes: AlarmAttributes<McccAlarmMetadata>, state: AlarmPresentationState) -> some View {
        VStack(spacing: 16) {
            // 顶部：Title + Subtitle
            HStack {
                alarmTitle(attributes: attributes, state: state)
                    .font(.title3)
                    .foregroundStyle(attributes.tintColor)
                    .fontWeight(.semibold)
                    .layoutPriority(2)
                
                Spacer(minLength: 4) // 最小间距 4
                
                Text(attributes.metadata?.subTitle ?? "")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            bottomView(attributes: attributes, state: state, style: .lockScreen)
        }
        .padding(EdgeInsets(top: 30, leading: 30, bottom: 20, trailing: 30))
        .frame(height: 140) // 可根据需求调整整体高度
        .foregroundStyle(.red)
    }
}




extension McccAlarmActivity {
    
    enum CountdownStyle {
        case lockScreen
        case expanded
        case compact
    }
    
    @ViewBuilder
    func countdownView(
        attributes: AlarmAttributes<McccAlarmMetadata>,
        state: AlarmPresentationState,
        style: CountdownStyle
    ) -> some View {
        // 字体/布局参数
        let (fontSize, alignment, maxWidth): (CGFloat, Alignment, CGFloat) = {
            switch style {
            case .lockScreen:
                return (72, .leading, 150)
            case .expanded:
                return (56, .leading, 150)
            case .compact:
                return (20, .center, 44)
            }
        }()
        
        // 主体视图（确保所有分支都有 View 返回）
        Group {
            switch state.mode {
            case .countdown(let countdown):
                // 运行中：用 timerInterval 的 Text（会自动倒计时）
                Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
                    .font(.system(size: fontSize, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(attributes.tintColor)
                    .frame(maxWidth: maxWidth, alignment: alignment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
            case .paused(let pausedState):
                // 暂停：计算剩余并用静态文本显示，带一个小的暂停图标
                let remaining = Duration.seconds(
                    pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
                )
                let pattern: Duration.TimeFormatStyle.Pattern =
                    remaining > .seconds(3600) ? .hourMinuteSecond : .minuteSecond
                
                Text(remaining.formatted(.time(pattern: pattern)))
                    .font(.system(size: fontSize, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(attributes.tintColor.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
            case .alert:
                alarmTitle(attributes: attributes, state: state, fontSize: 26)

                
            @unknown default:
                // 保底分支，避免返回 Void
                EmptyView()
                    .frame(maxWidth: maxWidth, alignment: alignment)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: state.mode)
    }
}


extension McccAlarmActivity {
    @ViewBuilder
    func expandedRegionView(
        attributes: AlarmAttributes<McccAlarmMetadata>,
        state: AlarmPresentationState
    ) -> some View {
        VStack(spacing: 12) {
            // 顶部标题 + 副标题
            HStack(spacing: 6) {
                alarmTitle(attributes: attributes, state: state)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(attributes.tintColor)
                    .lineLimit(1)
                    .layoutPriority(2) // 优先显示title
                
                // 使用 Text + truncationMode 控制副标题截断
                if let subTitle = attributes.metadata?.subTitle, !subTitle.isEmpty {
                    Text(subTitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1) // 空间不足时优先被截断
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 底部控制/倒计时区域
            bottomView(attributes: attributes, state: state, style: .expanded)
    
        }
        .padding(.horizontal, 12)
    }

    // MARK: - 底部视图
    func bottomView(attributes: AlarmAttributes<McccAlarmMetadata>, state: AlarmPresentationState, style: CountdownStyle) -> some View {
        HStack {
            countdownView(attributes: attributes, state: state, style: style)
            
            Spacer()
            
            AlarmControls(
                presentation: attributes.presentation,
                state: state,
                tintColor: attributes.tintColor
            )
        }
    }
}

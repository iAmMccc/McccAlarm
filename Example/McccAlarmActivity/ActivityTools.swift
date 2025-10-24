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
struct AlarmControls: View {
    var presentation: AlarmPresentation
    var state: AlarmPresentationState
    
    var body: some View {
        HStack(spacing: 4) {
            switch state.mode {
            case .countdown:
                ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            case .paused:
                ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            default:
                EmptyView()
            }

            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: .red)
        }
    }
}

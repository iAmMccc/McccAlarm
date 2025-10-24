//
//  McccAlarmActivityBundle.swift
//  McccAlarmActivity
//
//  Created by qixin on 2025/10/17.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import WidgetKit
import SwiftUI
import AlarmKit
import McccAlarm
import AppIntents

@main
struct McccAlarmActivityBundle: WidgetBundle {
    var body: some Widget {
        McccAlarmActivity()
        McccAlarmActivity_EmptyMetadata()
        
    
        let v: AlarmControls?
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
            Label(config.text, systemImage: config.systemImageName)
                .lineLimit(1)
        }
        .tint(tint)
        .buttonStyle(.borderedProminent)
        .frame(width: 96, height: 30)
    }
}

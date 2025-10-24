//
//  AlarmPresentation+Extension.swift
//  McccAlarm
//
//  Created by qixin on 2025/10/24.
//

import Foundation
import AlarmKit


public extension AlarmPresentation.Alert {
    static func alert(title: LocalizedStringResource, needRepeat: Bool = true) -> AlarmPresentation.Alert {
        return AlarmPresentation.Alert(
            title: title,
            stopButton: .stopButton,
            secondaryButton: needRepeat ? .repeatButton : nil,
            secondaryButtonBehavior: needRepeat ? .countdown : nil
        )
    }
}


public extension AlarmPresentation.Countdown {

    static func countDown(title: LocalizedStringResource) -> AlarmPresentation.Countdown {
        return AlarmPresentation.Countdown(title: title, pauseButton: .pauseButton)
    }
}


public extension AlarmPresentation.Paused {
    static func paused(title: LocalizedStringResource) -> AlarmPresentation.Paused {
        return AlarmPresentation.Paused(title: title, resumeButton: .resumeButton)
    }
}

//
//  ViewController+Test.swift
//  McccNotify_Example
//
//  Created by qixin on 2025/7/8.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import AlarmKit
import SwiftUI
import McccAlarm

extension ViewController {
    var alarm_test: [String: Any] {
        [
            "title": "基础测试",
            "list": [
                ["name": "设置一个普通闹钟"],
            ]
        ]
    }
    
    
    func didSelectSection0(atRow row: Int) {
        let vc = McccSystemAlarmViewController(title: "闹钟所发生的水电费水电费SSD收费水电费手段", time: Date.now, alarmId: "123")
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false)
    }
    
}

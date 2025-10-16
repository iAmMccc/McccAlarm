//
//  ViewController+Countdown.swift
//  McccAlarmKit_Example
//
//  Created by qixin on 2025/10/15.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import AlarmKit
import SwiftUI
import ActivityKit


extension ViewController {
    var alarm_countdowm: [String: Any] {
        [
            "title": "倒计时",
            "list": [
                ["name": "方法1: 使用 countdownDuration (当前方式)"],
                ["name": "方法2: 使用绝对时间 Time (测试)"],
                ["name": "方法3: 反转 preAlert/postAlert 参数"],
                ["name": "查看当前所有闹钟详情"],
            ]
        ]
    }
    
    func didSelectSection2(atRow row: Int) {
       
    }
    
    
}

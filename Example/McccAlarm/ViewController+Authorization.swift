//
//  ViewController+Content.swift
//  McccNotify_Example
//
//  Created by qixin on 2025/7/8.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import McccAlarm
extension ViewController {
    var alarm_authorization: [String: Any] {
        [
            "title": "权限测试",
            "list": [
                ["name": "请求闹钟权限"]
            ]
        ]
    }
    
    
    func didSelectSection1(atRow row: Int) {
        switch row {
        case 0:
            break
            
        case 1:
            break
            
        case 2:
            break
            
        case 3:
            break
            
        default:
            break
        }
    }
}

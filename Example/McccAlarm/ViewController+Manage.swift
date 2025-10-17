//
//  ViewController+Manage.swift
//  McccAlarm_Example
//
//  Created by qixin on 2025/10/17.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import AlarmKit

extension ViewController {
    var alarm_manage: [String: Any] {
        [
            "title": "管理闹钟",
            "list": [
                ["name": "查询当前所有闹钟"],
                ["name": "删除当前所有闹钟"],
            ]
        ]
    }
    
    
    func didSelectSection2(atRow row: Int) {
        switch row {
        case 0:
            
            do {
                let alarms = try AlarmManager.shared.alarms
                print("=============")
                print("查询到的闹钟alarms = \(alarms)")
                print("=============")
                
            } catch {
                print("error = \(error)")
            }
            
        case 1:
            
            do {
                let alarms = try AlarmManager.shared.alarms
                
                for alarm in alarms {
                    try AlarmManager.shared.cancel(id: alarm.id)
                }
            } catch {
                print("error = \(error)")
            }
            
            
        case 2:
            break
            
        case 3:
            break
            
        default:
            break
        }
    }
    
}


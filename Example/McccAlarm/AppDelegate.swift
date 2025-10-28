//
//  AppDelegate.swift
//  McccAlarm
//
//  Created by iAmMccc on 10/16/2025.
//  Copyright (c) 2025 iAmMccc. All rights reserved.
//

import UIKit
import AlarmKit
import McccAlarm

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        alarmAlertMonitor()
        return true
    }
}



extension AppDelegate {
    func alarmAlertMonitor() {
        Task {
            for await alarms in AlarmManager.shared.alarmUpdates {
                if let alarm = alarms.first(where: { $0.state == .alerting }) {
                    await MainActor.run {
                        let topVC = UIViewController.mc_current
                        
                        // 避免重复弹出
                        guard !(topVC.presentedViewController is McccSystemAlarmViewController) else {
                            return
                        }
                        
                        let alarmTitle = "闹钟响铃中"

                        let vc = McccSystemAlarmViewController(
                            title: alarmTitle,
                            time: Date.now,
                            alarmId: alarm.id.uuidString
                        )
                        vc.modalPresentationStyle = .fullScreen
                        topVC.present(vc, animated: false)
                    }
                }
            }
        }
    }
}



import UIKit

extension UIViewController {
    /// 获取当前正在显示的顶层控制器
    static var mc_current: UIViewController {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else {
            fatalError("未找到根控制器")
        }
        return topViewController(from: root)
    }
    
    /// 递归找到最顶层控制器
    private static func topViewController(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = vc as? UINavigationController {
            return topViewController(from: nav.visibleViewController ?? nav)
        }
        if let tab = vc as? UITabBarController {
            return topViewController(from: tab.selectedViewController ?? tab)
        }
        return vc
    }
}

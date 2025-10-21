//
//  ViewController.swift
//  McccAlarmKit
//
//  Created by iAmMccc on 10/15/2025.
//  Copyright (c) 2025 iAmMccc. All rights reserved.
//

import UIKit
import McccAlarm


/**
 1. 倒计时
 2. 重复
 3. 管理闹钟
 4. 如何设置alert状态的UI
 5. 如何设置多个不同的倒计时UI 和 多个不同的响铃UI？
 
 */


class ViewController: UIViewController {
    
    
    var dataArray: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Alarm详解"

        dataArray = [
            alarm_test,
            alarm_authorization,
            alarm_manage,
            alarm_countdowm,
            alarm_alarm
        ]
        
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.reloadData()
        
        // 在 App 启动时设置监听
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenAlarmAppIntentPerformed"),
            object: nil,
            queue: .main
        ) { notification in
            if let alarmID = notification.userInfo?["alarmID"] as? String {
                print("OpenAlarmAppIntent 被点击，alarmID: \(alarmID)")
                // 执行你的特定操作
                self.handleOpenAppIntent(alarmID: alarmID)
            }
        }
        
    }
    
    lazy var tableView = UITableView.make(registerCells: [UITableViewCell.self], delegate: self, style: .grouped)
   
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

        
        /**
         case notDetermined = 0

         case denied = 1

         case authorized = 2

         @available(iOS 12.0, *)
         case provisional = 3

         @available(iOS 14.0, *)
         case ephemeral = 4
         
         */
        
    }
}


extension ViewController {
    private func handleOpenAppIntent(alarmID: String) {
        // 这里执行你的特定操作
        print("处理 OpenAlarmAppIntent，alarmID: \(alarmID)")
        
        DispatchQueue.main.async {
            
            
            // 创建 UIAlertController
            let alertController = UIAlertController(
                title: "闹钟应用已打开",
                message: "",
                preferredStyle: .alert
            )
            
            // 添加确定按钮
            let okAction = UIAlertAction(title: "确定", style: .default) { _ in
                // 点击确定后的操作
                print("用户确认了提示")
            }
            alertController.addAction(okAction)
            
            // 显示 Alert
            self.present(alertController, animated: true, completion: nil)
        }
    }
}



extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let dict = dataArray[section~] {
            let list = dict["list"] as? [[String: String]] ?? []
            return list.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        if let dict = dataArray[section~] {
            let title = dict["title"] as? String ?? ""
            label.text = "    " + title
        }
        
        return label
    }

    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.makeCell(indexPath: indexPath)
        
        if let dict = dataArray[indexPath.section~] {

            let list = dict["list"] as? [[String: String]] ?? []
            
            let inDict = list[indexPath.row~] ?? [:]
            cell.textLabel?.text = inDict["name"] ?? ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                
        switch indexPath.section {
        case 0:
            didSelectSection0(atRow: indexPath.row)
        case 1:
            didSelectSection1(atRow: indexPath.row)
        case 2:
            didSelectSection2(atRow: indexPath.row)
        case 3:
            didSelectSection3(atRow: indexPath.row)
        case 4:
            didSelectSection4(atRow: indexPath.row)
//        case 5:
//            didSelectSection5(atRow: indexPath.row)
//        case 6:
//            didSelectSection6(atRow: indexPath.row)
//        case 7:
//            didSelectSection7(atRow: indexPath.row)
            // ...
        default:
            break
        }
        
    }
    
}

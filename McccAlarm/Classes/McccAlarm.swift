
import Foundation
import AlarmKit



/** Todo List
 * 1. 做一个通用的App内的响铃页面。 支持配置。
 * 2. 闹钟封装
 * 2.1 某日某时刻的具体时间。
 * 2.2 倒计时闹钟
 * 2.3 重复闹钟
 */

@available(iOS 26.0, *)
public struct McccAlarm {
    public static let shared = McccAlarm()
    
    let alarmManager = AlarmManager.shared
}





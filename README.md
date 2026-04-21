# McccAlarm

iOS AlarmKit 封装库，提供闹钟授权、调度、UI 展示，以及节假日感知的智能调度策略引擎。

## 功能

- **AlarmKit 封装**：授权、调度、停止、小睡，统一 API
- **闹钟响铃页面**：内置全屏响铃 UI，支持停止/重复按钮，文本可配置
- **节假日调度引擎**：支持多种重复周期 × 调度策略的组合
- **系统日历读取**：自动从系统日历获取法定节假日和补班日数据
- **灵活配置**：时区、周末定义、过滤规则、按钮文本均可自定义

## 要求

- iOS 16.0+（节假日调度引擎和日历读取）
- iOS 26.0+（AlarmKit 相关功能）
- Swift 5.9+

## 安装

### CocoaPods

```ruby
pod 'McccAlarm'
```

### Swift Package Manager

```swift
.package(url: "https://github.com/iAmMccc/McccAlarm.git", from: "0.2.0")
```

## 使用

### 1. 授权

```swift
import McccAlarm

if #available(iOS 26, *) {
    let granted = await McccAlarm.shared.requestAuthorization()
}
```

### 2. 闹钟响铃页面

```swift
let vc = McccSystemAlarmViewController(
    title: "起床闹钟",
    time: Date.now,
    alarmId: uuid.uuidString
)
vc.delegate = self
vc.soundName = "alarm.m4r"
present(vc, animated: false)
```

### 3. 按钮文本配置

默认中文，可在 App 启动时修改：

```swift
McccAlarm.ButtonText.stop = "Stop"
McccAlarm.ButtonText.repeat = "Repeat"
McccAlarm.ButtonText.sleep = "Snooze"
McccAlarm.ButtonText.pause = "Pause"
McccAlarm.ButtonText.resume = "Resume"
McccAlarm.ButtonText.openApp = "Open"
```

### 4. 节假日调度引擎

#### 4.1 实现 HolidayProvider 协议

```swift
class MyHolidayProvider: HolidayProvider {
    // 判断是否法定假日
    func isHoliday(_ date: Date) -> Bool {
        holidayDates.contains(dateKey(date))
    }

    // 判断是否补班日
    func isWorkday(_ date: Date) -> Bool {
        workdayDates.contains(dateKey(date))
    }

    // 可选：覆盖时区（默认 Asia/Shanghai）
    var timeZone: TimeZone { TimeZone(identifier: "Asia/Shanghai")! }
}
```

#### 4.2 注册 Provider

```swift
McccAlarm.registerHolidayProvider(MyHolidayProvider())
```

#### 4.3 重复周期（RepeatInterval）

```swift
typealias Weekday = HolidaySchedulePolicy.Weekday
typealias Interval = HolidaySchedulePolicy.RepeatInterval

// 每天
Interval.everyNDays(1)

// 每 3 天
Interval.everyNDays(3)

// 每周一三五
Interval.weekly([.monday, .wednesday, .friday])

// 工作日
Interval.weekly(Weekday.weekdays)

// 每月 21 号
Interval.monthly(day: 21, everyN: 1)

// 每 2 月 15 号
Interval.monthly(day: 15, everyN: 2)

// 每年 10 月 1 日
Interval.yearly(month: 10, day: 1, everyN: 1)

// 每隔 2 年 3 月 8 日
Interval.yearly(month: 3, day: 8, everyN: 2)
```

#### 4.4 调度策略（ScheduleStrategy）

| 策略 | 说明 |
|------|------|
| `.none` | 不过滤，到了就响 |
| `.workdayOnly` | 仅工作日响（含补班日），法定假日和周末不响 |
| `.restdayOnly` | 仅休息日响（含法定假日），补班日和工作日不响 |

#### 4.5 计算下一个有效日期

```swift
// 每周工作日 + 仅工作日模式（含补班）
let fireDate = HolidaySchedulePolicy.nextValidFireDate(
    interval: .weekly(Weekday.weekdays),
    strategy: .workdayOnly,
    hour: 8,
    minute: 0,
    holidayProvider: myProvider
)

// 每天 + 不过滤
let fireDate = HolidaySchedulePolicy.nextValidFireDate(
    interval: .everyNDays(1),
    strategy: .none,
    hour: 9,
    minute: 30
)

// 批量获取未来 5 个有效日期
let dates = HolidaySchedulePolicy.nextValidFireDates(
    count: 5,
    interval: .weekly(Weekday.weekdays),
    strategy: .workdayOnly,
    hour: 8,
    minute: 0,
    holidayProvider: myProvider
)
```

### 5. 从系统日历获取节假日

```swift
if #available(iOS 17, *) {
    let fetcher = CalendarHolidayFetcher.shared

    // 请求日历权限
    let granted = await fetcher.requestAccess()

    // 获取未来一年的节假日和补班日
    let result = fetcher.fetchHolidaysAndWorkdays(
        from: Date(),
        to: Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    )

    print("法定假日: \(result.holidays.count) 个")
    print("补班日: \(result.workdays.count) 个")
}
```

#### 自定义过滤规则

默认使用中国大陆规则（`休`/`班` 关键词）。其他地区可自定义：

```swift
let rule = CalendarFilterRule(
    holidayKeyword: "祝",
    workdayKeyword: "出勤",
    fallbackCalendarNames: ["Japanese Holidays"]
)

let result = fetcher.fetchHolidaysAndWorkdays(
    from: start,
    to: end,
    calendarName: "日本の祝日",
    rule: rule,
    timeZone: TimeZone(identifier: "Asia/Tokyo")!
)
```

### 6. 周末定义

默认周六周日。部分地区可修改：

```swift
// 中东：周五周六为周末
HolidaySchedulePolicy.weekendDays = [.friday, .saturday]
```

### 7. 日志

DEBUG 模式默认开启，RELEASE 默认关闭。可手动控制：

```swift
McccAlarmLog.isEnabled = true   // 强制开启
McccAlarmLog.isEnabled = false  // 强制关闭
```

日志格式：

```
🔔 [McccAlarm] AppDelegate.swift:38 | HolidayProvider 已注册
📅 [Holiday]   HolidaySchedulePolicy.swift:74 | ✅ 2026-04-21 | 搜索了 1 天
⏰ [Schedule]  AlarmManager+Normal.swift:92 | Normal 闹钟(起床) 节假日模式 → fixed(...)
❌ [McccAlarm] ... | 错误信息
```

## 架构

```
McccAlarm
├── McccAlarm.swift                    // 主入口，单例
├── McccAlarm+Authorization.swift      // 闹钟授权
├── McccAlarm+Holiday.swift            // 节假日 Provider 注册 + 调度 API
├── McccAlarmMetaData.swift            // 闹钟元数据
├── McccAlarmLog.swift                 // 日志工具
├── AlarmButton+Extension.swift        // 按钮预设 + ButtonText 配置
├── AlarmPresentation+Extension.swift  // 展示状态工厂方法
├── McccSystemAlarmViewController.swift// 内置响铃页面
├── HolidayProvider.swift              // 节假日协议 + 日历过滤规则 + CalendarHolidayFetcher
└── HolidaySchedulePolicy.swift        // 调度引擎（Weekday + RepeatInterval + ScheduleStrategy）
```

## License

McccAlarm is available under the MIT license. See the LICENSE file for more info.

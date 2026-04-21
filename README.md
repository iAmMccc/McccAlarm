# McccAlarm

iOS AlarmKit 封装库，提供闹钟授权、调度、UI 展示，以及节假日感知的智能调度策略引擎。

## 调度流程

### 什么时候需要这套机制？

并非所有闹钟都需要预调度引擎。根据闹钟类型选择合适的方式：

| 闹钟类型 | 调度方式 | 说明 |
|---------|---------|------|
| **一次性闹钟** | `Schedule.fixed(date)` | 直接用 AlarmKit 原生，响完即止 |
| **重复闹钟，不避开节假日** | `Schedule.relative(repeats:)` | 直接用 AlarmKit 原生，系统自动重复 |
| **重复闹钟，避开节假日** | **本库的预调度引擎** | 系统不支持「跳过某些日期」，必须用本库 |

前两种场景 AlarmKit 原生已完美支持，无需本库介入。**只有第三种——需要跳过节假日/补班日的重复闹钟——才需要以下机制。**

### 问题背景

假设用户设置了一个闹钟：**每天早上 8:00 起床，仅工作日响铃（避开节假日，补班日要响）**。

AlarmKit 的 `Schedule.relative(repeats:)` 只能按固定星期重复，无法跳过特定日期。所以必须用一次性的 `Schedule.fixed(date)` 逐个调度，并在触发后安排下一次。

但如果只调度 1 个触发器，一旦 App 被杀死且 StopIntent 也未能执行，下一次闹钟就丢了。

**解决方案：首次创建时预调度 N 个触发器（默认 3 个），触发后补充差额，始终保持 N 个 pending。即使连续 N-1 天 StopIntent 都失败，闹钟也不会丢失。**

### 工作流

```
第一步：创建闹钟 → 预调度 N 个

  用户设置「每天 8:00，仅工作日」→ scheduleWithStrategy()
  计算未来 3 个有效日期 → 批量调度：
      ┌──────────────────────────────────┐
      │  A(周二 8:00)  ← 最近的一个        │
      │  B(周三 8:00)  ← 第二个           │
      │  C(周四 8:00)  ← 第三个           │
      └──────────────────────────────────┘
  每个触发器有独立 UUID，业务信息（alarmId 等）存在 metadata 中。
  3 个触发器互不依赖，任何一个都能独立响铃。


第二步：A 触发 → 根据 App 状态补充

  周二 8:00，A 触发响铃，用户点击停止。
  此时 pending 还剩 B、C = 2 个，需要补 1 个。

  补充通过两条路径触发：

  ● 主路径：StopIntent（覆盖 App 在前台 / 后台 / 被杀死）
    用户点击停止 → 系统执行 StopIntent（LiveActivityIntent）
      → 无论 App 是否活跃，都在 Extension 进程中执行
      → 从 App Group 共享存储读取闹钟信息
      → 调用 replenish() 补充差额

  ● 兜底路径：App 冷启动 / 进前台
    覆盖 StopIntent 未能执行的极端情况（如系统资源不足）
    AppDelegate → ensureAlarmsScheduled()
      → 遍历所有闹钟 → replenish()


第三步：计算补充数量

  replenish() 执行：
      ├── 查询该 alarmId 的 pending 数量 = 2（B、C）
      ├── 差额 = 目标(3) - pending(2) = 1
      └── 从 C(周四) 之后开始计算
          → 找到 D(周五 8:00)


第四步：实施补充

  AlarmScheduler.schedule()：
      ├── 为 D 生成随机 UUID
      ├── 构建配置（业务信息写入 metadata）
      └── 调度到 AlarmKit

  结果：B(周三) C(周四) D(周五) — 始终保持 3 个 pending
```

### 场景推演

```
正常流程（每天触发）：
  初始：A(周一) B(周二) C(周三)
  周一 A 触发 → 补 D(周四) → pending: B C D
  周二 B 触发 → 补 E(周五) → pending: C D E
  周三 C 触发 → 补 F(下周一) → pending: D E F
  ...永远保持 3 个

遇到节假日（五一放假 5/1~5/4）：
  初始：A(4/30) B(5/5) C(5/6)  ← 5/1~5/4 被自动跳过
  4/30 A 触发 → 补 D(5/7) → pending: B C D

StopIntent 失败（App 被杀死 + Extension 未执行）：
  初始：A(周一) B(周二) C(周三)
  周一 A 触发 → StopIntent 失败 → 无补充
  周二 B 触发 → StopIntent 成功 → pending: C = 1 个
    → 补 2 个: D(周四) E(周五) → pending: C D E
  闹钟不会丢失，最多延迟补充

极端情况（连续 3 天 StopIntent 都失败）：
  A B C 全部触发且全失败 → pending = 0
  下次 App 打开 → ensureAlarmsScheduled → replenish
  → 从头计算 3 个 → 恢复正常
```

### 设计原则

| 原则 | 说明 |
|------|------|
| **不取消 sibling** | 触发后只补差额，永远不主动取消已有的有效触发器 |
| **幂等补充** | 多次调用 replenish 结果一致，不会重复调度 |
| **UUID 随机** | 不在 UUID 中编码业务信息，业务信息全部存 metadata |
| **多重保险** | StopIntent（主）+ App 进前台（兜底）+ 冷启动（二次兜底）|

---

## 快速接入（节假日闹钟）

以下是让节假日闹钟跑通的最小步骤：

### Step 1：配置 App Group

主 App 和 Extension 都需要开启同一个 App Group，用于共享节假日数据。

- Xcode → Target → Signing & Capabilities → + Capability → App Groups
- 两个 target 添加同一个 Group ID（如 `group.yourapp.alarm`）

### Step 2：实现 HolidayProvider

```swift
class MyHolidayProvider: HolidayProvider {
    private var holidaySet: Set<String> = []
    private var workdaySet: Set<String> = []
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return f
    }()

    func isHoliday(_ date: Date) -> Bool {
        holidaySet.contains(formatter.string(from: date))
    }

    func isWorkday(_ date: Date) -> Bool {
        workdaySet.contains(formatter.string(from: date))
    }

    /// 加载数据（从 API / 系统日历 / 本地缓存）
    func load() {
        let result = CalendarHolidayFetcher.shared.fetchHolidaysAndWorkdays(
            from: Date(),
            to: Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        )
        holidaySet = Set(result.holidays.map { formatter.string(from: $0) })
        workdaySet = Set(result.workdays.map { formatter.string(from: $0) })

        // 同步写入 App Group，供 Extension 读取
        let defaults = UserDefaults(suiteName: "group.yourapp.alarm")
        defaults?.set(Array(holidaySet), forKey: "holidays")
        defaults?.set(Array(workdaySet), forKey: "workdays")
    }
}
```

### Step 3：App 启动时注册

```swift
// AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) {
    if #available(iOS 26, *) {
        let provider = MyHolidayProvider()
        McccAlarm.registerHolidayProvider(provider)

        Task {
            let granted = await CalendarHolidayFetcher.shared.requestAccess()
            if granted { provider.load() }
        }
    }
}
```

### Step 4：创建闹钟时调度

```swift
await McccAlarm.scheduleWithStrategy(
    alarmId: alarm.id,
    interval: .weekly(Weekday.weekdays),
    strategy: .workdayOnly,
    hour: 8, minute: 0
) { uuid, fireDate, allFireDates in
    let metadata = McccAlarmMetadata(
        title: "起床", subTitle: "工作日闹钟",
        alarmId: alarm.id, fireDate: fireDate,
        siblingFireDates: allFireDates
    )
    let presentation = AlarmPresentation(alert: alertContent, countdown: nil, paused: nil)
    let attributes = AlarmAttributes(presentation: presentation, metadata: metadata, tintColor: .orange)
    return AlarmManager.AlarmConfiguration(
        schedule: .fixed(fireDate),
        attributes: attributes,
        stopIntent: MyStopIntent(alarmID: uuid.uuidString)
    )
}
```

### Step 5：StopIntent 中补充调度

```swift
// AppIntents.swift（Extension target 也能访问）
struct MyStopIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }
        try AlarmManager.shared.stop(id: uuid)

        // 从 App Group 读取节假日数据，构建轻量 Provider
        let defaults = UserDefaults(suiteName: "group.yourapp.alarm")
        let holidays = defaults?.stringArray(forKey: "holidays") ?? []
        let workdays = defaults?.stringArray(forKey: "workdays") ?? []
        let provider = SharedHolidayProvider(holidays: holidays, workdays: workdays)
        McccAlarm.registerHolidayProvider(provider)

        // 从 metadata 获取 alarmId（通过遍历 pending alarms）
        let pending = AlarmScheduler.pendingAlarms(forAlarmId: alarmId)
        // ... 读取 interval、strategy、hour、minute

        Task {
            await McccAlarm.replenish(
                alarmId: alarmId,
                interval: .weekly(Weekday.weekdays),
                strategy: .workdayOnly,
                hour: 8, minute: 0
            ) { uuid, fireDate, allFireDates in
                // 构建配置（同 Step 4）
            }
        }

        return .result()
    }
}
```

### Step 6：冷启动兜底

```swift
// AppDelegate.swift — setupHolidayProvider() 中数据加载完成后
McccAlarm.ensureAlarmsScheduled {
    for alarm in myAlarms where alarm.exceptHolidays {
        Task {
            await McccAlarm.replenish(
                alarmId: alarm.id,
                interval: alarm.repeatInterval,
                strategy: alarm.strategy,
                hour: alarm.hour, minute: alarm.minute
            ) { uuid, fireDate, allFireDates in
                // 构建配置
            }
        }
    }
}
```

### 完成

以上 6 步跑通后，节假日闹钟就能正常工作了：
- 创建时预调度 3 个触发器
- 每次触发后自动补充
- App 被杀死也不丢闹钟
- 冷启动自动兜底

---

## 功能

- **AlarmKit 封装**：授权、调度、停止、小睡，统一 API
- **闹钟响铃页面**：内置全屏响铃 UI，支持停止/重复按钮，文本可配置
- **节假日调度引擎**：支持多种重复周期 × 调度策略的组合
- **批量调度管理**：预调度 N 个触发器，触发后自动补充，防止链条断裂
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

### 2. 节假日调度

#### 2.1 实现 HolidayProvider

```swift
class MyHolidayProvider: HolidayProvider {
    func isHoliday(_ date: Date) -> Bool {
        holidayDates.contains(dateKey(date))
    }

    func isWorkday(_ date: Date) -> Bool {
        workdayDates.contains(dateKey(date))
    }

    // 可选：覆盖时区（默认 Asia/Shanghai）
    var timeZone: TimeZone { TimeZone(identifier: "Asia/Shanghai")! }
}
```

#### 2.2 注册 Provider（App 启动时）

```swift
McccAlarm.registerHolidayProvider(MyHolidayProvider())
```

#### 2.3 创建闹钟 — 首次调度

```swift
let results = await McccAlarm.scheduleWithStrategy(
    alarmId: "1713687600.123",
    interval: .weekly(Weekday.weekdays),
    strategy: .workdayOnly,
    hour: 8,
    minute: 0
) { uuid, fireDate, allFireDates in
    // 构建 AlarmKit 配置，业务信息写入 metadata
    let metadata = McccAlarmMetadata(
        title: "起床",
        subTitle: "工作日闹钟",
        alarmId: "1713687600.123",
        fireDate: fireDate,
        siblingFireDates: allFireDates
    )
    let attributes = AlarmAttributes(
        presentation: presentation,
        metadata: metadata,
        tintColor: .orange
    )
    return AlarmManager.AlarmConfiguration(
        schedule: .fixed(fireDate),
        attributes: attributes,
        stopIntent: MyStopIntent(alarmID: uuid.uuidString)
    )
}
// results: [(uuid, fireDate)] — 成功调度的触发器列表
```

#### 2.4 闹钟触发后 — 补充调度

```swift
// 在 StopIntent 或 AppDelegate 中调用
let newResults = await McccAlarm.replenish(
    alarmId: "1713687600.123",
    interval: .weekly(Weekday.weekdays),
    strategy: .workdayOnly,
    hour: 8,
    minute: 0
) { uuid, fireDate, allFireDates in
    // 同上，构建配置
}
```

#### 2.5 App 进前台 / 冷启动 — 兜底检查

```swift
McccAlarm.ensureAlarmsScheduled {
    for alarm in myAlarms where alarm.needsHolidaySchedule {
        await McccAlarm.replenish(
            alarmId: alarm.id,
            interval: alarm.interval,
            strategy: alarm.strategy,
            hour: alarm.hour,
            minute: alarm.minute
        ) { uuid, fireDate, allFireDates in
            // 构建配置
        }
    }
}
```

### 3. 重复周期（RepeatInterval）

```swift
typealias Weekday = HolidaySchedulePolicy.Weekday
typealias Interval = HolidaySchedulePolicy.RepeatInterval

Interval.everyNDays(1)                               // 每天
Interval.everyNDays(3)                               // 每 3 天
Interval.weekly([.monday, .wednesday, .friday])      // 周一三五
Interval.weekly(Weekday.weekdays)                    // 工作日
Interval.monthly(day: 21, everyN: 1)                 // 每月 21 号
Interval.monthly(day: 15, everyN: 2)                 // 每 2 月 15 号
Interval.yearly(month: 10, day: 1, everyN: 1)        // 每年 10/1
Interval.yearly(month: 3, day: 8, everyN: 2)         // 每隔 2 年 3/8
```

### 4. 调度策略（ScheduleStrategy）

| 策略 | 普通工作日 | 普通周末 | 法定假日 | 补班日 |
|------|-----------|---------|---------|--------|
| `.none` | 按周期 | 按周期 | 按周期 | 按周期 |
| `.workdayOnly` | 响 | 不响 | 不响 | 响 |
| `.restdayOnly` | 不响 | 响 | 响 | 不响 |

### 5. 仅计算日期（不调度）

```swift
// 单个
let date = HolidaySchedulePolicy.nextValidFireDate(
    interval: .weekly(Weekday.weekdays),
    strategy: .workdayOnly,
    hour: 8, minute: 0,
    holidayProvider: myProvider
)

// 批量
let dates = HolidaySchedulePolicy.nextValidFireDates(
    count: 5,
    interval: .weekly(Weekday.weekdays),
    strategy: .workdayOnly,
    hour: 8, minute: 0,
    holidayProvider: myProvider
)
```

### 6. 从系统日历获取节假日

```swift
if #available(iOS 17, *) {
    let fetcher = CalendarHolidayFetcher.shared
    let granted = await fetcher.requestAccess()

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
    from: start, to: end,
    calendarName: "日本の祝日",
    rule: rule,
    timeZone: TimeZone(identifier: "Asia/Tokyo")!
)
```

### 7. 闹钟响铃页面

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

### 8. 按钮文本配置

默认中文，可在 App 启动时修改：

```swift
McccAlarm.ButtonText.stop = "Stop"
McccAlarm.ButtonText.repeat = "Repeat"
McccAlarm.ButtonText.sleep = "Snooze"
McccAlarm.ButtonText.pause = "Pause"
McccAlarm.ButtonText.resume = "Resume"
McccAlarm.ButtonText.openApp = "Open"
```

### 9. 周末定义

默认周六周日。部分地区可修改：

```swift
HolidaySchedulePolicy.weekendDays = [.friday, .saturday]
```

### 10. 日志

DEBUG 模式默认开启，RELEASE 默认关闭：

```swift
McccAlarmLog.isEnabled = true   // 强制开启
McccAlarmLog.isEnabled = false  // 强制关闭
```

```
🔔 [McccAlarm]  HolidayProvider 已注册
📅 [Holiday]    ✅ 2026-04-21 | 搜索了 1 天
⏰ [Schedule]   批量调度完成: 3/3 成功
⏰ [Schedule]   replenish: pending=2 目标=3 差额=1
❌ [McccAlarm]  错误信息
```

## 架构

```
McccAlarm
├── McccAlarm.swift                    // 主入口
├── McccAlarm+Authorization.swift      // 闹钟授权
├── McccAlarm+Holiday.swift            // 调度 API（scheduleWithStrategy / replenish）
├── McccAlarmMetaData.swift            // 元数据（alarmId / fireDate / siblingFireDates）
├── McccAlarmLog.swift                 // 日志
├── AlarmButton+Extension.swift        // 按钮预设 + ButtonText 配置
├── AlarmPresentation+Extension.swift  // 展示状态
├── McccSystemAlarmViewController.swift// 响铃页面
├── HolidayProvider.swift              // 节假日协议 + 日历过滤规则 + CalendarHolidayFetcher
├── HolidaySchedulePolicy.swift        // 日期计算（Weekday + RepeatInterval + ScheduleStrategy）
└── AlarmScheduler.swift               // 批量调度/取消（UUID 随机，metadata 存业务信息）
```

## License

McccAlarm is available under the MIT license. See the LICENSE file for more info.

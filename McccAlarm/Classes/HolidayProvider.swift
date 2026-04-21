
import Foundation
import EventKit

// MARK: - 节假日提供者协议

/// App 层实现此协议，注入节假日数据到 McccAlarm
public protocol HolidayProvider: AnyObject {
    /// 节假日所属时区（默认 Asia/Shanghai）
    var timeZone: TimeZone { get }

    /// 判断某一天是否为法定节假日（放假日）
    func isHoliday(_ date: Date) -> Bool

    /// 判断某一天是否为补班日（调休上班日，通常是周末）
    func isWorkday(_ date: Date) -> Bool
}

/// 默认实现
public extension HolidayProvider {
    var timeZone: TimeZone { TimeZone(identifier: "Asia/Shanghai")! }
    func isWorkday(_ date: Date) -> Bool { false }
}

// MARK: - 日历事件过滤规则

/// 定义如何从日历事件标题中识别节假日和补班日
public struct CalendarFilterRule {
    /// 节假日关键词（标题包含此关键词则视为法定假日）
    public let holidayKeyword: String
    /// 补班日关键词（标题包含此关键词则视为补班日）
    public let workdayKeyword: String
    /// 备选日历名称（主日历未找到时的 fallback 匹配列表）
    public let fallbackCalendarNames: [String]

    public init(holidayKeyword: String, workdayKeyword: String, fallbackCalendarNames: [String] = []) {
        self.holidayKeyword = holidayKeyword
        self.workdayKeyword = workdayKeyword
        self.fallbackCalendarNames = fallbackCalendarNames
    }

    /// 中国大陆规则
    public static let china = CalendarFilterRule(
        holidayKeyword: "休",
        workdayKeyword: "班",
        fallbackCalendarNames: ["Chinese Holidays", "中国节假日"]
    )
}

// MARK: - 系统日历节假日获取

/// 从系统日历 App 中读取节假日事件
@available(iOS 17.0, *)
public class CalendarHolidayFetcher {

    public static let shared = CalendarHolidayFetcher()

    private let eventStore: EKEventStore

    public init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    /// 请求日历访问权限
    public func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    /// 从系统日历中获取节假日和补班日
    /// - Parameters:
    ///   - start: 起始日期
    ///   - end: 结束日期
    ///   - calendarName: 日历名称
    ///   - rule: 过滤规则（决定如何从事件标题识别假日/补班）
    ///   - timeZone: 时区
    /// - Returns: (holidays: 法定假日, workdays: 补班日)
    public func fetchHolidaysAndWorkdays(
        from start: Date,
        to end: Date,
        calendarName: String = "中国大陆节假日",
        rule: CalendarFilterRule = .china,
        timeZone: TimeZone = TimeZone(identifier: "Asia/Shanghai")!
    ) -> (holidays: [Date], workdays: [Date]) {
        let calendars = eventStore.calendars(for: .event)

        McccAlarmLog.holiday("系统日历列表:")
        for cal in calendars {
            McccAlarmLog.holiday("  - \"\(cal.title)\" (type: \(cal.type.rawValue), source: \(cal.source?.title ?? "nil"))")
        }

        guard let holidayCalendar = calendars.first(where: {
            $0.title.contains(calendarName)
        }) else {
            McccAlarmLog.holiday("⚠️ 未找到名为「\(calendarName)」的日历")
            for fallbackName in rule.fallbackCalendarNames {
                if let fallback = calendars.first(where: { $0.title == fallbackName }) {
                    McccAlarmLog.holiday("使用备选日历: \"\(fallback.title)\"")
                    return fetchEvents(from: start, to: end, calendar: fallback, rule: rule, timeZone: timeZone)
                }
            }
            McccAlarmLog.error("❌ 未找到任何匹配的节假日日历")
            return ([], [])
        }

        McccAlarmLog.holiday("使用日历: \"\(holidayCalendar.title)\"")
        return fetchEvents(from: start, to: end, calendar: holidayCalendar, rule: rule, timeZone: timeZone)
    }

    private func fetchEvents(
        from start: Date,
        to end: Date,
        calendar ekCalendar: EKCalendar,
        rule: CalendarFilterRule,
        timeZone: TimeZone
    ) -> (holidays: [Date], workdays: [Date]) {
        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: [ekCalendar]
        )

        let events = eventStore.events(matching: predicate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone

        McccAlarmLog.holiday("读取到 \(events.count) 个事件，开始过滤:")
        var holidays: [Date] = []
        var workdays: [Date] = []

        for event in events where event.isAllDay {
            let title = event.title ?? ""

            let eventStart = calendar.startOfDay(for: event.startDate)
            let eventEnd = calendar.startOfDay(for: event.endDate)
            var day = eventStart
            while day < eventEnd {
                let dateStr = formatter.string(from: day)

                if title.contains(rule.workdayKeyword) {
                    McccAlarmLog.holiday("  🏢 \(dateStr) - \(title) [补班]")
                    workdays.append(day)
                } else if title.contains(rule.holidayKeyword) {
                    McccAlarmLog.holiday("  ✅ \(dateStr) - \(title) [法定假日]")
                    if !holidays.contains(where: { calendar.isDate($0, inSameDayAs: day) }) {
                        holidays.append(day)
                    }
                } else {
                    McccAlarmLog.holiday("  ⏭️ \(dateStr) - \(title) [忽略]")
                }

                day = calendar.date(byAdding: .day, value: 1, to: day)!
            }
        }

        holidays = holidays.filter { date in
            !workdays.contains(where: { calendar.isDate($0, inSameDayAs: date) })
        }

        McccAlarmLog.holiday("法定假日: \(holidays.count) 个，补班日: \(workdays.count) 个")
        return (holidays.sorted(), workdays.sorted())
    }
}

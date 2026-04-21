
import Foundation

// MARK: - 调度策略（独立于周期的过滤层）

public enum ScheduleStrategy {
    /// 不过滤，候选日直接触发
    case none
    /// 仅工作日：工作日 + 补班日响，法定假日 + 周末不响
    case workdayOnly
    /// 仅休息日：周末 + 法定假日响，工作日 + 补班日不响
    case restdayOnly
}

// MARK: - 调度策略引擎

public struct HolidaySchedulePolicy {

    // MARK: - 星期枚举（嵌套在 HolidaySchedulePolicy 作用域下）

    public enum Weekday: Int, CaseIterable, Sendable {
        case sunday    = 1
        case monday    = 2
        case tuesday   = 3
        case wednesday = 4
        case thursday  = 5
        case friday    = 6
        case saturday  = 7

        public var calendarValue: Int { rawValue }

        public static let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]
        public static let weekend: [Weekday] = [.saturday, .sunday]
        public static let everyday: [Weekday] = allCases
    }

    // MARK: - 重复周期

    public enum RepeatInterval {
        /// 每 N 天（1 = 每天，3 = 每 3 天）
        case everyNDays(Int)
        /// 每周指定星期
        case weekly([Weekday])
        /// 每 N 月的指定日（day: 几号, everyN: 间隔月数）
        case monthly(day: Int, everyN: Int)
        /// 每 N 年的指定月日（month: 几月, day: 几号, everyN: 间隔年数）
        case yearly(month: Int, day: Int, everyN: Int)
    }

    // MARK: - 周末定义（可配置）

    /// 当前使用的周末定义，默认周六周日。业务方可修改（如中东：周五周六）
    public static var weekendDays: Set<Weekday> = [.saturday, .sunday]

    // MARK: - 计算下一个有效触发日期

    public static func nextValidFireDate(
        interval: RepeatInterval,
        strategy: ScheduleStrategy = .none,
        after: Date = Date(),
        hour: Int,
        minute: Int,
        holidayProvider: HolidayProvider? = nil,
        maxSearchDays: Int = 365
    ) -> Date? {
        let tz = holidayProvider?.timeZone ?? TimeZone(identifier: "Asia/Shanghai")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = tz

        McccAlarmLog.holiday("周期: \(interval) | 策略: \(strategy) | 时间: \(hour):\(String(format: "%02d", minute)) | 起点: \(formatter.string(from: after))")

        var candidate = calendar.startOfDay(for: after)

        var todayComponents = calendar.dateComponents([.year, .month, .day], from: candidate)
        todayComponents.hour = hour
        todayComponents.minute = minute
        if let todayAlarm = calendar.date(from: todayComponents), after >= todayAlarm {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate)!
            McccAlarmLog.holiday("今日时间已过，从明天开始: \(formatter.string(from: candidate))")
        }

        for dayOffset in 0..<maxSearchDays {
            let matchesInterval = evaluateInterval(interval, date: candidate, baseDate: after, calendar: calendar)

            if matchesInterval {
                let passesStrategy = evaluateStrategy(strategy, date: candidate, calendar: calendar, provider: holidayProvider)

                if passesStrategy {
                    var components = calendar.dateComponents([.year, .month, .day], from: candidate)
                    components.hour = hour
                    components.minute = minute
                    components.timeZone = tz
                    McccAlarmLog.holiday("✅ \(formatter.string(from: candidate)) | 搜索了 \(dayOffset + 1) 天")
                    return calendar.date(from: components)
                }
            }

            candidate = calendar.date(byAdding: .day, value: 1, to: candidate)!
        }

        McccAlarmLog.error("在 \(maxSearchDays) 天内未找到有效日期")
        return nil
    }

    // MARK: - 批量计算

    public static func nextValidFireDates(
        count: Int,
        interval: RepeatInterval,
        strategy: ScheduleStrategy = .none,
        after: Date = Date(),
        hour: Int,
        minute: Int,
        holidayProvider: HolidayProvider? = nil
    ) -> [Date] {
        var results: [Date] = []
        var searchFrom = after

        for _ in 0..<count {
            guard let next = nextValidFireDate(
                interval: interval,
                strategy: strategy,
                after: searchFrom,
                hour: hour,
                minute: minute,
                holidayProvider: holidayProvider
            ) else { break }

            results.append(next)
            searchFrom = next
        }

        return results
    }
}

// MARK: - 周期判定

extension HolidaySchedulePolicy {

    private static func evaluateInterval(
        _ interval: RepeatInterval,
        date: Date,
        baseDate: Date,
        calendar: Calendar
    ) -> Bool {
        switch interval {
        case .everyNDays(let n):
            guard n > 0 else { return false }
            let baseDayStart = calendar.startOfDay(for: baseDate)
            let candidateDayStart = calendar.startOfDay(for: date)
            let days = calendar.dateComponents([.day], from: baseDayStart, to: candidateDayStart).day ?? 0
            return days >= 0 && days % n == 0

        case .weekly(let weekdays):
            let weekday = calendar.component(.weekday, from: date)
            let effective = weekdays.isEmpty ? Weekday.everyday : weekdays
            return effective.contains(where: { $0.calendarValue == weekday })

        case .monthly(let day, let everyN):
            guard everyN > 0 else { return false }
            let candidateDay = calendar.component(.day, from: date)
            guard candidateDay == day else { return false }
            let baseMonth = calendar.component(.month, from: baseDate)
            let baseYear = calendar.component(.year, from: baseDate)
            let candidateMonth = calendar.component(.month, from: date)
            let candidateYear = calendar.component(.year, from: date)
            let monthDiff = (candidateYear - baseYear) * 12 + (candidateMonth - baseMonth)
            return monthDiff >= 0 && monthDiff % everyN == 0

        case .yearly(let month, let day, let everyN):
            guard everyN > 0 else { return false }
            let candidateMonth = calendar.component(.month, from: date)
            let candidateDay = calendar.component(.day, from: date)
            guard candidateMonth == month && candidateDay == day else { return false }
            let baseYear = calendar.component(.year, from: baseDate)
            let candidateYear = calendar.component(.year, from: date)
            let yearDiff = candidateYear - baseYear
            return yearDiff >= 0 && yearDiff % everyN == 0
        }
    }
}

// MARK: - 策略判定

extension HolidaySchedulePolicy {

    private static func evaluateStrategy(
        _ strategy: ScheduleStrategy,
        date: Date,
        calendar: Calendar,
        provider: HolidayProvider?
    ) -> Bool {
        guard strategy != .none else { return true }
        guard let provider = provider else { return true }

        let weekday = calendar.component(.weekday, from: date)
        let isHoliday = provider.isHoliday(date)
        let isWorkday = provider.isWorkday(date)
        let isWeekend = weekendDays.contains(where: { $0.calendarValue == weekday })

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        let dateStr = formatter.string(from: date)

        switch strategy {
        case .none:
            return true

        case .workdayOnly:
            if isWorkday {
                McccAlarmLog.holiday("  🏢 \(dateStr): 补班日 → 响铃")
                return true
            }
            if isHoliday {
                McccAlarmLog.holiday("  跳过 \(dateStr): 法定假日")
                return false
            }
            if isWeekend {
                McccAlarmLog.holiday("  跳过 \(dateStr): 周末")
                return false
            }
            return true

        case .restdayOnly:
            if isHoliday {
                McccAlarmLog.holiday("  🎉 \(dateStr): 法定假日 → 响铃")
                return true
            }
            if isWorkday {
                McccAlarmLog.holiday("  跳过 \(dateStr): 补班日")
                return false
            }
            if isWeekend {
                return true
            }
            McccAlarmLog.holiday("  跳过 \(dateStr): 工作日")
            return false
        }
    }
}

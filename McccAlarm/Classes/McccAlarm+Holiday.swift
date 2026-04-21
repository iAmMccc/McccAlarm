
import Foundation
import AlarmKit

@available(iOS 26.0, *)
extension McccAlarm {

    // MARK: - Holiday Provider 注册

    private static var _holidayProvider: HolidayProvider?

    public static func registerHolidayProvider(_ provider: HolidayProvider) {
        _holidayProvider = provider
    }

    public static var holidayProvider: HolidayProvider? {
        _holidayProvider
    }

    // MARK: - 首次调度（创建 / 编辑闹钟时）

    /// 计算并调度未来 N 个有效触发器
    @discardableResult
    public static func scheduleWithStrategy(
        alarmId: String,
        interval: HolidaySchedulePolicy.RepeatInterval,
        strategy: ScheduleStrategy = .none,
        hour: Int,
        minute: Int,
        prefetchCount: Int = AlarmScheduler.defaultPrefetchCount,
        buildConfiguration: @escaping (UUID, Date, [Date]) -> AlarmManager.AlarmConfiguration<McccAlarmMetadata>
    ) async -> [(uuid: UUID, fireDate: Date)] {
        if strategy == .none {
            McccAlarmLog.info("strategy=.none 不需要节假日引擎，建议直接使用 AlarmKit 原生 Schedule.relative(repeats:)")
        }

        let fireDates = HolidaySchedulePolicy.nextValidFireDates(
            count: prefetchCount,
            interval: interval,
            strategy: strategy,
            after: Date(),
            hour: hour,
            minute: minute,
            holidayProvider: _holidayProvider
        )

        guard !fireDates.isEmpty else {
            McccAlarmLog.error("scheduleWithStrategy: 未找到有效日期 alarmId=\(alarmId)")
            return []
        }

        McccAlarmLog.schedule("scheduleWithStrategy: alarmId=\(alarmId) 调度 \(fireDates.count) 个")

        return await AlarmScheduler.schedule(fireDates: fireDates) { uuid, fireDate in
            buildConfiguration(uuid, fireDate, fireDates)
        }
    }

    // MARK: - 补充调度（触发后 / 进前台时）

    /// 计算 targetCount 个有效日期并调度，AlarmKit 对同一 UUID 会自动去重
    @discardableResult
    public static func replenish(
        alarmId: String,
        interval: HolidaySchedulePolicy.RepeatInterval,
        strategy: ScheduleStrategy = .none,
        hour: Int,
        minute: Int,
        targetCount: Int = AlarmScheduler.defaultPrefetchCount,
        buildConfiguration: @escaping (UUID, Date, [Date]) -> AlarmManager.AlarmConfiguration<McccAlarmMetadata>
    ) async -> [(uuid: UUID, fireDate: Date)] {
        let fireDates = HolidaySchedulePolicy.nextValidFireDates(
            count: targetCount,
            interval: interval,
            strategy: strategy,
            after: Date(),
            hour: hour,
            minute: minute,
            holidayProvider: _holidayProvider
        )

        guard !fireDates.isEmpty else {
            McccAlarmLog.error("replenish: 未找到有效日期 alarmId=\(alarmId)")
            return []
        }

        McccAlarmLog.schedule("replenish: alarmId=\(alarmId) 补充 \(fireDates.count) 个")

        return await AlarmScheduler.schedule(fireDates: fireDates) { uuid, fireDate in
            buildConfiguration(uuid, fireDate, fireDates)
        }
    }

    /// App 进前台 / 冷启动时兜底检查
    public static func ensureAlarmsScheduled(checker: () throws -> Void) rethrows {
        try checker()
    }
}

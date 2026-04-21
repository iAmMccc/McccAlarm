
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

    // MARK: - 首次调度（创建闹钟时）

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

        // 先取消该闹钟已有的触发器（编辑场景）
        AlarmScheduler.cancelAll(forAlarmId: alarmId)

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

        McccAlarmLog.schedule("首次调度: alarmId=\(alarmId) 调度 \(fireDates.count) 个触发器")

        return await AlarmScheduler.schedule(fireDates: fireDates) { uuid, fireDate in
            buildConfiguration(uuid, fireDate, fireDates)
        }
    }

    // MARK: - 补充调度（触发后 / 进前台时）

    /// 检查并补充到目标数量（不取消已有的 sibling）
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
        // 查询当前 pending 的触发器
        let pendingAlarms = AlarmScheduler.pendingAlarms(forAlarmId: alarmId)
        let pendingCount = pendingAlarms.count
        let deficit = targetCount - pendingCount

        McccAlarmLog.schedule("replenish: alarmId=\(alarmId) pending=\(pendingCount) 目标=\(targetCount) 差额=\(deficit)")

        guard deficit > 0 else {
            McccAlarmLog.schedule("replenish: 数量充足，无需补充")
            return []
        }

        // 从最后一个 pending 的日期之后开始计算，避免重复
        let lastPendingDate = pendingAlarms
            .compactMap { $0.metadata?.fireDate }
            .max() ?? Date()

        let newFireDates = HolidaySchedulePolicy.nextValidFireDates(
            count: deficit,
            interval: interval,
            strategy: strategy,
            after: lastPendingDate,
            hour: hour,
            minute: minute,
            holidayProvider: _holidayProvider
        )

        guard !newFireDates.isEmpty else {
            McccAlarmLog.error("replenish: 未找到新的有效日期")
            return []
        }

        let allFireDates = pendingAlarms.compactMap { $0.metadata?.fireDate } + newFireDates
        McccAlarmLog.schedule("replenish: 补充 \(newFireDates.count) 个触发器")

        return await AlarmScheduler.schedule(fireDates: newFireDates) { uuid, fireDate in
            buildConfiguration(uuid, fireDate, allFireDates)
        }
    }

    /// 检查并补充所有需要调度的闹钟（App 进前台/冷启动时调用）
    public static func ensureAlarmsScheduled(checker: () throws -> Void) rethrows {
        try checker()
    }
}


import Foundation
import AlarmKit

@available(iOS 26.0, *)
extension McccAlarm {

    // MARK: - Holiday Provider 注册

    private static var _holidayProvider: HolidayProvider?

    /// 注册节假日数据源（App 启动时调用）
    public static func registerHolidayProvider(_ provider: HolidayProvider) {
        _holidayProvider = provider
    }

    /// 获取当前注册的节假日数据源
    public static var holidayProvider: HolidayProvider? {
        _holidayProvider
    }

    // MARK: - 节假日感知的闹钟调度

    /// 调度一个节假日感知的闹钟（使用一次性 fixed schedule）
    @discardableResult
    public static func scheduleWithStrategy<M: AlarmMetadata>(
        id: UUID,
        interval: HolidaySchedulePolicy.RepeatInterval,
        strategy: ScheduleStrategy = .none,
        hour: Int,
        minute: Int,
        buildConfiguration: (Date) -> AlarmManager.AlarmConfiguration<M>
    ) async throws -> Bool {
        guard let fireDate = HolidaySchedulePolicy.nextValidFireDate(
            interval: interval,
            strategy: strategy,
            after: Date(),
            hour: hour,
            minute: minute,
            holidayProvider: _holidayProvider
        ) else {
            McccAlarmLog.error("scheduleWithStrategy: 未找到有效日期 id=\(id)")
            return false
        }

        let configuration = buildConfiguration(fireDate)
        let _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
        McccAlarmLog.schedule("scheduleWithStrategy: ✅ id=\(id) fireDate=\(fireDate)")
        return true
    }

    /// 检查并补充调度（App 进前台/冷启动时调用）
    public static func ensureAlarmsScheduled(checker: () throws -> Void) rethrows {
        try checker()
    }
}

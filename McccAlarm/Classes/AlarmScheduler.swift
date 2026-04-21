
import Foundation
import AlarmKit

/// 批量调度管理
@available(iOS 26.0, *)
public struct AlarmScheduler {

    /// 默认预调度数量
    public static var defaultPrefetchCount: Int = 3

    // MARK: - 调度

    /// 批量调度
    @discardableResult
    public static func schedule<M: AlarmMetadata>(
        fireDates: [Date],
        buildConfiguration: (UUID, Date) -> AlarmManager.AlarmConfiguration<M>
    ) async -> [(uuid: UUID, fireDate: Date)] {
        var results: [(uuid: UUID, fireDate: Date)] = []

        for fireDate in fireDates {
            let uuid = UUID()
            let config = buildConfiguration(uuid, fireDate)

            do {
                let _ = try await AlarmManager.shared.schedule(id: uuid, configuration: config)
                results.append((uuid, fireDate))
                McccAlarmLog.schedule("schedule: ✅ \(uuid) → \(fireDate)")
            } catch {
                McccAlarmLog.error("schedule: \(uuid) → \(fireDate) error=\(error)")
            }
        }

        McccAlarmLog.schedule("批量调度完成: \(results.count)/\(fireDates.count) 成功")
        return results
    }

    // MARK: - 取消

    /// 取消一组 UUID 对应的闹钟
    public static func cancel(uuids: [UUID]) {
        for uuid in uuids {
            do {
                try AlarmManager.shared.cancel(id: uuid)
                McccAlarmLog.schedule("cancel: \(uuid)")
            } catch {
                McccAlarmLog.error("cancel 失败: \(uuid) error=\(error)")
            }
        }
    }

    /// 取消所有闹钟
    public static func cancelAll() {
        let uuids = Array(pendingUUIDs())
        guard !uuids.isEmpty else { return }
        McccAlarmLog.schedule("cancelAll: 取消 \(uuids.count) 个触发器")
        cancel(uuids: uuids)
    }

    // MARK: - 查询

    /// 获取当前系统中所有 pending 的闹钟
    public static func pendingAlarms() -> [Alarm] {
        do {
            return try AlarmManager.shared.alarms
        } catch {
            McccAlarmLog.error("读取 pending alarms 失败: \(error)")
            return []
        }
    }

    /// 获取当前系统中所有 pending 的闹钟 UUID
    public static func pendingUUIDs() -> Set<UUID> {
        Set(pendingAlarms().map { $0.id })
    }

    /// 当前 pending 闹钟数量
    public static func pendingCount() -> Int {
        pendingAlarms().count
    }

    /// 获取所有 pending 的 fixed 日期
    public static func pendingFixedDates() -> [Date] {
        pendingAlarms().compactMap { alarm in
            if case .fixed(let date) = alarm.schedule {
                return date
            }
            return nil
        }
    }

    /// 计算需要补充的日期（目标日期中尚未存在于 pending 的）
    /// - Parameters:
    ///   - targetDates: 期望调度的日期列表
    ///   - tolerance: 时间容差（秒），默认 60 秒内视为同一个
    /// - Returns: 需要新调度的日期
    public static func datesNeedingSchedule(
        targetDates: [Date],
        tolerance: TimeInterval = 60
    ) -> [Date] {
        let existing = pendingFixedDates()
        return targetDates.filter { target in
            !existing.contains(where: { abs($0.timeIntervalSince(target)) < tolerance })
        }
    }
}

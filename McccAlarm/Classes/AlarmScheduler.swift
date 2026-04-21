
import Foundation
import AlarmKit

/// 批量调度管理
@available(iOS 26.0, *)
public struct AlarmScheduler {

    /// 默认预调度数量
    public static var defaultPrefetchCount: Int = 3

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

    /// 获取当前系统中所有 pending 的闹钟 UUID
    public static func pendingUUIDs() -> Set<UUID> {
        do {
            let alarms = try AlarmManager.shared.alarms
            return Set(alarms.map { $0.id })
        } catch {
            McccAlarmLog.error("读取 pending alarms 失败: \(error)")
            return []
        }
    }

    /// 当前 pending 闹钟数量
    public static func pendingCount() -> Int {
        pendingUUIDs().count
    }

    /// 取消所有闹钟
    public static func cancelAll() {
        let uuids = Array(pendingUUIDs())
        guard !uuids.isEmpty else { return }
        McccAlarmLog.schedule("cancelAll: 取消 \(uuids.count) 个触发器")
        cancel(uuids: uuids)
    }
}

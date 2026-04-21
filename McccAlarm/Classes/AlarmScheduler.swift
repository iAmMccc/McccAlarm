
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
    /// - Parameters:
    ///   - fireDates: 要调度的触发日期列表
    ///   - buildConfiguration: 根据 (uuid, fireDate) 构建 AlarmKit 配置。uuid 已自动生成。
    /// - Returns: 成功调度的 (uuid, fireDate) 列表
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
                McccAlarmLog.schedule("schedule: \u{2705} \(uuid) → \(fireDate)")
            } catch {
                McccAlarmLog.error("schedule: \(uuid) → \(fireDate) error=\(error)")
            }
        }

        McccAlarmLog.schedule("批量调度完成: \(results.count)/\(fireDates.count) 成功")
        return results
    }

    /// 获取当前系统中所有 pending 的闹钟
    public static func pendingAlarms() -> [Alarm<McccAlarmMetadata>] {
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

    /// 根据 metadata 中的 alarmId 查找某个闹钟的所有 pending 触发器
    public static func pendingAlarms(forAlarmId alarmId: String) -> [Alarm<McccAlarmMetadata>] {
        pendingAlarms().filter { $0.metadata?.alarmId == alarmId }
    }

    /// 取消某个 alarmId 下所有 pending 触发器
    public static func cancelAll(forAlarmId alarmId: String) {
        let uuids = pendingAlarms(forAlarmId: alarmId).map { $0.id }
        guard !uuids.isEmpty else { return }
        McccAlarmLog.schedule("cancelAll: alarmId=\(alarmId) 取消 \(uuids.count) 个触发器")
        cancel(uuids: uuids)
    }
}

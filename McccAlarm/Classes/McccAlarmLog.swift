
import Foundation

public enum McccAlarmLog {

    /// 是否启用日志（默认 DEBUG 开启，RELEASE 关闭）
    #if DEBUG
    public static var isEnabled: Bool = true
    #else
    public static var isEnabled: Bool = false
    #endif

    public static func info(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("🔔 [McccAlarm] \(fileName):\(line) | \(message())")
    }

    public static func holiday(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("📅 [Holiday] \(fileName):\(line) | \(message())")
    }

    public static func schedule(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("⏰ [Schedule] \(fileName):\(line) | \(message())")
    }

    public static func error(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("❌ [McccAlarm] \(fileName):\(line) | \(message())")
    }
}

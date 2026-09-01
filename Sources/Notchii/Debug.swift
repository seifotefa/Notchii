import Foundation

/// Opt-in tracing: run the binary with NOTCHII_DEBUG=1 to see state changes.
enum Debug {
    static let isOn = ProcessInfo.processInfo.environment["NOTCHII_DEBUG"] != nil
    private static let start = Date()

    static func log(_ message: @autoclosure () -> String) {
        guard isOn else { return }
        let t = String(format: "%7.3f", Date().timeIntervalSince(start))
        FileHandle.standardError.write(Data("[\(t)] \(message())\n".utf8))
    }
}

import os.log

public struct Logger: Sendable {
    private let osLogger: os.Logger
    
    public init(category: String) {
        self.osLogger = os.Logger(subsystem: "com.swiftsheetgen", category: category)
    }
    
    public func info(_ message: String) {
        osLogger.info("\(message)")
    }
    
    public func error(_ message: String) {
        osLogger.error("\(message)")
    }
    
    public func debug(_ message: String) {
        osLogger.debug("\(message)")
    }
}

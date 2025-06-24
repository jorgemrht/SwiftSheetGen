import os.log
import Foundation

// MARK: - Centralized Logger Configuration
public extension Logger {
    private static let subsystem = "com.swiftsheetgen"
    
    // MARK: - Module Loggers
    static let csvDownloader = Logger(subsystem: subsystem, category: "CSVDownloader")
    static let csvParser = Logger(subsystem: subsystem, category: "CSVParser")
    static let googleSheetURLTransformer = Logger(subsystem: subsystem, category: "GoogleSheetURLTransformer")
    static let localizationGenerator = Logger(subsystem: subsystem, category: "LocalizationGenerator")
    static let xcodeIntegration = Logger(subsystem: subsystem, category: "XcodeIntegration")
    static let urlTransformer = Logger(subsystem: subsystem, category: "URLTransformer")
    static let cli = Logger(subsystem: subsystem, category: "CLI")
    
    // MARK: - Convenience Methods for Better DX
    func logError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let location = "\(fileName):\(line) \(function)"
        
        if let error = error {
            self.error("[\(location)] \(message) | Error: \(error.localizedDescription)")
        } else {
            self.error("[\(location)] \(message)")
        }
    }
    
    func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let location = "\(fileName):\(line) \(function)"
        self.info("[\(location)] \(message)")
    }
    
    func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let location = "\(fileName):\(line) \(function)"
        self.debug("[\(location)] \(message)")
    }
}

import os.log
import Foundation

// MARK: - Centralized Logger Configuration

public extension Logger {
    
    /// Using bundle identifier ensures unique subsystem identifier
    private static let subsystem = "com.swiftsheetgen"
    
    // MARK: - Module-Specific Loggers with Optimized Categories
    
    /// CSV download and network operations
    static let csvDownloader = Logger(subsystem: subsystem, category: "CSV.Download")
    
    /// CSV parsing and data processing
    static let csvParser = Logger(subsystem: subsystem, category: "CSV.Parser")
    
    /// Google Sheets URL transformation
    static let googleSheetURLTransformer = Logger(subsystem: subsystem, category: "GoogleSheets.URL")
    
    /// Swift localization file generation
    static let localizationGenerator = Logger(subsystem: subsystem, category: "Localization.Generator")
    
    /// Xcode project integration
    static let xcodeIntegration = Logger(subsystem: subsystem, category: "Xcode.Integration")
    
    /// CLI command processing
    static let cli = Logger(subsystem: subsystem, category: "CLI")
    
    /// File system operations
    static let fileSystem = Logger(subsystem: subsystem, category: "FileSystem")
    
    /// Network operations and validation
    static let network = Logger(subsystem: subsystem, category: "Network")
}

// MARK: - Privacy and Performance Extensions

public extension Logger {
    
    func logInfo(_ message: String, value: String, isPrivate: Bool = false) {
        if isPrivate {
            self.info("\(message) \(value, privacy: .private)")
        } else {
            self.info("\(message) \(value, privacy: .public)")
        }
    }
    
    func logError(_ message: String, value: String, isPrivate: Bool = false) {
        if isPrivate {
            self.error("\(message) \(value, privacy: .private)")
        } else {
            self.error("\(message) \(value, privacy: .public)")
        }
    }
    
    func logFatal(_ message: String, error: Error? = nil, isPrivate: Bool = false) -> Never {
        if let error = error {
            if isPrivate {
                self.error("FATAL: \(message, privacy: .private) - \(error.localizedDescription, privacy: .private)")
            } else {
                self.error("FATAL: \(message, privacy: .public) - \(error.localizedDescription, privacy: .public)")
            }
        } else {
            if isPrivate {
                self.error("FATAL: \(message, privacy: .private)")
            } else {
                self.error("FATAL: \(message, privacy: .public)")
            }
        }
        exit(EXIT_FAILURE)
    }
    
    func logNetworkRequest(url: String, method: String, statusCode: Int, isPrivate: Bool = false) {
        if isPrivate {
            self.info("Network Request: \(method, privacy: .private) \(url, privacy: .private) -> \(statusCode, privacy: .private)")
        } else {
            self.info("Network Request: \(method, privacy: .public) \(url, privacy: .public) -> \(statusCode, privacy: .public)")
        }
    }

    func logFileOperation(_ operation: String, path: String, size: Int64? = nil, isPrivate: Bool = false) {
        let sizeString = size.map { " [\(ByteCountFormatter.string(fromByteCount: $0, countStyle: .file))]" } ?? ""
        if isPrivate {
            self.info("File Operation: \(operation, privacy: .private) \(path, privacy: .private)\(sizeString, privacy: .private)")
        } else {
            self.info("File Operation: \(operation, privacy: .public) \(path, privacy: .public)\(sizeString, privacy: .public)")
        }
    }

    func logCSVProcessing(rowCount: Int, columnCount: Int, processingTime: TimeInterval, isPrivate: Bool = false) {
        if isPrivate {
            self.info("CSV Processing: \(rowCount, privacy: .private) rows, \(columnCount, privacy: .private) columns in \(processingTime, format: .fixed(precision: 3), privacy: .private)s")
        } else {
            self.info("CSV Processing: \(rowCount, privacy: .public) rows, \(columnCount, privacy: .public) columns in \(processingTime, format: .fixed(precision: 3), privacy: .public)s")
        }
    }
}

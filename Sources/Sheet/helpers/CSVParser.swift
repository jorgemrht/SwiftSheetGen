import Foundation
import CoreExtensions
import os.log

// MARK: - CSV Parser Protocol

public protocol CSVParserProtocol: Sendable {
    static func parse(_ content: String) throws -> [[String]]
    static func parseWithValidation(_ content: String) throws -> [[String]]
    static func parseToKeyedRows(_ content: String) throws -> [[String: String]]
}

public protocol StreamingCSVParserProtocol: Sendable {
    static func parseStream(fileURL: URL, bufferSize: Int) async throws -> [[String]]
    static func parseStreamWithValidation(fileURL: URL, bufferSize: Int) async throws -> [[String]]
}

// MARK: - CSV Parser

public struct CSVParser: CSVParserProtocol, StreamingCSVParserProtocol, Sendable {
    
    internal enum ParseState: Sendable {
        case field, quotedField, quotedQuote
    }
    
    private static let logger = Logger.csvParser
    
    private static let newlinePattern = CharacterSet(charactersIn: "\r\n")
    private static let whitespaceAndNewlines = CharacterSet.whitespacesAndNewlines

    public static func parse(_ content: String) throws -> [[String]] {
   
        guard !content.isEmptyOrWhitespace else {
            logger.error("Empty CSV content provided")
            throw SheetLocalizerError.csvParsingError("CSV content is empty")
        }
        
        logger.debug("Starting CSV parsing, content length: \(content.count)")
        
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var state: ParseState = .field
        var lineNumber = 1
        
        for char in content {
            switch (state, char) {
            case (.field, "\""):
                state = .quotedField
                
            case (.field, ","):
                currentRow.append(currentField.trimmedContent)
                currentField = ""
                
            case (.field, "\n"), (.field, "\r\n"):
                currentRow.append(currentField.trimmedContent)
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                    logger.debug("Parsed row \(lineNumber): \(currentRow.count) fields")
                }
                currentRow = []
                currentField = ""
                lineNumber += 1
                
            case (.quotedField, "\""):
                state = .quotedQuote
                
            case (.quotedQuote, "\""):
                currentField.append("\"")
                state = .quotedField
                
            case (.quotedQuote, ","):
                currentRow.append(currentField.trimmedContent)
                currentField = ""
                state = .field
                
            case (.quotedQuote, "\n"), (.quotedQuote, "\r\n"):
                currentRow.append(currentField.trimmedContent)
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                    logger.debug("Parsed row \(lineNumber): \(currentRow.count) fields")
                }
                currentRow = []
                currentField = ""
                state = .field
                lineNumber += 1
                
            case (.quotedField, "\n"), (.quotedField, "\r\n"):
                currentField.append(char)
                
            default:
                currentField.append(char)
                if state == .quotedQuote { state = .quotedField }
            }
        }
        
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmedContent)
            rows.append(currentRow)
            logger.debug("Parsed final row \(lineNumber): \(currentRow.count) fields")
        }
        
        let filteredRows = rows.filter { !$0.allSatisfy(\.isEmptyOrWhitespace) }
        
        logger.info("CSV parsing completed: \(filteredRows.count) valid rows from \(lineNumber) total lines")
        
        guard !filteredRows.isEmpty else {
            logger.error("No valid rows found after parsing")
            throw SheetLocalizerError.csvParsingError("No valid rows found in CSV")
        }
        
        return filteredRows
    }
    
    public static func parseWithValidation(_ content: String) throws -> [[String]] {
        let rows = try parse(content)
        
        let firstRowColumnCount = rows.first?.count ?? 0
        
        guard firstRowColumnCount > 0 else {
            logger.error("First row has no columns")
            throw SheetLocalizerError.csvParsingError("First row is empty")
        }
        
        for (index, row) in rows.enumerated() {
            if row.count != firstRowColumnCount {
                logger.error("Row \(index + 1) has \(row.count) columns, expected \(firstRowColumnCount)")
                throw SheetLocalizerError.csvParsingError("Row \(index + 1) has inconsistent column count: expected \(firstRowColumnCount), got \(row.count)")
            }
        }
        
        logger.info("CSV validation passed: \(rows.count) rows with \(firstRowColumnCount) columns each")
        return rows
    }
    
    public static func parseToKeyedRows(_ content: String) throws -> [[String: String]] {
        let rows = try parseWithValidation(content)
        
        guard let headerRow = rows.first else {
            throw SheetLocalizerError.csvParsingError("No header row found")
        }
        
        let dataRows = Array(rows.dropFirst())
        
        return dataRows.map { row in
            Dictionary(uniqueKeysWithValues: zip(headerRow, row))
        }
    }
    
    public static func parse(filePath: String) async throws -> [[String]] {
        let fileURL = URL(fileURLWithPath: filePath)
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: filePath)[.size] as? Int64 ?? 0
        let fileSizeInMB = Double(fileSize) / (1024 * 1024)
        
        let streamingThreshold: Int64 = 2 * 1024 * 1024
        
        if fileSize > streamingThreshold {
            logger.debug("Using streaming parser for file: \(String(format: "%.2f", fileSizeInMB)) MB")
            return try await parseStreamWithValidation(fileURL: fileURL, bufferSize: selectBufferSize(fileSize: fileSize))
        } else {
            logger.debug("Using traditional parser for file: \(String(format: "%.2f", fileSizeInMB)) MB")
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            return try parseWithValidation(content)
        }
    }
    
    private static func selectBufferSize(fileSize: Int64) -> Int {
        let fileSizeInMB = fileSize / (1024 * 1024)
        
        switch fileSizeInMB {
        case 0..<10:
            return 16 * 1024
        case 10..<50:
            return 64 * 1024
        case 50..<200:
            return 128 * 1024
        default:
            return 256 * 1024
        }
    }
}

// MARK: - Streaming CSV Parser Implementation

extension CSVParser {
    
    public struct StreamingConfig: Sendable {
        public let bufferSize: Int
        public let maxMemoryUsage: Int
        public let batchSize: Int
        public let logProgressInterval: Int
        
        public static let `default` = StreamingConfig(
            bufferSize: 16384,
            maxMemoryUsage: 20 * 1024 * 1024,
            batchSize: 2000,
            logProgressInterval: 10
        )
        
        public static let highPerformance = StreamingConfig(
            bufferSize: 128 * 1024,
            maxMemoryUsage: 100 * 1024 * 1024,
            batchSize: 10000,
            logProgressInterval: 5
        )
        
        public static let memoryConstrained = StreamingConfig(
            bufferSize: 8192,
            maxMemoryUsage: 10 * 1024 * 1024,
            batchSize: 1000,
            logProgressInterval: 20
        )
    }
    
    public static func parseStream(fileURL: URL, bufferSize: Int = StreamingConfig.default.bufferSize) async throws -> [[String]] {
        logger.info("Starting streaming CSV parsing for file: \(fileURL.path)")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SheetLocalizerError.fileSystemError("File not found: \(fileURL.path)")
        }
        
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer {
            try? fileHandle.close()
        }
        
        let config = selectOptimalConfig(bufferSize: bufferSize, fileURL: fileURL)
        let reader = BufferedCSVReader(fileHandle: fileHandle, config: config)
        
        var allRows: [[String]] = []
        var currentBatch: [[String]] = []
        var batchCount = 0
        
        currentBatch.reserveCapacity(config.batchSize)
        allRows.reserveCapacity(estimateRowCount(fileURL: fileURL))
        
        while let row = try await reader.readNextRow() {
            currentBatch.append(row)
            
            if currentBatch.count >= config.batchSize {
                batchCount += 1
                
                let validRows = currentBatch.filter { !$0.allSatisfy(\.isEmptyOrWhitespace) }
                allRows.append(contentsOf: validRows)
                currentBatch.removeAll(keepingCapacity: true)
                
                if config.logProgressInterval > 0 && batchCount % config.logProgressInterval == 0 {
                    let processedRows = batchCount * config.batchSize
                    logger.info("Processed \(processedRows) rows (\(allRows.count) valid)")
                    
                    try Task.checkCancellation()
                }
            }
        }
        
        if !currentBatch.isEmpty {
            let validRows = currentBatch.filter { !$0.allSatisfy(\.isEmptyOrWhitespace) }
            allRows.append(contentsOf: validRows)
        }
        
        guard !allRows.isEmpty else {
            logger.error("No valid rows found after streaming parse")
            throw SheetLocalizerError.csvParsingError("No valid rows found in CSV")
        }
        
        logger.info("Streaming CSV parsing completed: \(allRows.count) valid rows")
        return allRows
    }
    
    public static func parseStreamWithValidation(fileURL: URL, bufferSize: Int = StreamingConfig.default.bufferSize) async throws -> [[String]] {
        let rows = try await parseStream(fileURL: fileURL, bufferSize: bufferSize)
        
        let firstRowColumnCount = rows.first?.count ?? 0
        guard firstRowColumnCount > 0 else {
            logger.error("First row has no columns")
            throw SheetLocalizerError.csvParsingError("First row is empty")
        }
        
        let sampleSize = min(100, rows.count)
        for (index, row) in rows.prefix(sampleSize).enumerated() {
            if row.count != firstRowColumnCount {
                logger.error("Row \(index + 1) has \(row.count) columns, expected \(firstRowColumnCount)")
                throw SheetLocalizerError.csvParsingError("Row \(index + 1) has inconsistent column count: expected \(firstRowColumnCount), got \(row.count)")
            }
        }
        
        logger.info("Streaming CSV validation passed: \(rows.count) rows with \(firstRowColumnCount) columns each")
        return rows
    }
    
    // MARK: - CLI Helpers
    
    private static func selectOptimalConfig(bufferSize: Int, fileURL: URL) -> StreamingConfig {
        guard let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 else {
            return StreamingConfig.default
        }
        
        let fileSizeInMB = fileSize / (1024 * 1024)
        
        if bufferSize >= 64 * 1024 || fileSizeInMB > 100 {
            return StreamingConfig.highPerformance
        } else if fileSizeInMB > 50 {
            return StreamingConfig.default
        } else {
            return StreamingConfig.memoryConstrained
        }
    }
    
    private static func estimateRowCount(fileURL: URL) -> Int {
        guard let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 else {
            return 1000
        }
        
        let estimatedRows = max(1000, Int(fileSize / 100))
        return min(estimatedRows, 1_000_000)
    }
}

// MARK: - Buffered CSV Reader

private actor BufferedCSVReader {
    
    private let fileHandle: FileHandle
    private let config: CSVParser.StreamingConfig
    private var buffer: Data
    private var parseState: CSVParser.ParseState = .field
    private var currentField = ""
    private var currentRow: [String] = []
    private var isEndOfFile = false
    private var lineNumber = 1
    
    init(fileHandle: FileHandle, config: CSVParser.StreamingConfig) {
        self.fileHandle = fileHandle
        self.config = config
        self.buffer = Data()
        self.buffer.reserveCapacity(config.bufferSize)
    }
    
    func readNextRow() throws -> [String]? {
        while !isEndOfFile {
            try fillBufferIfNeeded()
            
            guard !buffer.isEmpty else {
                break
            }
            
            if let row = try parseBufferForNextRow() {
                return row
            }
        }
        
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmedContent)
            let finalRow = currentRow
            currentRow = []
            currentField = ""
            return finalRow.isEmpty ? nil : finalRow
        }
        
        return nil
    }
    
    private func fillBufferIfNeeded() throws {
        guard buffer.count < config.bufferSize / 4 && !isEndOfFile else { return }
        
        let readSize = config.bufferSize * 2  // Read 2x buffer size for efficiency
        let newData = fileHandle.readData(ofLength: readSize)
        
        if newData.isEmpty {
            isEndOfFile = true
        } else {
            buffer.append(newData)
        }
    }
    
    private func parseBufferForNextRow() throws -> [String]? {
        var bytesConsumed = 0
        
        for byte in buffer {
            guard byte < 128 else {
                bytesConsumed += 1
                continue
            }
            let char = Character(UnicodeScalar(byte))
            bytesConsumed += 1
            
            switch (parseState, char) {
            case (.field, "\""):
                parseState = .quotedField
                
            case (.field, ","):
                currentRow.append(currentField.trimmedContent)
                currentField = ""
                
            case (.field, "\n"), (.field, "\r"):
                currentRow.append(currentField.trimmedContent)
                if !currentRow.isEmpty {
                    let completedRow = currentRow
                    currentRow = []
                    currentField = ""
                    lineNumber += 1
                    
                    buffer.removeFirst(bytesConsumed)
                    return completedRow
                }
                currentRow = []
                currentField = ""
                lineNumber += 1
                
            case (.quotedField, "\""):
                parseState = .quotedQuote
                
            case (.quotedQuote, "\""):
                currentField.append("\"")
                parseState = .quotedField
                
            case (.quotedQuote, ","):
                currentRow.append(currentField.trimmedContent)
                currentField = ""
                parseState = .field
                
            case (.quotedQuote, "\n"), (.quotedQuote, "\r"):
                currentRow.append(currentField.trimmedContent)
                if !currentRow.isEmpty {
                    let completedRow = currentRow
                    currentRow = []
                    currentField = ""
                    parseState = .field
                    lineNumber += 1
                    
                    buffer.removeFirst(bytesConsumed)
                    return completedRow
                }
                currentRow = []
                currentField = ""
                parseState = .field
                lineNumber += 1
                
            case (.quotedField, "\n"), (.quotedField, "\r"):
                currentField.append(char)
                
            default:
                currentField.append(char)
                if parseState == .quotedQuote { 
                    parseState = .quotedField 
                }
            }
        }
        
        buffer.removeFirst(bytesConsumed)
        return nil
    }
}

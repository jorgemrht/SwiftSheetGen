import Foundation
import Extensions

public struct CSVParser: Sendable {
    
    private enum ParseState {
        case field, quotedField, quotedQuote
    }
    
    private static let logger = Logger(category: "CSVParser")
    
    public static func parse(_ content: String) throws -> [[String]] {
   
        guard !content.isBlank else {
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
                currentRow.append(currentField.trimmed)
                currentField = ""
                
            case (.field, "\n"), (.field, "\r\n"):
                currentRow.append(currentField.trimmed)
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
                currentRow.append(currentField.trimmed)
                currentField = ""
                state = .field
                
            case (.quotedQuote, "\n"), (.quotedQuote, "\r\n"):
                currentRow.append(currentField.trimmed)
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
            currentRow.append(currentField.trimmed)
            rows.append(currentRow)
            logger.debug("Parsed final row \(lineNumber): \(currentRow.count) fields")
        }
        
        let filteredRows = rows.filter { !$0.allSatisfy(\.isBlank) }
        
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
}

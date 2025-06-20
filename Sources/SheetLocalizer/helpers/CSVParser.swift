//
//  Created by jorge on 20/6/25.
//

// MARK: - CSV Parser
public struct CSVParser: Sendable {
   
    static func parse(_ content: String) throws -> [[String]] {
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SheetLocalizerError.csvParsingError("Empty content")
        }
        
        let lines = content.components(separatedBy: .newlines)
        let parsedLines = try lines.compactMap { line -> [String]? in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { return nil }
            return try parseLine(trimmedLine)
        }
        
        guard !parsedLines.isEmpty else {
            throw SheetLocalizerError.csvParsingError("No valid lines found")
        }
        
        return parsedLines
    }
    
    private static func parseLine(_ line: String) throws -> [String] {
        var values: [String] = []
        var current = ""
        var inQuotes = false
        var escapeNext = false
        
        for char in line {
            if escapeNext {
                current.append(char)
                escapeNext = false
                continue
            }
            
            switch char {
            case "\\" where inQuotes:
                escapeNext = true
            case "\"":
                if inQuotes && current.last == "\"" {
                    // Doble comilla dentro de comillas = escape
                    current.append(char)
                } else {
                    inQuotes.toggle()
                }
            case "," where !inQuotes:
                values.append(current)
                current = ""
            default:
                current.append(char)
            }
        }
        
        values.append(current)
        return values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

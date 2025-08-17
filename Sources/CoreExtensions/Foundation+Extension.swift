import Foundation

// MARK: - String Extensions

public extension String {
    var isEmptyOrWhitespace: Bool {
        isEmpty || allSatisfy(\.isWhitespace)
    }
    
    var trimmedContent: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isGoogleSheetsURL: Bool {
        guard !isEmptyOrWhitespace else { return false }
        
        let trimmed = trimmedContent
        
        let pubhtmlPattern = #"^https://docs\.google\.com/spreadsheets/d/e/[a-zA-Z0-9_.-]+/pubhtml$"#
        
        let csvPattern = #"^https://docs\.google\.com/spreadsheets/d/e/[a-zA-Z0-9_.-]+/pub\?output=csv$"#
        
        return trimmed.range(of: pubhtmlPattern, options: .regularExpression) != nil ||
               trimmed.range(of: csvPattern, options: .regularExpression) != nil
    }
    
    var googleSheetsDocumentID: String? {
        let pattern = #"/spreadsheets/d/e/([a-zA-Z0-9_.-]+)/"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              let range = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[range])
    }
    
    var csvEscaped: String {
        if contains("\"") || contains(",") || contains("\n") {
            return "\"\(replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return self
    }
    
    var isValidLocalizationKey: Bool {
        !isEmpty && !hasPrefix(" ") && !hasSuffix(" ") && !contains("\"") && !contains("\n")
    }
    
    var invalidLocalizationKeyReason: String? {
        if isEmpty { return "Key is empty" }
        if hasPrefix(" ") { return "Key starts with a space" }
        if hasSuffix(" ") { return "Key ends with a space" }
        if contains("\"") { return "Key contains a double quote (\")" }
        if contains("\n") { return "Key contains a newline" }
        return nil
    }
}

// MARK: - Array Extensions

public extension Array where Element == String {
    var csvRow: String { map(\.csvEscaped).joined(separator: ",") }
}
public extension Array where Element == [String] {
    var csvContent: String { map(\.csvRow).joined(separator: "\n") }
}

// MARK: - FileManager Extensions

public extension FileManager {
    func createDirectoryIfNeeded(atPath path: String, createIntermediates: Bool = true) throws {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FileManagerError.invalidPath
        }
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: path, isDirectory: &isDirectory)
        if !exists {
            try createDirectory(atPath: path, withIntermediateDirectories: createIntermediates)
        } else if !isDirectory.boolValue {
            throw FileManagerError.pathExistsButNotDirectory
        }
    }
    
    @discardableResult
    func safeRemoveItem(atPath path: String) throws -> Bool {
        guard fileExists(atPath: path) else { return false }
        try removeItem(atPath: path)
        return true
    }
}

// MARK: - Custom Error Types

public enum FileManagerError: LocalizedError, Sendable {
    case invalidPath
    case pathExistsButNotDirectory
    public var errorDescription: String? {
        switch self {
        case .invalidPath: return "The provided path is invalid or empty"
        case .pathExistsButNotDirectory: return "Path exists but is not a directory"
        }
    }
}

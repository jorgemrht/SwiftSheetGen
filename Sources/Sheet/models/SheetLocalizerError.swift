import Foundation

// MARK: - Error Types

public enum SheetLocalizerError: Error, LocalizedError, Sendable {
    
    case invalidURL(String)
    case networkError(String)
    case csvParsingError(String)
    case fileSystemError(String)
    case insufficientData
    case httpError(Int)
    case localizationGenerationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "URL inválida: \(url)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .csvParsingError(let message):
            return "Error parsing CSV: \(message)"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .insufficientData:
            return "Insufficient data in the CSV"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .localizationGenerationError(let message):
            return "Localization generation error: \(message)"
        }
    }
}

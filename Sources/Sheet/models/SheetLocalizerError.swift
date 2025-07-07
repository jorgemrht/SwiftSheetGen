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
            "URL inválida: \(url)"
        case .networkError(let message):
            "Network error: \(message)"
        case .csvParsingError(let message):
            "Error parsing CSV: \(message)"
        case .fileSystemError(let message):
            "File system error: \(message)"
        case .insufficientData:
            "Insufficient data in the CSV"
        case .httpError(let statusCode):
            "HTTP error: \(statusCode)"
        case .localizationGenerationError(let message):
            "Localization generation error: \(message)"
        }
    }
}

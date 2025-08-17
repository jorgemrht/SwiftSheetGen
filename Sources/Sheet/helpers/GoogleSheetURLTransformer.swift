import Foundation
import CoreExtensions
import os.log

// MARK: - Google Sheet URL Transformer

public struct GoogleSheetURLTransformer: Sendable {
  
    private static let logger = Logger.googleSheetURLTransformer

    public static func transformToCSV(_ urlString: String) throws -> String {
        
        guard urlString.isGoogleSheetsURL else {
            logger.error("Provided string is not a valid Google Sheets URL. Only these formats are accepted:")
            logger.error("  1. https://docs.google.com/spreadsheets/d/e/ID-document/pubhtml")
            logger.error("  2. https://docs.google.com/spreadsheets/d/e/ID-document/pub?output=csv")
            logger.error("Received: \(urlString)")
            throw SheetLocalizerError.invalidGoogleSheetsURL(url: urlString)
        }
        
        let trimmedURL = urlString.trimmedContent
        
        if trimmedURL.hasSuffix("/pub?output=csv") {
            logger.debug("URL already in CSV format: \(trimmedURL)")
            return trimmedURL
        }
        
        if trimmedURL.hasSuffix("/pubhtml") {
            let transformedURL = trimmedURL.replacingOccurrences(of: "/pubhtml", with: "/pub?output=csv")
            logger.info("Transformed /pubhtml URL to /pub?output=csv format.")
            return transformedURL
        }
        
        logger.error("URL passed validation but couldn't be transformed: \(trimmedURL)")
        throw SheetLocalizerError.invalidGoogleSheetsURL(url: urlString)
    }
}

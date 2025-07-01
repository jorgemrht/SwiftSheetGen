import Foundation
import CoreExtensions
import os.log

// MARK: - Google Sheet URL Transformer

public struct GoogleSheetURLTransformer: Sendable {
  
    private static let logger = Logger.googleSheetURLTransformer

    public static func transformToCSV(_ urlString: String) -> String {
        
        guard !urlString.isEmptyOrWhitespace else {
            logger.error("Empty URL string provided")
            return urlString
        }
        
        let trimmedURL = urlString.trimmedContent
        
        if trimmedURL.contains("export?format=csv") || trimmedURL.contains("output=csv") {
            logger.debug("URL already in CSV format: \(trimmedURL)")
            return trimmedURL
        }
        
        if trimmedURL.contains("/pubhtml") {
            if trimmedURL.contains("2PACX-") {
                let transformedURL = trimmedURL.replacingOccurrences(of: "/pubhtml", with: "/pub?output=csv")
                logger.info("Transformed 2PACX /pubhtml URL: \(transformedURL)")
                return transformedURL
            } else {
                let transformedURL = trimmedURL.replacingOccurrences(of: "/pubhtml", with: "/export?format=csv")
                logger.info("Transformed regular /pubhtml URL: \(transformedURL)")
                return transformedURL
            }
        }
                
        let transformedURL = trimmedURL.hasSuffix("/")
            ? "\(trimmedURL)pub?output=csv"
            : "\(trimmedURL)/pub?output=csv"
            
        logger.info("Applied default transformation: \(transformedURL)")
        return transformedURL
    }
}

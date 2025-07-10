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
        
        // 1. Check if the URL is already in a downloadable format.
        if trimmedURL.contains("output=csv") || trimmedURL.contains("export?format=csv") {
            logger.debug("URL already in CSV format: \(trimmedURL)")
            return trimmedURL
        }
        
        // 2. Handle the most common published format: /pubhtml
        // This should be transformed to /pub?output=csv
        if trimmedURL.contains("/pubhtml") {
            let transformedURL = trimmedURL.replacingOccurrences(of: "/pubhtml", with: "/pub?output=csv")
            logger.info("Transformed /pubhtml URL to /pub?output=csv format.")
            return transformedURL
        }
                
        // 3. Default transformation for other standard sheet URLs.
        let transformedURL = trimmedURL.hasSuffix("/")
            ? "\(trimmedURL)pub?output=csv"
            : "\(trimmedURL)/pub?output=csv"
            
        logger.info("Applied default transformation to URL.")
        return transformedURL
    }
}

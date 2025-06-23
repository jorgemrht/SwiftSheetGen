import Foundation
import Extensions

// MARK: - CSV Downloader

public actor CSVDownloader {
    
    private let session: URLSession
    private let logger: Logger
    
    public init(timeoutInterval: TimeInterval = 30.0) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        config.httpAdditionalHeaders = [
            "User-Agent": "SheetLocalizer/1.0 (Swift 6.1)"
        ]
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
        self.logger = Logger(category: "CSVDownloader")
    }

    deinit {
        session.invalidateAndCancel()
        logger.debug("CSVDownloader deallocated")
    }

    public func download(from urlString: String, to outputPath: String) async throws {
        try await validateInputs(urlString: urlString, outputPath: outputPath)
        
        let transformedURL = GoogleSheetURLTransformer.transformToCSV(urlString.trimmed)
        
        guard let url = URL(string: transformedURL) else {
            logger.error("Invalid URL: \(transformedURL)")
            throw SheetLocalizerError.invalidURL(transformedURL)
        }

        logger.info("Starting download from: \(transformedURL)")

        try Task.checkCancellation()

        do {
            let (data, response) = try await session.data(from: url)
            
            try Task.checkCancellation()
            
            try await validateAndSave(data: data, response: response, outputPath: outputPath)
            
            logger.info("CSV successfully downloaded to: \(outputPath)")
            
        } catch let error as SheetLocalizerError {
            logger.error("Download failed: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Unexpected download error: \(error.localizedDescription)")
            throw SheetLocalizerError.networkError("Download failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers
    
    nonisolated private func validateInputs(urlString: String, outputPath: String) async throws {
        guard !urlString.isBlank else {
            throw SheetLocalizerError.invalidURL("URL string is empty")
        }
        
        guard !outputPath.isBlank else {
            throw SheetLocalizerError.fileSystemError("Output path is empty")
        }
    }
    
    private func validateAndSave(data: Data, response: URLResponse, outputPath: String) async throws {
        try validateResponse(response)
        try await saveData(data, to: outputPath)
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response type")
            throw SheetLocalizerError.networkError("Invalid HTTP response")
        }
        
        logger.debug("HTTP Status: \(httpResponse.statusCode)")
        
        guard 200...299 ~= httpResponse.statusCode else {
            logger.error("HTTP error: \(httpResponse.statusCode)")
            throw SheetLocalizerError.httpError(httpResponse.statusCode)
        }

        guard let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") else {
            logger.debug("No Content-Type header found")
            return
        }
        
        logger.debug("Content-Type: \(contentType)")
        
        let validContentTypes = ["text/csv", "text/plain", "application/csv"]
        let isValidContentType = validContentTypes.contains { contentType.localizedCaseInsensitiveContains($0) }
        
        if !isValidContentType {
            logger.error("Unexpected Content-Type: \(contentType)")
        }
    }

    private func saveData(_ data: Data, to outputPath: String) async throws {
        let trimmedPath = outputPath.trimmed
        let fileURL = URL(fileURLWithPath: trimmedPath)
        
        logger.debug("Attempting to save \(data.count) bytes to: \(trimmedPath)")
        
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            
            var isDirectory: ObjCBool = false
            let directoryExists = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
            
            if !directoryExists || !isDirectory.boolValue {
                try FileManager.default.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                logger.debug("Directory created: \(directoryURL.path)")
            } else {
                logger.debug("Directory already exists: \(directoryURL.path)")
            }
            
            if data.count > 10_000_000 {
                try await saveDataWithFileHandle(data, to: fileURL)
            } else {
                try data.write(to: fileURL, options: .atomic)
            }
            
            logger.debug("File written successfully: \(fileURL.path)")
            
        } catch {
            logger.error("File system error: \(error.localizedDescription)")
            throw SheetLocalizerError.fileSystemError("Error writing file: \(error.localizedDescription)")
        }
    }
    
    private func saveDataWithFileHandle(_ data: Data, to fileURL: URL) async throws {
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        defer {
            try? fileHandle.close()
        }
        
        try fileHandle.write(contentsOf: data)
        logger.debug("Large file written with FileHandle")
    }
    
    // MARK: - Additional Utility Methods
    
    nonisolated public func validateURL(_ urlString: String) async -> Bool {
        guard !urlString.isBlank else {
            return false
        }
        
        let transformedURL = GoogleSheetURLTransformer.transformToCSV(urlString.trimmed)
        
        guard let url = URL(string: transformedURL) else {
            return false
        }
        
        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10.0
            let validationSession = URLSession(configuration: config)
            defer { validationSession.invalidateAndCancel() }
            
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            
            let (_, response) = try await validationSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return 200...299 ~= httpResponse.statusCode
            }
            
            return false
            
        } catch {
            return false
        }
    }
}

// MARK: - Extensions

extension CSVDownloader {
    public func downloadWithRetry(
        from urlString: String,
        to outputPath: String,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 2.0
    ) async throws {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                try await download(from: urlString, to: outputPath)
                return
            } catch {
                lastError = error
                logger.error("Download attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    logger.info("Retrying in \(retryDelay) seconds...")
                    try await Task.sleep(for: .seconds(retryDelay))
                }
            }
        }
        
        throw lastError ?? SheetLocalizerError.networkError("All retry attempts failed")
    }
    
    nonisolated static func isValidGoogleSheetURL(_ urlString: String) -> Bool {
        return urlString.contains("docs.google.com/spreadsheets")
    }
    
    nonisolated static func createWithDefaults() -> CSVDownloader {
        return CSVDownloader(timeoutInterval: 30.0)
    }
}

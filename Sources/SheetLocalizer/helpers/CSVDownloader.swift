//
//  Created by jorge on 20/6/25.
//
import Foundation

// MARK: - CSV Downloader

public actor CSVDownloader {
    private let session: URLSession

    public init(timeoutInterval: TimeInterval = 30.0) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        config.httpAdditionalHeaders = [
            "User-Agent": "SheetLocalizer/1.0 (Swift 6.1)"
        ]
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    deinit {
        session.invalidateAndCancel()
    }

    public func download(from urlString: String, to outputPath: String) async throws {

        let transformedURL = GoogleSheetURLTransformer.transformToCSV(urlString)
      
        guard let url = URL(string: transformedURL) else {
            throw SheetLocalizerError.invalidURL(transformedURL)
        }

        print("⬇️ Downloading from: \(transformedURL)")

        try Task.checkCancellation()

        let (data, response) = try await session.data(from: url)

        try Task.checkCancellation()

        try validateResponse(response)
        try await saveData(data, to: outputPath)

        print("✔️ CSV successfully downloaded to: \(outputPath)")
    }

    // MARK: - Private Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SheetLocalizerError.networkError("Invalid HTTP response")
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw SheetLocalizerError.httpError(httpResponse.statusCode)
        }

        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           !contentType.contains("text/csv"),
           !contentType.contains("text/plain") {
            print("⚠️ Warning: Unexpected Content-Type: \(contentType)")
        }
    }

    private func saveData(_ data: Data, to outputPath: String) async throws {
        let fileURL = URL(fileURLWithPath: outputPath)
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw SheetLocalizerError.fileSystemError("Error writing file: \(error.localizedDescription)")
        }
    }
}

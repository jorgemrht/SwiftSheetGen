import Foundation
import CoreExtensions
import os.log

struct GeneratorHelper {

    static func findXcodeProjectPath(logger: Logger) throws -> String? {
        let currentDir = FileManager.default.currentDirectoryPath
        let searchPaths = [currentDir, "\(currentDir)/..", "\(currentDir)/../.."]

        for searchPath in searchPaths {
            let resolvedPath = URL(fileURLWithPath: searchPath).standardized.path
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resolvedPath)
                if let xcodeproj = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
                    logger.info("Found Xcode project: \(xcodeproj) in \(resolvedPath)")
                    return resolvedPath
                }
            } catch {
                logger.debug("Could not read directory: \(resolvedPath)")
            }
        }
        return nil
    }

    static func cleanupTemporaryFile(at path: String, logger: Logger) async throws {
        logger.info("Cleaning up temporary file: \(path, privacy: .public)")

        let fileManager = FileManager.default
        let fileURL = URL(fileURLWithPath: path)

        do {
            if fileManager.fileExists(atPath: path) {
                try fileManager.removeItem(at: fileURL)
                logger.info("Successfully deleted temporary file: \(path, privacy: .public)")
            } else {
                logger.debug("File not found, skipping cleanup: \(path, privacy: .public)")
            }
        } catch {
            logger.error("Failed to delete temporary file: \(error.localizedDescription, privacy: .public)")
        }
    }
}

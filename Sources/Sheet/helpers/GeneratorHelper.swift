import Foundation
import CoreExtensions
import os.log

struct GeneratorHelper {

    static func findXcodeProjectPath(logger: Logger) throws -> String? {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        
        var searchDir = URL(fileURLWithPath: currentDir)
        
        for _ in 0..<5 {
            if let enumerator = fileManager.enumerator(at: searchDir, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "xcodeproj" {
                        let projectPath = fileURL.deletingLastPathComponent().path
                        logger.info("Found Xcode project at: \(projectPath)")
                        return projectPath
                    }
                }
            }
            
            if searchDir.pathComponents.count > 1 {
                searchDir.deleteLastPathComponent()
            } else {
                break
            }
        }
        
        logger.warning("No valid .xcodeproj found in current directory or parent directories.")
        return nil
    }

    static func cleanupTemporaryFile(at path: String, logger: Logger) async throws {
        logger.info("Cleaning up temporary file: \(path, privacy: .public)")

        let fileManager = FileManager.default
        let fileURL = URL(fileURLWithPath: path)

        guard fileManager.fileExists(atPath: path) else {
            logger.debug("File not found, skipping cleanup: \(path, privacy: .public)")
            return
        }

        do {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    try fileManager.removeItem(at: fileURL)
                    logger.info("Successfully deleted temporary directory: \(path, privacy: .public)")
                    return
                }
            }

            if fileManager.isDeletableFile(atPath: path) {
                try fileManager.removeItem(at: fileURL)
                logger.info("Successfully deleted temporary file: \(path, privacy: .public)")
            } else {
                logger.warning("File is not deletable: \(path, privacy: .public)")
            }
        } catch CocoaError.fileWriteFileExists {
            logger.debug("File deletion conflict (file exists): \(path, privacy: .public)")
        } catch CocoaError.fileNoSuchFile {
            logger.debug("File no longer exists: \(path, privacy: .public)")
        } catch {
            logger.error("Failed to delete temporary file: \(error.localizedDescription, privacy: .public)")
        }
    }
}

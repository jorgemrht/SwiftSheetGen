import Foundation
import SheetLocalizer
import ArgumentParser
import CoreExtensions
import os.log

extension LocalizationConfig: SheetConfig {}
extension ColorConfig: SheetConfig {}

extension LocalizationGenerator: SheetGenerator {}
extension ColorGenerator: SheetGenerator {}

// MARK: - Shared Logging and Validation Extensions
extension AsyncParsableCommand {
  
    func validateGoogleSheetsURL(_ urlString: String) -> Bool {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedURL.isEmpty else { return false }
        guard let url = URL(string: trimmedURL) else { return false }
        guard url.host?.contains("docs.google.com") == true else { return false }
        guard trimmedURL.contains("spreadsheets") else { return false }
        
        return true
    }
    
    func ensureOutputDirectoryExists(atPath path: String, logger: Logger) throws {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try FileManager.default.createDirectoryIfNeeded(atPath: trimmedPath)
            logger.logInfo("📁 Output directory ready", value: trimmedPath, isPrivate: false)
        } catch {
            logger.logError("❌ Cannot create directory at", value: trimmedPath, isPrivate: false)
            throw SheetLocalizerError.fileSystemError("Cannot create directory at \(trimmedPath): \(error.localizedDescription)")
        }
    }

    func logSuccessfulExecutionCompletion(
        startTime: Date,
        generatedFilesLocation: String,
        skipXcode: Bool,
        forceUpdate: Bool,
        logPrivacyLevel: String
    ) {
        let executionDuration = Date().timeIntervalSince(startTime)
        let logger = Logger.cli // Assuming Logger.cli is accessible here

        logger.log("🎉 Generation completed successfully!")
        logger.logInfo("⏱️ Total execution time:", value: "\(String(format: "%.2f", executionDuration)) seconds")
        
        logger.logInfo("📍 Generated files location:", value: generatedFilesLocation, isPrivate: LogPrivacyLevel(from: logPrivacyLevel).isPrivate)

        if !skipXcode {
            logger.log("📱 Files have been integrated into your Xcode project")
            if forceUpdate {
                logger.log("🔄 Existing files were updated in Xcode project")
            }
        }
        
        logger.log("🚀 Your Swift project is now ready with generated files!")
    }
}

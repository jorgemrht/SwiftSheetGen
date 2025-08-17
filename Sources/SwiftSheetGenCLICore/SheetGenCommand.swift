import Foundation
import ArgumentParser
import CoreExtensions
import os.log
import SheetLocalizer

public protocol SheetGenCommand: AsyncParsableCommand {
    
    associatedtype ConfigType: SheetConfig
    associatedtype GeneratorType: SheetGenerator where GeneratorType.Config == ConfigType

    var sharedOptions: SharedOptions { get }
    var commandSpecificDirectoryName: String { get }
    
    static var logger: Logger { get }

    func createConfiguration() throws -> ConfigType
    func createGenerator(config: ConfigType) -> GeneratorType
    func logConfigurationDetailsIfVerbose(_ config: ConfigType) throws
    
    func executeCompleteWorkflow() async throws
    func downloadCSVDataFromGoogleSheets() async throws
    func generateSwiftFiles(using configuration: ConfigType) async throws
    func temporaryFileCleanupIfRequested() throws
}

// MARK: - SheetGenCommand Extension for Common Logic
public extension SheetGenCommand {
    
    var logPrivacy: LogPrivacyLevel {
        LogPrivacyLevel(from: sharedOptions.logPrivacyLevel)
    }
    
    var outputDirectory: String {
        "\(sharedOptions.outputDir.trimmingCharacters(in: .whitespacesAndNewlines))/\(commandSpecificDirectoryName)"
    }
    
    var temporaryCSVFilePath: String {
        "\(FileManager.default.currentDirectoryPath)/\(commandSpecificDirectoryName.lowercased())/generated_\(commandSpecificDirectoryName.lowercased()).csv"
    }
    
    func run() async throws {
        
        let executionStartTime = Date()
        let commandName = Self.configuration.commandName ?? ""
        
        Self.logger.log("🚀 SwiftSheetGen \(commandName) generation started")
        
        do {
            try await executeCompleteWorkflow()
            logSuccessfulExecutionCompletion(
                startTime: executionStartTime,
                generatedFilesLocation: outputDirectory,
                logPrivacyLevel: sharedOptions.logPrivacyLevel
            )
        } catch {
            Self.logger.error("💥 \(commandName.capitalized) generation workflow failed: \(error.localizedDescription)")
            throw SheetLocalizerError.networkError("Failed to generate \(commandName): \(error.localizedDescription)")
        }
    }

    func executeCompleteWorkflow() async throws {
        
        let commandName = Self.configuration.commandName ?? ""
        
        // Step 1: Validate and prepare configuration
        Self.logger.log("⚙️ Preparing \(commandName) configuration")
        let configuration = try createConfiguration()
        try logConfigurationDetailsIfVerbose(configuration)
        
        // Step 2: Download CSV data from Google Sheets
        Self.logger.logInfo("📥 Downloading CSV data from Google Sheets", value: sharedOptions.sheetsURL,  isPrivate: logPrivacy.isPrivate)
        try await downloadCSVDataFromGoogleSheets()
        
        // Step 3: Generate Swift files
        Self.logger.log("🔨 Generating Swift \(commandName) files from CSV data")
        try await generateSwiftFiles(using: configuration)
        
        // Step 4: Clean up temporary files if requested
        Self.logger.log("🧹 Cleanup operations")
        try temporaryFileCleanupIfRequested()
    }

    func downloadCSVDataFromGoogleSheets() async throws {
        Self.logger.debug("🌐 Initializing CSV downloader with default configuration")
        let csvDataDownloader = CSVDownloader()
        
        Self.logger.log("✅ Google Sheets URL validation successful")
        
        let tempDirectory = (temporaryCSVFilePath as NSString).deletingLastPathComponent
        try ensureOutputDirectoryExists(atPath: tempDirectory, logger: Self.logger)

        try await csvDataDownloader.download(
            from: sharedOptions.sheetsURL,
            to: temporaryCSVFilePath
        )
        Self.logger.log("✅ CSV data downloaded successfully to: \(temporaryCSVFilePath)")
    }

    func generateSwiftFiles(using configuration: ConfigType) async throws {
        let commandName = Self.configuration.commandName ?? ""
        Self.logger.debug("🏗️ Initializing \(commandName) generator with configuration")
        let generator = createGenerator(config: configuration)
        
        try await generator.generate(from: temporaryCSVFilePath)
        Self.logger.log("✅ Swift \(commandName) files generated successfully")
    }

    func temporaryFileCleanupIfRequested() throws {
        if sharedOptions.keepCSV {
            Self.logger.logInfo("💾 Temporary CSV file preserved at:", value: temporaryCSVFilePath, isPrivate: logPrivacy.isPrivate)
            Self.logger.debug("📄 You can review the CSV data for debugging purposes")
            return
        }
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: temporaryCSVFilePath) {
            do {
                try fileManager.removeItem(atPath: temporaryCSVFilePath)
                Self.logger.debug("🗑️ Temporary CSV file cleaned up successfully")
            } catch {
                Self.logger.logError("⚠️ Failed to clean up temporary CSV file:",  value: error.localizedDescription, isPrivate: logPrivacy.isPrivate)
            }
        } else {
            Self.logger.debug("ℹ️ No temporary CSV file found to clean up")
        }
    }
}

public extension SheetGenCommand {
    func validateAndLogGoogleSheetsURL() throws {
        guard validateGoogleSheetsURL(sharedOptions.sheetsURL) else {
            Self.logger.logError("❌ Invalid Google Sheets URL:", value: sharedOptions.sheetsURL, isPrivate: logPrivacy.isPrivate)
            throw SheetLocalizerError.invalidURL("Google Sheets URL is not valid")
        }
    }
}
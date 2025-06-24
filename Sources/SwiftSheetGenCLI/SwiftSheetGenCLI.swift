import Foundation
import SheetLocalizer
import ArgumentParser
import CoreExtensions
import os.log

// MARK: - Main CLI Command
@main
public struct SwiftSheetGenCLI: AsyncParsableCommand {
    
    private static let logger = Logger.cli

    public static let configuration = CommandConfiguration(
        commandName: "swiftsheetgen",
        abstract: "🌍 Generate Swift localization code from Google Sheets data",
        discussion: """
        SwiftSheetGen downloads CSV data from Google Sheets and generates Swift localization files
        with optional Xcode project integration and customizable output structure.
        
        📖 Examples:
          swiftsheetgen "https://docs.google.com/spreadsheets/..." --base-output-directory ./MyApp
          swiftsheetgen "sheet-url" --swift-enum-name AppLocalizations --enable-verbose-logging
          swiftsheetgen "sheet-url" --force-update-existing-localizations --enum-separate-from-localizations
        
        🔗 Google Sheets URL must be publicly accessible or have sharing permissions enabled.
        """,
        version: "1.0.0"
    )
    
    // MARK: - Command Arguments & Options with Descriptive Names
    @Argument(help: "📊 Google Sheets URL (must be publicly accessible)")
    var sheetsURL: String
    
    @Option(name: .long, help: "🏷️ Name for the generated Swift localization enum (default: L10n)")
    var swiftEnumName: String = "L10n"
    
    @Option(name: .long, help: "📁 Target directory for generated files (default: current directory)")
    var outputDir: String = "./"
    
    @Flag(help: "📝 Enable detailed logging for debugging")
    var verbose: Bool = false
    
    @Flag(name: .long, help: "⏭️ Skip automatic integration of generated files into Xcode project")
    var skipXcode: Bool = false
    
    @Flag(name: .long, help: "💾 Keep downloaded CSV file for debugging")
    var keepCSV: Bool = false
    
    @Flag(name: .long, help: "🔄 Update existing localization files in Xcode")
    var forceUpdate: Bool = false
    
    @Flag(name: .long, help: "📂 Generate Swift enum file separate from localization directories")
    var enumSeparateFromLocalizations: Bool = false
    
    private var localizationOutputDirectory: String {
        "\(outputDir.trimmingCharacters(in: .whitespacesAndNewlines))/Localizables"
    }
    
    private var temporaryCSVFilePath: String {
        "\(FileManager.default.currentDirectoryPath)/localizables/generated_localizations.csv"
    }
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Main Execution Entry Point
    public func run() async throws {
        
        let executionStartTime = Date()
        Self.logger.info("🚀 SwiftSheetGen localization generation started")
        
        do {
            try await executeCompleteLocalizationWorkflow()
            logSuccessfulExecutionCompletion(startTime: executionStartTime)
        } catch {
            Self.logger.error("💥 Localization generation workflow failed: \(error.localizedDescription)")
            throw SheetLocalizerError.networkError("Failed to generate localizations: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Main Workflow Execution
    private func executeCompleteLocalizationWorkflow() async throws {
        // Step 1: Validate and prepare configuration
        Self.logger.info("⚙️ Preparing localization configuration")
        let localizationConfiguration = try createLocalizationConfiguration()
        try logConfigurationDetailsIfVerbose(localizationConfiguration)
        
        // Step 2: Download CSV data from Google Sheets
        Self.logger.info("📥 Downloading CSV data from Google Sheets")
        try await downloadCSVDataFromGoogleSheets()
        
        // Step 3: Generate Swift localization files
        Self.logger.info("🔨 Generating Swift localization files from CSV data")
        try await generateSwiftLocalizationFiles(using: localizationConfiguration)
        
        // Step 4: Clean up temporary files if requested
        Self.logger.info("🧹 Performing cleanup operations")
        try performTemporaryFileCleanupIfRequested()
    }
    
    // MARK: - Configuration Creation
    private func createLocalizationConfiguration() throws -> LocalizationConfig {
        Self.logger.debug("🔧 Creating localization configuration with provided parameters")
        
        guard !sheetsURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SheetLocalizerError.invalidURL("Google Sheets URL cannot be empty")
        }
        
        let trimmedBaseDirectory = outputDir.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return LocalizationConfig.custom(
            outputDirectory: localizationOutputDirectory,
            enumName: swiftEnumName,
            sourceDirectory: enumSeparateFromLocalizations ? trimmedBaseDirectory : localizationOutputDirectory,
            csvFileName: "generated_localizations.csv",
            autoAddToXcode: !skipXcode,
            cleanupTemporaryFiles: !keepCSV,
            forceUpdateExistingXcodeFiles: forceUpdate,
            unifiedLocalizationDirectory: !enumSeparateFromLocalizations
        )
    }
    
    // MARK: - Configuration Logging
    private func logConfigurationDetailsIfVerbose(_ config: LocalizationConfig) throws {
        guard verbose else { return }
        
        Self.logger.debug("📋 Current Configuration Settings:")
        Self.logger.debug("  🔗 Google Sheets Source URL: \(sheetsURL)")
        Self.logger.debug("  🏷️  Swift Enum Name: \(swiftEnumName)")
        Self.logger.debug("  📁 Base Output Directory: \(outputDir)")
        Self.logger.debug("  📂 Localization Output Directory: \(config.outputDirectory)")
        Self.logger.debug("  📄 Temporary CSV File Path: \(temporaryCSVFilePath)")
        Self.logger.debug("  📱 Xcode Project Integration: \(!skipXcode)")
        Self.logger.debug("  📂 Enum Separate from Localizations: \(enumSeparateFromLocalizations)")
        Self.logger.debug("  🔄 Force Update Existing Files: \(forceUpdate)")
        Self.logger.debug("  💾 Preserve Temporary CSV: \(keepCSV)")
        Self.logger.debug("  🎯 Unified Localization Directory: \(!enumSeparateFromLocalizations)")
    }
    
    // MARK: - CSV Download Operations
    private func downloadCSVDataFromGoogleSheets() async throws {
        Self.logger.debug("🌐 Initializing CSV downloader with default configuration")
        let csvDataDownloader = CSVDownloader.createWithDefaults()
        
        // Validate URL accessibility before attempting download
        Self.logger.debug("🔍 Validating Google Sheets URL accessibility")
        let isURLAccessible = await csvDataDownloader.validateURL(sheetsURL)
        guard isURLAccessible else {
            throw SheetLocalizerError.invalidURL(
                "The provided Google Sheets URL is not accessible. Please check the URL and sharing permissions."
            )
        }
        
        Self.logger.info("✅ Google Sheets URL validation successful")
        
        // Perform CSV download with retry mechanism
        do {
            try await csvDataDownloader.downloadWithRetry(
                from: sheetsURL,
                to: temporaryCSVFilePath,
                maxRetries: 3,
                retryDelay: 2.0
            )
            Self.logger.info("✅ CSV data downloaded successfully to: \(temporaryCSVFilePath)")
        } catch {
            Self.logger.logError("❌ CSV download failed after retries", error: error)
            throw SheetLocalizerError.networkError("CSV download failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Swift File Generation
    private func generateSwiftLocalizationFiles(using configuration: LocalizationConfig) async throws {
        Self.logger.debug("🏗️ Initializing localization generator with configuration")
        let swiftLocalizationGenerator = LocalizationGenerator(config: configuration)
        
        do {
            try await swiftLocalizationGenerator.generate(from: temporaryCSVFilePath)
            Self.logger.info("✅ Swift localization files generated successfully")
            
            if !skipXcode {
                Self.logger.info("📱 Localization files integrated into Xcode project")
            }
        } catch {
            Self.logger.logError("❌ Swift localization generation failed", error: error)
            throw SheetLocalizerError.localizationGenerationError("Localization generation failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup Operations
    private func performTemporaryFileCleanupIfRequested() throws {
        if keepCSV {
            Self.logger.info("💾 Temporary CSV file preserved at: \(temporaryCSVFilePath)")
            Self.logger.debug("📄 You can review the CSV data for debugging purposes")
            return
        }
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: temporaryCSVFilePath) {
            do {
                try fileManager.removeItem(atPath: temporaryCSVFilePath)
                Self.logger.debug("🗑️ Temporary CSV file cleaned up successfully")
            } catch {
                Self.logger.logError("⚠️ Failed to clean up temporary CSV file", error: error)
            }
        } else {
            Self.logger.debug("ℹ️ No temporary CSV file found to clean up")
        }
    }
    
    // MARK: - Success Logging
    private func logSuccessfulExecutionCompletion(startTime: Date) {
        let executionDuration = Date().timeIntervalSince(startTime)
        
        Self.logger.info("🎉 Localization generation completed successfully!")
        Self.logger.info("⏱️ Total execution time: \(String(format: "%.2f", executionDuration)) seconds")
        
        // Provide helpful information about what was accomplished
        Self.logger.info("📍 Generated files location: \(localizationOutputDirectory)")
        
        if !skipXcode {
            Self.logger.info("📱 Localization files have been integrated into your Xcode project")
            
            if forceUpdate {
                Self.logger.info("🔄 Existing localization files were updated in Xcode project")
            }
        }
        
        if enumSeparateFromLocalizations {
            Self.logger.info("📂 Swift enum file generated separately from localization directories")
        }
        
        if keepCSV {
            Self.logger.info("💾 CSV file preserved for debugging: \(temporaryCSVFilePath)")
        }
        
        // Provide next steps guidance
        Self.logger.info("🚀 Your Swift project is now ready with generated localizations!")
        
        if verbose {
            Self.logger.debug("💡 Tip: You can now use \(swiftEnumName) enum in your Swift code for type-safe localizations")
        }
    }
}

// MARK: - Validation Extensions
extension SwiftSheetGenCLI {
    /// Validates that the provided Google Sheets URL appears to be valid
    private func validateGoogleSheetsURL(_ urlString: String) -> Bool {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedURL.isEmpty else { return false }
        guard let url = URL(string: trimmedURL) else { return false }
        guard url.host?.contains("docs.google.com") == true else { return false }
        guard trimmedURL.contains("spreadsheets") else { return false }
        
        return true
    }
    
    /// Creates output directory if it doesn't exist
    private func ensureOutputDirectoryExists() throws {
        let fileManager = FileManager.default
        let trimmedPath = outputDir.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var isDirectory: ObjCBool = false
        let directoryExists = fileManager.fileExists(atPath: trimmedPath, isDirectory: &isDirectory)
        
        if !directoryExists || !isDirectory.boolValue {
            do {
                try fileManager.createDirectory(
                    atPath: trimmedPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                Self.logger.debug("📁 Created output directory: \(trimmedPath)")
            } catch {
                throw SheetLocalizerError.fileSystemError(
                    "Cannot create directory at \(trimmedPath): \(error.localizedDescription)"
                )
            }
        }
    }
}

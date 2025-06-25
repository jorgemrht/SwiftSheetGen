import Foundation
import SheetLocalizer
import ArgumentParser
import CoreExtensions
import os.log

// MARK: - Main CLI Command
@main
public struct SwiftSheetGenCLI: AsyncParsableCommand {
    
    private static let logger = Logger.cli

    private var logPrivacy: LogPrivacyLevel {
        LogPrivacyLevel(from: logPrivacyLevel)
    }

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
    
    @Flag(name: [.customShort("v"), .long], help: "📝 Enable detailed logging for debugging")
    var verbose: Bool = false
    
    @Flag(name: .long, help: "⏭️ Skip automatic integration of generated files into Xcode project")
    var skipXcode: Bool = false
    
    @Flag(name: [.customShort("k"), .long], help: "💾 Keep downloaded CSV file for debugging")
    var keepCSV: Bool = false
    
    @Flag(name: .long, help: "🔄 Update existing localization files in Xcode")
    var forceUpdate: Bool = false
    
    @Flag(name: .long, help: "📂 Generate Swift enum file separate from localization directories")
    var enumSeparateFromLocalizations: Bool = false

    @Option(name: .long, help: "Privacy level for log output: public (default) or private")
    var logPrivacyLevel: String = "public"

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
        Self.logger.log("🚀 SwiftSheetGen localization generation started")
        
        do {
            try await executeCompleteLocalizationWorkflow()
            logSuccessfulExecutionCompletion(startTime: executionStartTime)
        } catch {
            Self.logger.error("💥 Localization generation workflow failed: \(error.localizedDescription)") // TODO: Check the log
            throw SheetLocalizerError.networkError("Failed to generate localizations: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Main Workflow Execution
    private func executeCompleteLocalizationWorkflow() async throws {
        // Step 1: Validate and prepare configuration
        Self.logger.log("⚙️ Preparing localization configuration")
        let localizationConfiguration = try createLocalizationConfiguration()
        try logConfigurationDetailsIfVerbose(localizationConfiguration)
        
        // Step 2: Download CSV data from Google Sheets
        Self.logger.logInfo("📥 Downloading CSV data from Google Sheets", value: sheetsURL,  isPrivate: logPrivacy.isPrivate)
        try await downloadCSVDataFromGoogleSheets()
        
        // Step 3: Generate Swift localization files
        Self.logger.log("🔨 Generating Swift localization files from CSV data")
        try await generateSwiftLocalizationFiles(using: localizationConfiguration)
        
        // Step 4: Clean up temporary files if requested
        Self.logger.log("🧹 Performing cleanup operations")
        try performTemporaryFileCleanupIfRequested()
    }
    
    // MARK: - Configuration Creation
    private func createLocalizationConfiguration() throws -> LocalizationConfig {
        Self.logger.debug("🔧 Creating localization configuration with provided parameters")
        
        guard validateGoogleSheetsURL(sheetsURL) else {
            Self.logger.logError("❌ Invalid Google Sheets URL:", value: sheetsURL, isPrivate: logPrivacy.isPrivate)
            throw SheetLocalizerError.invalidURL("Google Sheets URL is not valid")
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
        
        Self.logger.log("✅ Google Sheets URL validation successful")
        
        // Perform CSV download with retry mechanism
        do {
            try await csvDataDownloader.downloadWithRetry(
                from: sheetsURL,
                to: temporaryCSVFilePath,
                maxRetries: 3,
                retryDelay: 2.0
            )
            Self.logger.log("✅ CSV data downloaded successfully to: \(temporaryCSVFilePath)") // TODO: Check the log
        } catch {
            Self.logger.logFatal("❌ CSV download failed after retries", error: error) // TODO: Check the log
        }
    }
    
    // MARK: - Swift File Generation
    private func generateSwiftLocalizationFiles(using configuration: LocalizationConfig) async throws {
        Self.logger.debug("🏗️ Initializing localization generator with configuration")
        let swiftLocalizationGenerator = LocalizationGenerator(config: configuration)
        
        do {
            try await swiftLocalizationGenerator.generate(from: temporaryCSVFilePath)
            Self.logger.log("✅ Swift localization files generated successfully")
            
            if !skipXcode {
                Self.logger.log("📱 Localization files integrated into Xcode project")
            }
        } catch {
            Self.logger.logFatal("❌ Swift localization generation failed", error: error) // TODO: Check the log
        }
    }
    
    // MARK: - Cleanup Operations
    private func performTemporaryFileCleanupIfRequested() throws {
        if keepCSV {
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
    
    // MARK: - Success Logging
    private func logSuccessfulExecutionCompletion(startTime: Date) {
        let executionDuration = Date().timeIntervalSince(startTime)
        
        Self.logger.log("🎉 Localization generation completed successfully!")
        Self.logger.logInfo("⏱️ Total execution time:", value: "\(String(format: "%.2f", executionDuration)) seconds") // TODO: Check the log
        
        // Provide helpful information about what was accomplished
        Self.logger.logInfo("📍 Generated files location:", value: localizationOutputDirectory, isPrivate: logPrivacy.isPrivate)
        
        if !skipXcode {
            Self.logger.log("📱 Localization files have been integrated into your Xcode project")
            
            if forceUpdate {
                Self.logger.log("🔄 Existing localization files were updated in Xcode project")
            }
        }
        
        if enumSeparateFromLocalizations {
            Self.logger.log("📂 Swift enum file generated separately from localization directories")
        }
        
        if keepCSV {
            Self.logger.logInfo("💾 CSV file preserved for debugging:", value: temporaryCSVFilePath, isPrivate: logPrivacy.isPrivate)
        }
        
        // Provide next steps guidance
        Self.logger.log("🚀 Your Swift project is now ready with generated localizations!")
        
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
        let trimmedPath = outputDir.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try FileManager.default.createDirectoryIfNeeded(atPath: trimmedPath)
            Self.logger.logInfo("📁 Output directory ready", value: trimmedPath, isPrivate: logPrivacy.isPrivate)
        } catch {
            Self.logger.logError("❌ Cannot create directory at", value: trimmedPath, isPrivate: logPrivacy.isPrivate)
            throw SheetLocalizerError.fileSystemError("Cannot create directory at \(trimmedPath): \(error.localizedDescription)")
        }
    }
}

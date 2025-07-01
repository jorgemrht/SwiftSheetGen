import Foundation
import SheetLocalizer
import ArgumentParser
import CoreExtensions
import os.log

// MARK: - Main CLI Command
@main

public struct SwiftSheetGenCLI: AsyncParsableCommand {
    
    public static let configuration = CommandConfiguration(
        commandName: "swiftsheetgen",
        abstract: "A command-line tool to generate Swift code from Google Sheets data.",
        subcommands: [LocalizationCommand.self, ColorsCommand.self]
    )

    public init() {}

    public func run() async throws {
        print("Please specify a subcommand: 'localization' or 'colors'.")
        throw ExitCode.validationFailure
    }
}


// MARK: - Localization Command
public struct LocalizationCommand: AsyncParsableCommand {
    
    public static let configuration = CommandConfiguration(
        commandName: "localization",
        abstract: "Generate Swift localization code from Google Sheets data"
    )

    private static let logger = Logger.cli
    
    @OptionGroup var sharedOptions: SharedOptions

    @Option(name: .long, help: "🏷️ Name for the generated Swift localization enum (default: L10n)")
    var swiftEnumName: String = "L10n"
    
    @Flag(name: .long, help: "📂 Generate Swift enum file separate from localization directories")
    var enumSeparateFromLocalizations: Bool = false

    private var logPrivacy: LogPrivacyLevel {
        LogPrivacyLevel(from: sharedOptions.logPrivacyLevel)
    }
    
    private var localizationOutputDirectory: String {
        "\(sharedOptions.outputDir.trimmingCharacters(in: .whitespacesAndNewlines))/Localizables"
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
            logSuccessfulExecutionCompletion(
                startTime: executionStartTime,
                generatedFilesLocation: localizationOutputDirectory,
                skipXcode: sharedOptions.skipXcode,
                forceUpdate: sharedOptions.forceUpdate,
                logPrivacyLevel: sharedOptions.logPrivacyLevel
            )
        } catch {
            Self.logger.error("💥 Localization generation workflow failed: \(error.localizedDescription)")
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
        Self.logger.logInfo("📥 Downloading CSV data from Google Sheets", value: sharedOptions.sheetsURL,  isPrivate: logPrivacy.isPrivate)
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
        
        guard validateGoogleSheetsURL(sharedOptions.sheetsURL) else {
            Self.logger.logError("❌ Invalid Google Sheets URL:", value: sharedOptions.sheetsURL, isPrivate: logPrivacy.isPrivate)
            throw SheetLocalizerError.invalidURL("Google Sheets URL is not valid")
        }
        
        let trimmedBaseDirectory = sharedOptions.outputDir.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return LocalizationConfig.custom(
            outputDirectory: localizationOutputDirectory,
            enumName: swiftEnumName,
            sourceDirectory: enumSeparateFromLocalizations ? trimmedBaseDirectory : localizationOutputDirectory,
            csvFileName: "generated_localizations.csv",
            autoAddToXcode: !sharedOptions.skipXcode,
            cleanupTemporaryFiles: !sharedOptions.keepCSV,
            forceUpdateExistingXcodeFiles: sharedOptions.forceUpdate,
            unifiedLocalizationDirectory: !enumSeparateFromLocalizations
        )
    }
    
    // MARK: - Configuration Logging
    private func logConfigurationDetailsIfVerbose(_ config: LocalizationConfig) throws {
        guard sharedOptions.verbose else { return }
        
        Self.logger.debug("📋 Current Configuration Settings:")
        Self.logger.debug("  🔗 Google Sheets Source URL: \(sharedOptions.sheetsURL)")
        Self.logger.debug("  🏷️  Swift Enum Name: \(swiftEnumName)")
        Self.logger.debug("  📁 Base Output Directory: \(sharedOptions.outputDir)")
        Self.logger.debug("  📂 Localization Output Directory: \(config.outputDirectory)")
        Self.logger.debug("  📄 Temporary CSV File Path: \(temporaryCSVFilePath)")
        Self.logger.debug("  📱 Xcode Project Integration: \(!sharedOptions.skipXcode)")
        Self.logger.debug("  📂 Enum Separate from Localizations: \(enumSeparateFromLocalizations)")
        Self.logger.debug("  🔄 Force Update Existing Files: \(sharedOptions.forceUpdate)")
        Self.logger.debug("  💾 Preserve Temporary CSV: \(sharedOptions.keepCSV)")
        Self.logger.debug("  🎯 Unified Localization Directory: \(!enumSeparateFromLocalizations)")
    }
    
    // MARK: - CSV Download Operations
    private func downloadCSVDataFromGoogleSheets() async throws {
        Self.logger.debug("🌐 Initializing CSV downloader with default configuration")
        let csvDataDownloader = CSVDownloader.createWithDefaults()
        
        // Validate URL accessibility before attempting download
        Self.logger.debug("🔍 Validating Google Sheets URL accessibility")
        let isURLAccessible = await csvDataDownloader.validateURL(sharedOptions.sheetsURL)
        guard isURLAccessible else {
            throw SheetLocalizerError.invalidURL(
                "The provided Google Sheets URL is not accessible. Please check the URL and sharing permissions."
            )
        }
        
        Self.logger.log("✅ Google Sheets URL validation successful")
        
        do {
            try await csvDataDownloader.downloadWithRetry(
                from: sharedOptions.sheetsURL,
                to: temporaryCSVFilePath,
                maxRetries: 3,
                retryDelay: 2.0
            )
            Self.logger.log("✅ CSV data downloaded successfully to: \(temporaryCSVFilePath)")
        } catch {
            Self.logger.logFatal("❌ CSV download failed after retries", error: error)
        }
    }
    
    // MARK: - Swift File Generation
    private func generateSwiftLocalizationFiles(using configuration: LocalizationConfig) async throws {
        Self.logger.debug("🏗️ Initializing localization generator with configuration")
        let swiftLocalizationGenerator = LocalizationGenerator(config: configuration)
        
        do {
            try await swiftLocalizationGenerator.generate(from: temporaryCSVFilePath)
            Self.logger.log("✅ Swift localization files generated successfully")
            
            if !sharedOptions.skipXcode {
                Self.logger.log("📱 Localization files integrated into Xcode project")
            }
        } catch {
            Self.logger.logFatal("❌ Swift localization generation failed", error: error)
        }
    }
    
    // MARK: - Cleanup Operations
    private func performTemporaryFileCleanupIfRequested() throws {
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


// MARK: - Colors Command
public struct ColorsCommand: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "colors",
        abstract: "Generate Swift color assets from Google Sheets data"
    )

    private static let logger = Logger.cli

    @OptionGroup var sharedOptions: SharedOptions

    private var logPrivacy: LogPrivacyLevel {
        LogPrivacyLevel(from: sharedOptions.logPrivacyLevel)
    }

    private var colorsOutputDirectory: String {
        "\(sharedOptions.outputDir.trimmingCharacters(in: .whitespacesAndNewlines))/Colors"
    }

    private var temporaryCSVFilePath: String {
        "\(FileManager.default.currentDirectoryPath)/colors/generated_colors.csv"
    }

    // MARK: - Initialization
    public init() {}

    // MARK: - Main Execution Entry Point
    public func run() async throws {

        let executionStartTime = Date()
        
        Self.logger.log("🚀 SwiftSheetGen color generation started")

        do {
            try await executeCompleteColorWorkflow()
            logSuccessfulExecutionCompletion(
                startTime: executionStartTime,
                generatedFilesLocation: colorsOutputDirectory,
                skipXcode: sharedOptions.skipXcode,
                forceUpdate: sharedOptions.forceUpdate,
                logPrivacyLevel: sharedOptions.logPrivacyLevel
            )
        } catch {
            Self.logger.error("💥 Color generation workflow failed: \(error.localizedDescription)")
            throw SheetLocalizerError.networkError("Failed to generate colors: \(error.localizedDescription)")
        }
    }

    // MARK: - Main Workflow Execution
    private func executeCompleteColorWorkflow() async throws {
        // Step 1: Validate and prepare configuration
        Self.logger.log("⚙️ Preparing color configuration")
        let colorConfiguration = try createColorConfiguration()
        try logConfigurationDetailsIfVerbose(colorConfiguration)

        // Step 2: Download CSV data from Google Sheets
        Self.logger.logInfo("📥 Downloading CSV data from Google Sheets", value: sharedOptions.sheetsURL,  isPrivate: logPrivacy.isPrivate)
        try await downloadCSVDataFromGoogleSheets()

        // Step 3: Generate Swift color files
        Self.logger.log("🔨 Generating Swift color files from CSV data")
        try await generateSwiftColorFiles(using: colorConfiguration)

        // Step 4: Clean up temporary files if requested
        Self.logger.log("🧹 Performing cleanup operations")
        try performTemporaryFileCleanupIfRequested()
    }

    // MARK: - Configuration Creation
    private func createColorConfiguration() throws -> ColorConfig {
        Self.logger.debug("🔧 Creating color configuration with provided parameters")

        guard validateGoogleSheetsURL(sharedOptions.sheetsURL) else {
            Self.logger.logError("❌ Invalid Google Sheets URL:", value: sharedOptions.sheetsURL, isPrivate: logPrivacy.isPrivate)
            throw SheetLocalizerError.invalidURL("Google Sheets URL is not valid")
        }

        return ColorConfig.custom(
            outputDirectory: colorsOutputDirectory,
            csvFileName: "generated_colors.csv",
            autoAddToXcode: !sharedOptions.skipXcode,
            cleanupTemporaryFiles: !sharedOptions.keepCSV,
            forceUpdateExistingXcodeFiles: sharedOptions.forceUpdate
        )
    }

    // MARK: - Configuration Logging
    private func logConfigurationDetailsIfVerbose(_ config: ColorConfig) throws {
        guard sharedOptions.verbose else { return }

        Self.logger.debug("📋 Current Configuration Settings:")
        Self.logger.debug("  🔗 Google Sheets Source URL: \(sharedOptions.sheetsURL)")
        Self.logger.debug("  📁 Base Output Directory: \(sharedOptions.outputDir)")
        Self.logger.debug("  📂 Colors Output Directory: \(config.outputDirectory)")
        Self.logger.debug("  📄 Temporary CSV File Path: \(temporaryCSVFilePath)")
        Self.logger.debug("  📱 Xcode Project Integration: \(!sharedOptions.skipXcode)")
        Self.logger.debug("  🔄 Force Update Existing Files: \(sharedOptions.forceUpdate)")
        Self.logger.debug("  💾 Preserve Temporary CSV: \(sharedOptions.keepCSV)")
    }

    // MARK: - CSV Download Operations
    private func downloadCSVDataFromGoogleSheets() async throws {
        Self.logger.debug("🌐 Initializing CSV downloader with default configuration")
        let csvDataDownloader = CSVDownloader.createWithDefaults()

        // Validate URL accessibility before attempting download
        Self.logger.debug("🔍 Validating Google Sheets URL accessibility")
        let isURLAccessible = await csvDataDownloader.validateURL(sharedOptions.sheetsURL)
        guard isURLAccessible else {
            throw SheetLocalizerError.invalidURL(
                "The provided Google Sheets URL is not accessible. Please check the URL and sharing permissions."
            )
        }

        Self.logger.log("✅ Google Sheets URL validation successful")

        do {
            try await csvDataDownloader.downloadWithRetry(
                from: sharedOptions.sheetsURL,
                to: temporaryCSVFilePath,
                maxRetries: 3,
                retryDelay: 2.0
            )
            Self.logger.log("✅ CSV data downloaded successfully to: \(temporaryCSVFilePath)")
        } catch {
            Self.logger.logFatal("❌ CSV download failed after retries", error: error)
        }
    }

    // MARK: - Swift File Generation
    private func generateSwiftColorFiles(using configuration: ColorConfig) async throws {
        Self.logger.debug("🏗️ Initializing color generator with configuration")
        let swiftColorGenerator = ColorGenerator(config: configuration)

        do {
            try await swiftColorGenerator.generate(from: temporaryCSVFilePath)
            Self.logger.log("✅ Swift color files generated successfully")

            if !sharedOptions.skipXcode {
                Self.logger.log("📱 Color files integrated into Xcode project")
            }
        } catch {
            Self.logger.logFatal("❌ Swift color generation failed", error: error)
        }
    }

    // MARK: - Cleanup Operations
    private func performTemporaryFileCleanupIfRequested() throws {
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
    
    /// Creates output directory if it doesn't exist
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

    /// Logs successful execution completion details.
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





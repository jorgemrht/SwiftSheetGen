import Foundation
import SheetLocalizer
import ArgumentParser
import CoreExtensions
import os.log

// MARK: - Localization Command
public struct LocalizationCommand: AsyncParsableCommand, SheetGenCommand {
    
    public typealias ConfigType = LocalizationConfig
    public typealias GeneratorType = LocalizationGenerator
    
    public static let configuration = CommandConfiguration(
        commandName: "localization",
        abstract: "Generate Swift localization code from Google Sheets data"
    )
    
    public var commandSpecificDirectoryName: String { "Localizables" }

    public static let logger = Logger.cli
    
    @OptionGroup public var sharedOptions: SharedOptions

    @Option(name: .long, help: "🏷️ Name for the generated Swift localization enum (default: L10n)")
    public var swiftEnumName: String = "L10n"
    
    @Flag(name: .long, help: "📂 Generate Swift enum file separate from localization directories")
    public var enumSeparateFromLocalizations: Bool = false

    @Flag(name: .long, help: "📦 Use modern Xcode Strings Catalog (.xcstrings) for localization")
    public var useStringsCatalog: Bool = false

    public init() {}
    
    public func createConfiguration() throws -> LocalizationConfig {
        Self.logger.debug("Creating localization configuration with provided parameters")
        
        try validateAndLogGoogleSheetsURL()
        
        let trimmedBaseDirectory = sharedOptions.outputDir.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return LocalizationConfig.custom(
            outputDirectory: outputDirectory,
            enumName: swiftEnumName,
            sourceDirectory: enumSeparateFromLocalizations ? trimmedBaseDirectory : outputDirectory,
            csvFileName: "generated_localizations.csv",
            cleanupTemporaryFiles: !sharedOptions.keepCSV,
            unifiedLocalizationDirectory: !enumSeparateFromLocalizations,
            useStringsCatalog: useStringsCatalog
        )
    }

    public func createGenerator(config: LocalizationConfig) -> LocalizationGenerator {
        LocalizationGenerator(config: config)
    }
    
    public func logConfigurationDetailsIfVerbose(_ config: LocalizationConfig) throws {
        guard sharedOptions.verbose else { return }
        
        Self.logger.debug("📋 Current Configuration Settings:")
        Self.logger.debug("  🔗 Google Sheets Source URL: \(sharedOptions.sheetsURL)")
        Self.logger.debug("  🏷️  Swift Enum Name: \(swiftEnumName)")
        Self.logger.debug("  📁 Base Output Directory: \(sharedOptions.outputDir)")
        Self.logger.debug("  📂 Localization Output Directory: \(config.outputDirectory)")
        Self.logger.debug("  📄 Temporary CSV File Path: \(temporaryCSVFilePath)")
        Self.logger.debug("  📂 Enum Separate from Localizations: \(enumSeparateFromLocalizations)")
        Self.logger.debug("  💾 Preserve Temporary CSV: \(sharedOptions.keepCSV)")
        Self.logger.debug("  🎯 Unified Localization Directory: \(!enumSeparateFromLocalizations)")
    }
}

// MARK: - Colors Command
public struct ColorsCommand: AsyncParsableCommand, SheetGenCommand {
    
    public typealias ConfigType = ColorConfig
    public typealias GeneratorType = ColorGenerator

    public static let configuration = CommandConfiguration(
        commandName: "colors",
        abstract: "Generate Swift color assets from Google Sheets data"
    )

    public var commandSpecificDirectoryName: String { "Colors" }

    public static let logger = Logger.cli

    @OptionGroup public var sharedOptions: SharedOptions

    public init() {}

    public func createConfiguration() throws -> ColorConfig {
        
        Self.logger.debug("Creating color configuration with provided parameters")

        try validateAndLogGoogleSheetsURL()

        return ColorConfig.custom(
            outputDirectory: outputDirectory,
            csvFileName: "generated_colors.csv",
            cleanupTemporaryFiles: !sharedOptions.keepCSV
        )
    }

    public func createGenerator(config: ColorConfig) -> ColorGenerator {
        ColorGenerator(config: config)
    }
    
    public func logConfigurationDetailsIfVerbose(_ config: ColorConfig) throws {
        guard sharedOptions.verbose else { return }

        Self.logger.debug("📋 Current Configuration Settings:")
        Self.logger.debug("  🔗 Google Sheets Source URL: \(sharedOptions.sheetsURL)")
        Self.logger.debug("  📁 Base Output Directory: \(sharedOptions.outputDir)")
        Self.logger.debug("  📂 Colors Output Directory: \(config.outputDirectory)")
        Self.logger.debug("  📄 Temporary CSV File Path: \(temporaryCSVFilePath)")
        Self.logger.debug("  💾 Preserve Temporary CSV: \(sharedOptions.keepCSV)")
    }
}
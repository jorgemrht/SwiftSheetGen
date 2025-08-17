import Testing
import Foundation
import ArgumentParser
import os.log
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer
@testable import CoreExtensions

@Suite
struct CLITests {
    
    // MARK: - Main CLI Configuration Tests
    
    @Test("CLI Commands are properly configured and accessible")
    func cliCommandsConfigurationValidation() {
        
        let locConfig = LocalizationCommand.configuration
        #expect(locConfig.commandName == "localization", "Localization command name should be correct")
        #expect(locConfig.abstract == "Generate Swift localization code from Google Sheets data", "Abstract should describe localization")
        
       
        let colorConfig = ColorsCommand.configuration
        #expect(colorConfig.commandName == "colors", "Colors command name should be correct")
        #expect(colorConfig.abstract == "Generate Swift color assets from Google Sheets data", "Abstract should describe color generation")
    }
    
    // MARK: - LocalizationCommand Tests
    
    @Test("LocalizationCommand configuration validates correctly")
    func localizationCommandConfigurationValidation() {
        let config = LocalizationCommand.configuration
        
        #expect(config.commandName == "localization", "Command name should be localization")
        #expect(config.abstract == "Generate Swift localization code from Google Sheets data", "Abstract should describe localization generation")
    }
    
    @Test("LocalizationCommand creates proper configuration with default parameters")
    func localizationCommandDefaultConfigurationCreation() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        
        #expect(config.enumName == "L10n", "Default enum name should be L10n")
        #expect(config.csvFileName == "generated_localizations.csv", "CSV filename should be generated_localizations.csv")
        #expect(config.cleanupTemporaryFiles == true, "Should cleanup temporary files by default")
        #expect(config.outputDirectory.contains("Localizables"), "Output directory should contain Localizables")
        #expect(config.unifiedLocalizationDirectory == true, "Should use unified localization directory by default")
        #expect(config.useStringsCatalog == false, "Should not use strings catalog by default")
    }
    
    @Test("LocalizationCommand handles custom configurations",
          arguments: [
              (enumName: "CustomL10n", separate: false, stringsCatalog: false, keepCSV: false),
              (enumName: "SeparateEnum", separate: true, stringsCatalog: false, keepCSV: true),
              (enumName: "ModernEnum", separate: false, stringsCatalog: true, keepCSV: false),
              (enumName: "ComplexEnum", separate: true, stringsCatalog: true, keepCSV: true)
          ])
    func localizationCommandCustomConfigurations(enumName: String, separate: Bool, stringsCatalog: Bool, keepCSV: Bool) throws {
        var args = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output",
            "--swift-enum-name", enumName
        ]
        
        if separate {
            args.append("--enum-separate-from-localizations")
        }
        if stringsCatalog {
            args.append("--use-strings-catalog")
        }
        if keepCSV {
            args.append("--keep-csv")
        }
        
        let command = try LocalizationCommand.parse(args)
        let config = try command.createConfiguration()
        
        #expect(config.enumName == enumName, "Enum name should match")
        #expect(config.unifiedLocalizationDirectory != separate, "Unified directory should be opposite of separation")
        #expect(config.useStringsCatalog == stringsCatalog, "Strings catalog setting should match")
        #expect(config.cleanupTemporaryFiles != keepCSV, "Cleanup should be opposite of keep CSV")
    }
    
    @Test("LocalizationCommand conforms to SheetGenCommand protocol")
    func localizationCommandProtocolConformance() throws {
        let command = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        
        #expect(String(describing: LocalizationCommand.logger).contains("Logger"), "Should have logger configured")
    }
    
    @Test("LocalizationCommand creates appropriate generator instance")
    func localizationCommandGeneratorCreation() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        let generator = command.createGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "LocalizationGenerator", "Should create LocalizationGenerator instance")
    }
    
    // MARK: - ColorsCommand Tests
    
    @Test("ColorsCommand configuration validates correctly")
    func colorsCommandConfigurationValidation() {
        let config = ColorsCommand.configuration
        
        #expect(config.commandName == "colors", "Command name should be colors")
        #expect(config.abstract == "Generate Swift color assets from Google Sheets data", "Abstract should describe color generation")
    }
    
    @Test("ColorsCommand creates proper configuration with default parameters")
    func colorsCommandDefaultConfigurationCreation() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        
        #expect(config.csvFileName == "generated_colors.csv", "CSV filename should be generated_colors.csv")
        #expect(config.cleanupTemporaryFiles == true, "Should cleanup temporary files by default")
        #expect(config.outputDirectory.contains("Colors"), "Output directory should contain Colors")
    }
    
    @Test("ColorsCommand conforms to SheetGenCommand protocol")
    func colorsCommandProtocolConformance() throws {
        let command = try ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        
        #expect(command.commandSpecificDirectoryName == "Colors", "Should provide correct directory name")
        #expect(String(describing: ColorsCommand.logger).contains("Logger"), "Should have logger configured")
    }
    
    @Test("ColorsCommand creates appropriate generator instance")
    func colorsCommandGeneratorCreation() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        let generator = command.createGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "ColorGenerator", "Should create ColorGenerator instance")
    }
    
    // MARK: - URL Validation Tests
    
    @Test("Commands validate complex configuration scenarios")
    func commandsComplexConfigurationValidation() throws {
        let complexArgs = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/complex/test",
            "--verbose", "--keep-csv",
            "--swift-enum-name", "ComplexEnum",
            "--enum-separate-from-localizations",
            "--use-strings-catalog"
        ]
        
        let command = try LocalizationCommand.parse(complexArgs)
        let config = try command.createConfiguration()
        
        #expect(config.enumName == "ComplexEnum")
        #expect(config.useStringsCatalog == true)
        #expect(config.unifiedLocalizationDirectory == false)
        #expect(config.cleanupTemporaryFiles == false)
    }
    
    // MARK: - Computed Properties Tests
    
    @Test("Commands compute log privacy level correctly",
          arguments: [
              ("public", false),
              ("private", true),
              ("Public", false),
              ("PRIVATE", true),
              ("invalid", false)
          ])
    func commandsLogPrivacyLevelComputation(inputLevel: String, expectedIsPrivate: Bool) throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--log-privacy-level", inputLevel
        ])
        
        let logPrivacy = command.logPrivacy
        
        #expect(logPrivacy.isPrivate == expectedIsPrivate, "Privacy level should be computed correctly for '\(inputLevel)'")
        #expect(logPrivacy.isPublic != expectedIsPrivate, "Public should be opposite of private")
    }
    
    @Test("Commands compute output directory correctly")
    func commandsOutputDirectoryComputation() throws {
        let testCases: [(baseDir: String, expected: String)] = [
            ("./", ".//Localizables"),
            ("/absolute/path", "/absolute/path/Localizables"),
            ("relative/path", "relative/path/Localizables"),
            ("  /path/with/spaces  ", "/path/with/spaces/Localizables")
        ]
        
        for testCase in testCases {
            let command = try LocalizationCommand.parse([
                "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
                "--output-dir", testCase.baseDir
            ])
            
            let outputDir = command.outputDirectory
            
            #expect(outputDir == testCase.expected, "Output directory should be computed correctly")
        }
    }
    
    @Test("Commands compute temporary CSV file path correctly")
    func commandsTemporaryCSVFilePathComputation() throws {
        let command = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        let tempPath = command.temporaryCSVFilePath
        
        #expect(tempPath.contains("localizables"), "Temp path should contain lowercased command directory")
        #expect(tempPath.contains("generated_localizables.csv"), "Temp path should contain generated CSV filename")
        #expect(tempPath.hasPrefix(FileManager.default.currentDirectoryPath), "Temp path should start with current directory")
    }
    
    // MARK: - Logging Tests
    
    @Test("Commands handle verbose configuration logging")
    func commandsVerboseConfigurationLogging() throws {
        let locCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output",
            "--verbose",
            "--swift-enum-name", "TestEnum",
            "--enum-separate-from-localizations"
        ])
        let locConfig = try locCommand.createConfiguration()
        
        let colorCommand = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output",
            "--verbose"
        ])
        let colorConfig = try colorCommand.createConfiguration()
        
        // Test that verbose logging method can be called without errors
        #expect(throws: Never.self) {
            try locCommand.logConfigurationDetailsIfVerbose(locConfig)
            try colorCommand.logConfigurationDetailsIfVerbose(colorConfig)
        }
    }
    
    @Test("Commands handle non-verbose mode gracefully")
    func commandsNonVerboseModeHandling() throws {
        let locCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let colorCommand = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        
        let locConfig = try locCommand.createConfiguration()
        let colorConfig = try colorCommand.createConfiguration()
        
        // Should not throw errors when verbose is false
        #expect(throws: Never.self) {
            try locCommand.logConfigurationDetailsIfVerbose(locConfig)
            try colorCommand.logConfigurationDetailsIfVerbose(colorConfig)
        }
    }
    
    @Test("Commands log successful execution completion properly")
    func commandsSuccessfulExecutionLogging() throws {
        let startTime = Date()
        let generatedLocation = "/test/output/generated"
        let logPrivacyLevel = "public"
        
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--log-privacy-level", logPrivacyLevel
        ])
        
        // This should not throw any errors
        #expect(throws: Never.self) {
            command.logSuccessfulExecutionCompletion(
                startTime: startTime,
                generatedFilesLocation: generatedLocation,
                logPrivacyLevel: logPrivacyLevel
            )
        }
    }
    
    // MARK: - Directory Management Tests
    
    @Test("Commands ensure output directory exists")
    func commandsOutputDirectoryCreation() async throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let testOutputDir = tempDir.appendingPathComponent("test_output").path
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", testOutputDir
        ])
        
        #expect(throws: Never.self) {
            try command.ensureOutputDirectoryExists(atPath: testOutputDir, logger: LocalizationCommand.logger)
        }
        
        #expect(FileManager.default.fileExists(atPath: testOutputDir), "Output directory should be created")
    }
    
    // MARK: - Path Handling Tests
    
    @Test("Commands handle whitespace in directory paths properly")
    func commandsWhitespaceInDirectoryPathHandling() throws {
        let pathsWithWhitespace = [
            "  /test/output  ",
            "\t/test/output\t",
            "\n/test/output\n",
            "  \t  /test/output  \n  "
        ]
        
        for path in pathsWithWhitespace {
            let command = try LocalizationCommand.parse([
                "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
                "--output-dir", path
            ])
            let config = try command.createConfiguration()
            
            #expect(!config.outputDirectory.hasPrefix(" "), "Output directory should not start with whitespace")
            #expect(!config.outputDirectory.hasPrefix("\t"), "Output directory should not start with tab")
            #expect(!config.outputDirectory.hasPrefix("\n"), "Output directory should not start with newline")
            #expect(config.outputDirectory.contains("/test/output"), "Output directory should contain expected path")
        }
    }
    
    @Test("Commands handle special characters in output paths")
    func commandsSpecialCharactersInPaths() throws {
        let specialPaths = [
            "/path/with spaces/test",
            "/path/with-dashes_and_underscores",
            "/path/with.dots.and,commas",
            "/path/with(parentheses)and[brackets]"
        ]
        
        for specialPath in specialPaths {
            let command = try ColorsCommand.parse([
                "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
                "--output-dir", specialPath
            ])
            let config = try command.createConfiguration()
            
            #expect(config.outputDirectory.contains(specialPath), "Special characters in paths should be preserved")
        }
    }
    
    // MARK: - Configuration Consistency Tests
    
    @Test("Commands maintain configuration consistency across multiple creations")
    func commandsConfigurationConsistency() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output",
            "--keep-csv",
            "--swift-enum-name", "ConsistentEnum",
            "--enum-separate-from-localizations",
            "--use-strings-catalog"
        ])
        
        let config1 = try command.createConfiguration()
        let config2 = try command.createConfiguration()
        
        #expect(config1.enumName == config2.enumName, "Enum names should be consistent")
        #expect(config1.outputDirectory == config2.outputDirectory, "Output directories should be consistent")
        #expect(config1.cleanupTemporaryFiles == config2.cleanupTemporaryFiles, "Cleanup settings should be consistent")
        #expect(config1.unifiedLocalizationDirectory == config2.unifiedLocalizationDirectory, "Unified directory settings should be consistent")
        #expect(config1.useStringsCatalog == config2.useStringsCatalog, "Strings catalog settings should be consistent")
    }
}

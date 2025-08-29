import Testing
import Foundation
import ArgumentParser
import os.log
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer
@testable import CoreExtensions

@Suite
struct CommandsTest {
    
    
    @Test("LocalizationCommand configuration validates correctly")
    func localizationCommandConfigurationValidation() {
        let config = LocalizationCommand.configuration
        
        #expect(config.commandName == "localization")
        #expect(config.abstract == "Generate Swift localization code from Google Sheets data")
    }
    
    @Test("LocalizationCommand creates proper configuration with default parameters")
    func localizationCommandDefaultConfigurationCreation() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        
        #expect(config.enumName == "L10n")
        #expect(config.csvFileName == "generated_localizations.csv")
        #expect(config.cleanupTemporaryFiles == true)
        #expect(config.outputDirectory.contains("Localizables"))
        #expect(config.unifiedLocalizationDirectory == true)
        #expect(config.useStringsCatalog == false)
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
        
        #expect(config.enumName == enumName)
        #expect(config.unifiedLocalizationDirectory != separate)
        #expect(config.useStringsCatalog == stringsCatalog)
        #expect(config.cleanupTemporaryFiles != keepCSV)
    }
    
    @Test("LocalizationCommand conforms to SheetGenCommand protocol")
    func localizationCommandProtocolConformance() throws {
        _ = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        
        #expect(String(describing: LocalizationCommand.logger).contains("Logger"))
    }
    
    @Test("LocalizationCommand creates appropriate generator instance")
    func localizationCommandGeneratorCreation() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        let generator = command.createGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "LocalizationGenerator")
    }
    
    @Test("LocalizationCommand handles verbose configuration logging")
    func localizationCommandVerboseLogging() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output",
            "--verbose",
            "--swift-enum-name", "TestEnum",
            "--enum-separate-from-localizations"
        ])
        let config = try command.createConfiguration()
        
        #expect(throws: Never.self) {
            try command.logConfigurationDetailsIfVerbose(config)
        }
    }
    
    @Test("LocalizationCommand handles non-verbose mode gracefully")
    func localizationCommandNonVerboseModeHandling() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        
        #expect(throws: Never.self) {
            try command.logConfigurationDetailsIfVerbose(config)
        }
    }
    
    
    @Test("ColorsCommand configuration validates correctly")
    func colorsCommandConfigurationValidation() {
        let config = ColorsCommand.configuration
        
        #expect(config.commandName == "colors")
        #expect(config.abstract == "Generate Swift color assets from Google Sheets data")
    }
    
    @Test("ColorsCommand creates proper configuration with default parameters")
    func colorsCommandDefaultConfigurationCreation() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        
        #expect(config.csvFileName == "generated_colors.csv")
        #expect(config.cleanupTemporaryFiles == true)
        #expect(config.outputDirectory.contains("Colors"))
    }
    
    @Test("ColorsCommand conforms to SheetGenCommand protocol")
    func colorsCommandProtocolConformance() throws {
        let command = try ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        
        #expect(command.commandSpecificDirectoryName == "Colors")
        #expect(String(describing: ColorsCommand.logger).contains("Logger"))
    }
    
    @Test("ColorsCommand creates appropriate generator instance")
    func colorsCommandGeneratorCreation() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output"
        ])
        let config = try command.createConfiguration()
        let generator = command.createGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "ColorGenerator")
    }
    
    @Test("ColorsCommand handles verbose configuration logging")
    func colorsCommandVerboseLogging() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/test/output",
            "--verbose"
        ])
        let config = try command.createConfiguration()
        
        #expect(throws: Never.self) {
            try command.logConfigurationDetailsIfVerbose(config)
        }
    }
    
    
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
        
        #expect(logPrivacy.isPrivate == expectedIsPrivate)
        #expect(logPrivacy.isPublic != expectedIsPrivate)
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
            
            #expect(outputDir == testCase.expected)
        }
    }
    
    @Test("Commands compute temporary CSV file path correctly")
    func commandsTemporaryCSVFilePathComputation() throws {
        let locCommand = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        let locTempPath = locCommand.temporaryCSVFilePath
        
        #expect(locTempPath.contains("localizables"))
        #expect(locTempPath.contains("generated_localizables.csv"))
        #expect(locTempPath.hasPrefix(FileManager.default.currentDirectoryPath))
        
        let colorCommand = try ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        let colorTempPath = colorCommand.temporaryCSVFilePath
        
        #expect(colorTempPath.contains("colors"))
        #expect(colorTempPath.contains("generated_colors.csv"))
        #expect(colorTempPath.hasPrefix(FileManager.default.currentDirectoryPath))
    }
    
    
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
        
        #expect(config1.enumName == config2.enumName)
        #expect(config1.outputDirectory == config2.outputDirectory)
        #expect(config1.cleanupTemporaryFiles == config2.cleanupTemporaryFiles)
        #expect(config1.unifiedLocalizationDirectory == config2.unifiedLocalizationDirectory)
        #expect(config1.useStringsCatalog == config2.useStringsCatalog)
    }
    
    
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
            
            #expect(!config.outputDirectory.hasPrefix(" "))
            #expect(!config.outputDirectory.hasPrefix("\t"))
            #expect(!config.outputDirectory.hasPrefix("\n"))
            #expect(config.outputDirectory.contains("/test/output"))
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
            
            #expect(config.outputDirectory.contains(specialPath))
        }
    }
    
    
    @Test("Commands validate Google Sheets URL format")
    func commandsGoogleSheetsURLValidation() throws {
        let validURLs = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pub?output=csv"
        ]
        
        for url in validURLs {
            #expect(throws: Never.self) {
                let command = try LocalizationCommand.parse([url])
                try command.validateAndLogGoogleSheetsURL()
            }
        }
    }
    
    @Test("Commands reject invalid Google Sheets URLs")
    func commandsInvalidURLRejection() throws {
        let invalidURLs = [
            "https://google.com",
            "https://docs.google.com/documents/d/123/edit",
            "not-a-url"
        ]
        
        for url in invalidURLs {
            let command = try LocalizationCommand.parse([url])
            #expect(throws: SheetLocalizerError.self) {
                try command.validateAndLogGoogleSheetsURL()
            }
        }
    }
    
    
    @Test("Commands ensure output directory exists")
    func commandsOutputDirectoryCreation() throws {
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
        
        #expect(FileManager.default.fileExists(atPath: testOutputDir))
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
        
        #expect(throws: Never.self) {
            command.logSuccessfulExecutionCompletion(
                startTime: startTime,
                generatedFilesLocation: generatedLocation,
                logPrivacyLevel: logPrivacyLevel
            )
        }
    }
    
    
    @Test("Commands handle empty and minimal configurations")
    func commandsMinimalConfigurationHandling() throws {
        let minimalCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"
        ])
        
        let config = try minimalCommand.createConfiguration()
        
        #expect(config.enumName == "L10n")
        #expect(config.cleanupTemporaryFiles == true)
        #expect(config.unifiedLocalizationDirectory == true)
        #expect(config.useStringsCatalog == false)
    }
    
    @Test("Commands handle maximum configuration complexity")
    func commandsMaximumConfigurationComplexity() throws {
        let maximalCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123456789012345678901234567890/pub?output=csv",
            "--output-dir", "/very/long/path/with/many/nested/directories/and/special-characters_123",
            "--swift-enum-name", "VeryLongEnumNameWithSpecialCharactersAndNumbers123",
            "--verbose",
            "--keep-csv",
            "--enum-separate-from-localizations",
            "--use-strings-catalog",
            "--log-privacy-level", "private"
        ])
        
        let config = try maximalCommand.createConfiguration()
        
        #expect(config.enumName == "VeryLongEnumNameWithSpecialCharactersAndNumbers123")
        #expect(config.cleanupTemporaryFiles == false)
        #expect(config.unifiedLocalizationDirectory == false)
        #expect(config.useStringsCatalog == true)
        #expect(maximalCommand.logPrivacy.isPrivate == true)
    }
}

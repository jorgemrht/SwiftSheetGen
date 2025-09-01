import Testing
import Foundation
import ArgumentParser
import os.log
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer
@testable import CoreExtensions

@Suite
struct CommandsTest {
    
    
    @Test
    func localizationCommandConfigurationValidation() {
        let config = LocalizationCommand.configuration
        
        #expect(config.commandName == "localization")
        #expect(config.abstract == "Generate Swift localization code from Google Sheets data")
    }
    
    @Test
    func localizationCommandDefaultConfigurationCreation() throws {
        let tempDir = FileManager.default.temporaryDirectory.path
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", tempDir
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
            "--output-dir", FileManager.default.temporaryDirectory.path,
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
    
    @Test
    func localizationCommandProtocolConformance() throws {
        _ = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        
        #expect(String(describing: LocalizationCommand.logger).contains("Logger"))
    }
    
    @Test
    func localizationCommandGeneratorCreation() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", FileManager.default.temporaryDirectory.path
        ])
        let config = try command.createConfiguration()
        let generator = command.createGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "LocalizationGenerator")
    }
    
    @Test
    func localizationCommandVerboseLogging() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", FileManager.default.temporaryDirectory.path,
            "--verbose",
            "--swift-enum-name", "TestEnum",
            "--enum-separate-from-localizations"
        ])
        let config = try command.createConfiguration()
        
        #expect(throws: Never.self) {
            try command.logConfigurationDetailsIfVerbose(config)
        }
    }
    
    @Test
    func localizationCommandNonVerboseModeHandling() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", FileManager.default.temporaryDirectory.path
        ])
        let config = try command.createConfiguration()
        
        #expect(throws: Never.self) {
            try command.logConfigurationDetailsIfVerbose(config)
        }
    }
    
    
    @Test
    func colorsCommandConfigurationValidation() {
        let config = ColorsCommand.configuration
        
        #expect(config.commandName == "colors")
        #expect(config.abstract == "Generate Swift color assets from Google Sheets data")
    }
    
    @Test
    func colorsCommandDefaultConfigurationCreation() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", FileManager.default.temporaryDirectory.path
        ])
        let config = try command.createConfiguration()
        
        #expect(config.csvFileName == "generated_colors.csv")
        #expect(config.cleanupTemporaryFiles == true)
        #expect(config.outputDirectory.contains("Colors"))
    }
    
    @Test
    func colorsCommandProtocolConformance() throws {
        let command = try ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        
        #expect(command.commandSpecificDirectoryName == "Colors")
        #expect(String(describing: ColorsCommand.logger).contains("Logger"))
    }
    
    @Test
    func colorsCommandGeneratorCreation() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", FileManager.default.temporaryDirectory.path
        ])
        let config = try command.createConfiguration()
        let generator = command.createGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "ColorGenerator")
    }
    
    @Test
    func colorsCommandVerboseLogging() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", FileManager.default.temporaryDirectory.path,
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
    
    @Test
    func commandsOutputDirectoryComputation() throws {
        let tempDir = FileManager.default.temporaryDirectory.path
        let currentDir = FileManager.default.currentDirectoryPath
        
        let testCases: [(baseDir: String, expected: String)] = [
            (tempDir, tempDir),
            (currentDir, currentDir),
            (tempDir + "/subdir", "subdir")
        ]
        
        for testCase in testCases {
            let command = try LocalizationCommand.parse([
                "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
                "--output-dir", testCase.baseDir
            ])
            
            let outputDir = try command.getOutputDirectory()
            
            #expect(outputDir.contains(testCase.expected))
        }
    }
    
    @Test
    func commandsTemporaryCSVFilePathComputation() throws {
        let locCommand = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        let locTempPath = try locCommand.getTemporaryCSVFilePath()
        
        #expect(locTempPath.contains("localizables"))
        #expect(locTempPath.contains("generated_localizables.csv"))
        
        let colorCommand = try ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml"])
        let colorTempPath = try colorCommand.getTemporaryCSVFilePath()
        
        #expect(colorTempPath.contains("colors"))
        #expect(colorTempPath.contains("generated_colors.csv"))
    }
    
    
    @Test
    func commandsComplexConfigurationValidation() throws {
        let complexArgs = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", FileManager.default.temporaryDirectory.appendingPathComponent("complex_test").path,
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
    
    @Test
    func commandsConfigurationConsistency() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", FileManager.default.temporaryDirectory.path,
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
    
    
    @Test
    func commandsWhitespaceInDirectoryPathHandling() throws {
        let tempDir = FileManager.default.temporaryDirectory.path
        let pathsWithWhitespace = [
            "  \(tempDir)/test_output  ",
            "\t\(tempDir)/test_output\t",
            "\n\(tempDir)/test_output\n",
            "  \t  \(tempDir)/test_output  \n  "
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
            #expect(config.outputDirectory.contains("test_output"))
        }
    }
    
    @Test
    func commandsSpecialCharactersInPaths() throws {
        let specialPaths = [
            FileManager.default.temporaryDirectory.appendingPathComponent("test_with_underscores").path,
            FileManager.default.temporaryDirectory.appendingPathComponent("test-with-dashes").path,
            FileManager.default.temporaryDirectory.appendingPathComponent("test.with.dots").path
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
    
    
    @Test
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
    
    @Test
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
    
    
    @Test
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
    
    
    @Test
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
    
    
    @Test
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
    
    @Test
    func commandsMaximumConfigurationComplexity() throws {
        let maximalCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123456789012345678901234567890/pub?output=csv",
            "--output-dir", FileManager.default.temporaryDirectory.appendingPathComponent("very_long_path_with_many_nested_directories_and_special_characters_123").path,
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

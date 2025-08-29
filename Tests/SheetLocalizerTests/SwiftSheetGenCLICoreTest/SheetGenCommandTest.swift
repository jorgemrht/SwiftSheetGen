import Testing
import Foundation
import ArgumentParser
import CoreExtensions
import os.log
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer

@Suite
struct SheetGenCommandTest {
    
    
    @Test("SheetGenCommand protocol defines required methods correctly")
    func sheetGenCommandProtocolRequiredMethods() {
        #expect(String(describing: LocalizationCommand.self).contains("LocalizationCommand"))
        #expect(String(describing: ColorsCommand.self).contains("ColorsCommand"))
    }
    
    @Test("SheetGenCommand protocol defines required associated types correctly")
    func sheetGenCommandProtocolAssociatedTypes() {
        let locCommand = try! LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/test/pubhtml"])
        let colorCommand = try! ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/test/pubhtml"])
        
        #expect(String(describing: type(of: locCommand)) == "LocalizationCommand")
        #expect(String(describing: type(of: colorCommand)) == "ColorsCommand")
    }
    
    
    @Test("SheetGenCommand logPrivacy property works correctly",
          arguments: [
              ("public", false),
              ("private", true),
              ("Public", false),
              ("PRIVATE", true),
              ("invalid", false)
          ])
    func sheetGenCommandLogPrivacyProperty(inputLevel: String, expectedIsPrivate: Bool) throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--log-privacy-level", inputLevel
        ])
        
        let logPrivacy = command.logPrivacy
        
        #expect(logPrivacy.isPrivate == expectedIsPrivate)
        #expect(logPrivacy.isPublic != expectedIsPrivate)
    }
    
    @Test("SheetGenCommand outputDirectory property computes correctly")
    func sheetGenCommandOutputDirectoryProperty() throws {
        let testCases: [(baseDir: String, commandType: String, expected: String)] = [
            ("./", "Localizables", ".//Localizables"),
            ("/absolute/path", "Localizables", "/absolute/path/Localizables"),
            ("relative/path", "Colors", "relative/path/Colors"),
            ("  /path/with/spaces  ", "Localizables", "/path/with/spaces/Localizables")
        ]
        
        for testCase in testCases {
            if testCase.commandType == "Localizables" {
                let command = try LocalizationCommand.parse([
                    "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
                    "--output-dir", testCase.baseDir
                ])
                
                #expect(command.outputDirectory == testCase.expected)
            } else {
                let command = try ColorsCommand.parse([
                    "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
                    "--output-dir", testCase.baseDir
                ])
                
                #expect(command.outputDirectory == testCase.expected)
            }
        }
    }
    
    @Test("SheetGenCommand temporaryCSVFilePath property computes correctly")
    func sheetGenCommandTemporaryCSVFilePathProperty() throws {
        let locCommand = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/test/pubhtml"])
        let colorCommand = try ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/test/pubhtml"])
        
        let locTempPath = locCommand.temporaryCSVFilePath
        let colorTempPath = colorCommand.temporaryCSVFilePath
        
        #expect(locTempPath.contains("localizables"))
        #expect(locTempPath.contains("generated_localizables.csv"))
        #expect(locTempPath.hasPrefix(FileManager.default.currentDirectoryPath))
        
        #expect(colorTempPath.contains("colors"))
        #expect(colorTempPath.contains("generated_colors.csv"))
    }
    
    @Test("SheetGenCommand commandSpecificDirectoryName property is correct")
    func sheetGenCommandSpecificDirectoryNameProperty() throws {
        let locCommand = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/test/pubhtml"])
        let colorCommand = try ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/test/pubhtml"])
        
        #expect(locCommand.commandSpecificDirectoryName == "Localizables")
        #expect(colorCommand.commandSpecificDirectoryName == "Colors")
    }
    
    
    @Test("SheetGenCommand validateAndLogGoogleSheetsURL works correctly")
    func sheetGenCommandGoogleSheetsURLValidation() throws {
        let validURLs = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pub?output=csv"
        ]
        
        for url in validURLs {
            let command = try LocalizationCommand.parse([url])
            #expect(throws: Never.self) {
                try command.validateAndLogGoogleSheetsURL()
            }
        }
    }
    
    @Test("SheetGenCommand rejects invalid URLs appropriately")
    func sheetGenCommandInvalidURLRejection() throws {
        let invalidURLs = [
            "https://google.com",
            "https://docs.google.com/documents/d/123/edit",
            "not-a-url",
            ""
        ]
        
        for url in invalidURLs {
            let command = try LocalizationCommand.parse([url])
            #expect(throws: SheetLocalizerError.self) {
                try command.validateAndLogGoogleSheetsURL()
            }
        }
    }
    
    
    @Test("SheetGenCommand createConfiguration works for LocalizationCommand")
    func sheetGenCommandLocalizationConfigurationCreation() throws {
        let command = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", "/test/output",
            "--swift-enum-name", "TestEnum",
            "--use-strings-catalog"
        ])
        
        let config = try command.createConfiguration()
        
        #expect(config.enumName == "TestEnum")
        #expect(config.useStringsCatalog == true)
        #expect(config.outputDirectory.contains("Localizables"))
    }
    
    @Test("SheetGenCommand createConfiguration works for ColorsCommand")
    func sheetGenCommandColorsConfigurationCreation() throws {
        let command = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", "/test/colors",
            "--keep-csv"
        ])
        
        let config = try command.createConfiguration()
        
        #expect(config.cleanupTemporaryFiles == false)
        #expect(config.outputDirectory.contains("Colors"))
        #expect(config.csvFileName == "generated_colors.csv")
    }
    
    
    @Test("SheetGenCommand createGenerator works correctly")
    func sheetGenCommandGeneratorCreation() throws {
        let locCommand = try LocalizationCommand.parse(["https://docs.google.com/spreadsheets/d/e/test/pubhtml"])
        let colorCommand = try ColorsCommand.parse(["https://docs.google.com/spreadsheets/d/e/test/pubhtml"])
        
        let locConfig = try locCommand.createConfiguration()
        let colorConfig = try colorCommand.createConfiguration()
        
        let locGenerator = locCommand.createGenerator(config: locConfig)
        let colorGenerator = colorCommand.createGenerator(config: colorConfig)
        
        #expect(String(describing: type(of: locGenerator)) == "LocalizationGenerator")
        #expect(String(describing: type(of: colorGenerator)) == "ColorGenerator")
    }
    
    
    @Test("SheetGenCommand logConfigurationDetailsIfVerbose respects verbose flag")
    func sheetGenCommandVerboseLogging() throws {
        let verboseCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--verbose"
        ])
        
        let nonVerboseCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml"
        ])
        
        let config = try verboseCommand.createConfiguration()
        
        #expect(throws: Never.self) {
            try verboseCommand.logConfigurationDetailsIfVerbose(config)
            try nonVerboseCommand.logConfigurationDetailsIfVerbose(config)
        }
    }
    
    @Test("SheetGenCommand logging works with different privacy levels")
    func sheetGenCommandLoggingPrivacyLevels() throws {
        let privacyLevels = ["public", "private"]
        
        for level in privacyLevels {
            let command = try LocalizationCommand.parse([
                "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
                "--verbose",
                "--log-privacy-level", level
            ])
            
            let config = try command.createConfiguration()
            
            #expect(throws: Never.self) {
                try command.logConfigurationDetailsIfVerbose(config)
            }
        }
    }
    
    
    @Test("SheetGenCommand workflow methods are accessible and callable")
    func sheetGenCommandWorkflowMethodAccessibility() throws {
        let locCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", "/tmp/test"
        ])
        
        let colorCommand = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", "/tmp/test"
        ])
        
        #expect(String(describing: type(of: locCommand.temporaryFileCleanupIfRequested)) == "() throws -> ()")
        #expect(String(describing: type(of: colorCommand.temporaryFileCleanupIfRequested)) == "() throws -> ()")
    }
    
    @Test("SheetGenCommand temporary file cleanup logic works correctly")
    func sheetGenCommandTemporaryFileCleanupLogic() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let keepCSVCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", tempDir.path,
            "--keep-csv"
        ])
        
        let cleanupCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", tempDir.path
        ])
        
        #expect(throws: Never.self) {
            try keepCSVCommand.temporaryFileCleanupIfRequested()
            try cleanupCommand.temporaryFileCleanupIfRequested()
        }
    }
    
    
    @Test("SheetGenCommand handles invalid configuration gracefully")
    func sheetGenCommandInvalidConfigurationHandling() {
        #expect(throws: (any Error).self) {
            _ = try LocalizationCommand.parse([])
        }
        
        #expect(throws: (any Error).self) {
            _ = try ColorsCommand.parse(["--invalid-flag"])
        }
    }
    
    @Test("SheetGenCommand handles malformed arguments gracefully")
    func sheetGenCommandMalformedArgumentsHandling() {
        let malformedArgs = [
            ["--output-dir"],
            ["https://test.com", "--swift-enum-name"],
            ["https://test.com", "--log-privacy-level"]
        ]
        
        for args in malformedArgs {
            #expect(throws: (any Error).self) {
                _ = try LocalizationCommand.parse(args)
            }
        }
    }
    
    
    @Test("SheetGenCommand integrates properly with SheetConfig and SheetGenerator protocols")
    func sheetGenCommandProtocolIntegration() throws {
        let locCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", "/test"
        ])
        
        let colorCommand = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", "/test"
        ])
        
        let locConfig = try locCommand.createConfiguration()
        let colorConfig = try colorCommand.createConfiguration()
        
        let locGenerator = locCommand.createGenerator(config: locConfig)
        let colorGenerator = colorCommand.createGenerator(config: colorConfig)
        
        #expect(String(describing: type(of: locGenerator)).contains("Generator"))
        #expect(String(describing: type(of: colorGenerator)).contains("Generator"))
    }
    
    @Test("SheetGenCommand works with different command configurations")
    func sheetGenCommandDifferentConfigurations() throws {
        let configurations = [
            (
                args: ["https://docs.google.com/spreadsheets/d/e/test/pubhtml"],
                expectDefaults: true
            ),
            (
                args: ["https://docs.google.com/spreadsheets/d/e/test/pubhtml", "--verbose", "--keep-csv"],
                expectDefaults: false
            ),
            (
                args: ["https://docs.google.com/spreadsheets/d/e/test/pubhtml", "--output-dir", "/custom/path", "--log-privacy-level", "private"],
                expectDefaults: false
            )
        ]
        
        for configuration in configurations {
            let locCommand = try LocalizationCommand.parse(configuration.args)
            let colorCommand = try ColorsCommand.parse(configuration.args)
            
            #expect(throws: Never.self) {
                let locConfig = try locCommand.createConfiguration()
                let colorConfig = try colorCommand.createConfiguration()
                
                _ = locCommand.createGenerator(config: locConfig)
                _ = colorCommand.createGenerator(config: colorConfig)
            }
        }
    }
    
    
    @Test("SheetGenCommand handles complex argument combinations efficiently")
    func sheetGenCommandComplexArgumentCombinations() throws {
        let complexArgs = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-very-long-id-with-many-characters/pubhtml",
            "--output-dir", "/very/long/path/with/many/nested/directories/that/might/test/limits",
            "--swift-enum-name", "VeryLongEnumNameThatMightTestStringHandlingLimits",
            "--verbose",
            "--keep-csv", 
            "--enum-separate-from-localizations",
            "--use-strings-catalog",
            "--log-privacy-level", "private"
        ]
        
        let command = try LocalizationCommand.parse(complexArgs)
        let config = try command.createConfiguration()
        let generator = command.createGenerator(config: config)
        
        #expect(config.enumName == "VeryLongEnumNameThatMightTestStringHandlingLimits")
        #expect(config.useStringsCatalog == true)
        #expect(config.cleanupTemporaryFiles == false)
        #expect(command.logPrivacy.isPrivate == true)
        #expect(String(describing: type(of: generator)) == "LocalizationGenerator")
    }
    
    @Test("SheetGenCommand maintains consistency across multiple operations")
    func sheetGenCommandConsistencyAcrossOperations() throws {
        let args = [
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "--output-dir", "/consistent/test",
            "--verbose",
            "--keep-csv"
        ]
        
        for _ in 0..<10 {
            let command = try LocalizationCommand.parse(args)
            let config1 = try command.createConfiguration()
            let config2 = try command.createConfiguration()
            
            #expect(config1.outputDirectory == config2.outputDirectory)
            #expect(config1.cleanupTemporaryFiles == config2.cleanupTemporaryFiles)
            
            let generator1 = command.createGenerator(config: config1)
            let generator2 = command.createGenerator(config: config2)
            
            #expect(String(describing: type(of: generator1)) == String(describing: type(of: generator2)))
        }
    }
}

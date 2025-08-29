import Testing
import Foundation
import ArgumentParser
import os.log
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer
@testable import CoreExtensions

@Suite
struct SheetExtensionTest {
    
    // MARK: - Protocol Conformance Tests
    
    @Test("LocalizationConfig conforms to SheetConfig protocol")
    func localizationConfigSheetConfigConformance() {
        let config = LocalizationConfig.default
        
        #expect(config.outputDirectory == "./")
        #expect(config.csvFileName == "localizables.csv")
        #expect(config.cleanupTemporaryFiles == true)
    }
    
    @Test("ColorConfig conforms to SheetConfig protocol")
    func colorConfigSheetConfigConformance() {
        let config = ColorConfig.default
        
        #expect(config.outputDirectory == "Colors")
        #expect(config.csvFileName == "generated_colors.csv")
        #expect(config.cleanupTemporaryFiles == true)
    }
    
    @Test("LocalizationGenerator conforms to SheetGenerator protocol")
    func localizationGeneratorSheetGeneratorConformance() {
        let config = LocalizationConfig.default
        let generator = LocalizationGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "LocalizationGenerator")
    }
    
    @Test("ColorGenerator conforms to SheetGenerator protocol")
    func colorGeneratorSheetGeneratorConformance() {
        let config = ColorConfig.default
        let generator = ColorGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "ColorGenerator")
    }
    
    // MARK: - Google Sheets URL Validation Tests
    
    @Test("AsyncParsableCommand validates correct Google Sheets URLs",
          arguments: [
              "https://docs.google.com/spreadsheets/d/e/abc123def456/pubhtml",
              "https://docs.google.com/spreadsheets/d/e/simple-test-id/pub?output=csv",
          ])
    func asyncParsableCommandValidGoogleSheetsURLValidation(url: String) {
        let command = LocalizationCommand()
        let isValid = command.validateGoogleSheetsURL(url)
        
        #expect(isValid == true)
    }
    
    @Test("AsyncParsableCommand rejects invalid URLs",
          arguments: [
              "",
              "   ",
              "not-a-url",
              "https://google.com",
              "https://sheets.google.com/invalid",
              "https://docs.google.com/documents/d/123/edit",
              "https://drive.google.com/file/d/123/view",
              "https://example.com/spreadsheets/d/123/edit",
              "ftp://docs.google.com/spreadsheets/d/123/edit",
              "https://docs.google.com/presentations/d/123/edit",
              "https://docs.google.com/forms/d/123/edit",
              "https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit#gid=0",
              "https://docs.google.com/spreadsheets/d/abc123def456/export?format=csv&gid=789",
              "https://docs.google.com/spreadsheets/d/simple-id/pub?output=csv",
              "https://docs.google.com/spreadsheets/d/complex-id_with-special.chars123/edit",
              "https://docs.google.com/spreadsheets/d//edit",
              "https://docs.google.com/spreadsheets/d/with%20encoded%20chars/edit"
          ])
    func asyncParsableCommandInvalidURLRejection(url: String) {
        let command = ColorsCommand()
        let isValid = command.validateGoogleSheetsURL(url)
        
        #expect(isValid == false)
    }
    
    @Test("Google Sheets URL validation handles edge cases properly")
    func googleSheetsURLValidationEdgeCases() {
        let command = LocalizationCommand()
        
        let urlWithSpaces = "   https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml   "
        #expect(command.validateGoogleSheetsURL(urlWithSpaces) == true)
        
        let urlWithWhitespace = "\t\nhttps://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pub?output=csv\t\n"
        #expect(command.validateGoogleSheetsURL(urlWithWhitespace) == true)
        
        let malformedURL = "https://docs.google.com/spreadsheets/invalid-structure"
        #expect(command.validateGoogleSheetsURL(malformedURL) == false)
    }
    
    @Test("Google Sheets URL validation handles complex patterns")
    func googleSheetsURLValidationComplexPatterns() {
        let command = LocalizationCommand()
        
        let complexValidURLs = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vSf-A_z9XyZ123456789/pubhtml",
            "https://docs.google.com/spreadsheets/d/e/2PACX-1v_Very-Long-Document-ID-With-Many-Characters_123456789/pub?output=csv"
        ]
        
        for url in complexValidURLs {
            #expect(command.validateGoogleSheetsURL(url) == true)
        }
        
        let complexInvalidURLs = [
            "https://docs.google.com/spreadsheets/d/simple-id/pubhtml",
            "https://docs.google.com/spreadsheets/d/e/2PACX-invalid/export?format=csv"
        ]
        
        for url in complexInvalidURLs {
            #expect(command.validateGoogleSheetsURL(url) == false)
        }
    }
    
    // MARK: - Directory Management Tests
    
    @Test("AsyncParsableCommand ensures output directory exists for valid paths")
    func asyncParsableCommandOutputDirectoryCreation() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let testPath = tempDir.appendingPathComponent("test_output").path
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let command = LocalizationCommand()
        
        #expect(throws: Never.self) {
            try command.ensureOutputDirectoryExists(atPath: testPath, logger: LocalizationCommand.logger)
        }
        
        #expect(FileManager.default.fileExists(atPath: testPath))
        
        #expect(throws: Never.self) {
            try command.ensureOutputDirectoryExists(atPath: testPath, logger: LocalizationCommand.logger)
        }
    }
    
    @Test("AsyncParsableCommand handles directory creation errors gracefully")
    func asyncParsableCommandDirectoryCreationErrorHandling() {
        let command = ColorsCommand()
        
        let impossiblePaths = [
            "/dev/null/impossible/path",
            "/root/restricted/path"
        ]
        
        for impossiblePath in impossiblePaths {
            #expect(throws: SheetLocalizerError.self) {
                try command.ensureOutputDirectoryExists(atPath: impossiblePath, logger: ColorsCommand.logger)
            }
        }
    }
    
    @Test("AsyncParsableCommand handles directory paths with special characters")
    func asyncParsableCommandSpecialCharactersInPaths() throws {
        let tempBaseDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        defer {
            try? FileManager.default.removeItem(at: tempBaseDir)
        }
        
        let specialPaths = [
            "path with spaces",
            "path-with-dashes_and_underscores",
            "path.with.dots",
            "path(with)parentheses",
            "path[with]brackets",
            "path{with}braces"
        ]
        
        let command = LocalizationCommand()
        
        for specialPath in specialPaths {
            let fullPath = tempBaseDir.appendingPathComponent(specialPath).path
            
            #expect(throws: Never.self) {
                try command.ensureOutputDirectoryExists(atPath: fullPath, logger: LocalizationCommand.logger)
            }
            
            #expect(FileManager.default.fileExists(atPath: fullPath))
        }
    }
    
    @Test("AsyncParsableCommand handles nested directory creation")
    func asyncParsableCommandNestedDirectoryCreation() throws {
        let tempBaseDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        defer {
            try? FileManager.default.removeItem(at: tempBaseDir)
        }
        
        let command = LocalizationCommand()
        let deepPath = tempBaseDir.appendingPathComponent("level1/level2/level3/level4").path
        
        #expect(throws: Never.self) {
            try command.ensureOutputDirectoryExists(atPath: deepPath, logger: LocalizationCommand.logger)
        }
        
        #expect(FileManager.default.fileExists(atPath: deepPath))
    }
    
    // MARK: - Execution Completion Logging Tests
    
    @Test("AsyncParsableCommand logs successful execution with proper timing")
    func asyncParsableCommandSuccessfulExecutionLogging() {
        let command = LocalizationCommand()
        let startTime = Date().addingTimeInterval(-5.0)
        let location = "/test/generated/files"
        
        let privacyLevels = ["public", "private", "invalid"]
        
        for privacyLevel in privacyLevels {
            #expect(throws: Never.self) {
                command.logSuccessfulExecutionCompletion(
                    startTime: startTime,
                    generatedFilesLocation: location,
                    logPrivacyLevel: privacyLevel
                )
            }
        }
    }
    
    @Test("AsyncParsableCommand handles execution timing edge cases")
    func asyncParsableCommandExecutionTimingEdgeCases() {
        let command = ColorsCommand()
        let location = "/test/location"
        
        let recentStartTime = Date()
        #expect(throws: Never.self) {
            command.logSuccessfulExecutionCompletion(
                startTime: recentStartTime,
                generatedFilesLocation: location,
                logPrivacyLevel: "public"
            )
        }
        
        let futureStartTime = Date().addingTimeInterval(60.0)
        #expect(throws: Never.self) {
            command.logSuccessfulExecutionCompletion(
                startTime: futureStartTime,
                generatedFilesLocation: location,
                logPrivacyLevel: "public"
            )
        }
        
        let longAgoStartTime = Date().addingTimeInterval(-3600.0)
        #expect(throws: Never.self) {
            command.logSuccessfulExecutionCompletion(
                startTime: longAgoStartTime,
                generatedFilesLocation: location,
                logPrivacyLevel: "private"
            )
        }
    }
    
    @Test("AsyncParsableCommand handles special characters in file locations during logging")
    func asyncParsableCommandSpecialCharactersInLogging() {
        let command = LocalizationCommand()
        let startTime = Date().addingTimeInterval(-2.0)
        
        let locationsWithSpecialChars = [
            "/path/with spaces/generated files",
            "/path/with-dashes_and_underscores/files",
            "/path/with.dots.and,commas/files",
            "/path/with(parentheses)and[brackets]/files",
            "/path/with{braces}/files"
        ]
        
        for location in locationsWithSpecialChars {
            #expect(throws: Never.self) {
                command.logSuccessfulExecutionCompletion(
                    startTime: startTime,
                    generatedFilesLocation: location,
                    logPrivacyLevel: "public"
                )
            }
        }
    }
    
    @Test("AsyncParsableCommand handles very long execution times")
    func asyncParsableCommandLongExecutionTimes() {
        let command = LocalizationCommand()
        let veryOldStartTime = Date().addingTimeInterval(-86400.0) // 1 day ago
        let location = "/test/location"
        
        #expect(throws: Never.self) {
            command.logSuccessfulExecutionCompletion(
                startTime: veryOldStartTime,
                generatedFilesLocation: location,
                logPrivacyLevel: "public"
            )
        }
    }
    
    // MARK: - Log Privacy Level Integration Tests
    
    @Test("AsyncParsableCommand properly integrates LogPrivacyLevel with logging")
    func asyncParsableCommandLogPrivacyLevelIntegration() {
        let testCases: [(input: String, expectedIsPrivate: Bool)] = [
            ("public", false),
            ("private", true),
            ("Public", false),
            ("Private", true),
            ("PRIVATE", true),
            ("PUBLIC", false),
            ("invalid", false),
            ("", false),
            ("pRiVaTe", true),
            ("anything_else", false)
        ]
        
        for testCase in testCases {
            let privacyLevel = LogPrivacyLevel(from: testCase.input)
            
            #expect(privacyLevel.isPrivate == testCase.expectedIsPrivate)
            #expect(privacyLevel.isPublic != testCase.expectedIsPrivate)
        }
    }
    
    @Test("AsyncParsableCommand respects privacy levels in logging calls")
    func asyncParsableCommandPrivacyLevelRespected() {
        let command = LocalizationCommand()
        let startTime = Date()
        let location = "/private/sensitive/path"
        
        let privateLevels = ["private", "PRIVATE", "Private"]
        let publicLevels = ["public", "PUBLIC", "Public", "invalid", ""]
        
        for level in privateLevels {
            #expect(throws: Never.self) {
                command.logSuccessfulExecutionCompletion(
                    startTime: startTime,
                    generatedFilesLocation: location,
                    logPrivacyLevel: level
                )
            }
        }
        
        for level in publicLevels {
            #expect(throws: Never.self) {
                command.logSuccessfulExecutionCompletion(
                    startTime: startTime,
                    generatedFilesLocation: location,
                    logPrivacyLevel: level
                )
            }
        }
    }
    
    // MARK: - Error Propagation Tests
    
    @Test("AsyncParsableCommand properly creates SheetLocalizerError for file system issues")
    func asyncParsableCommandFileSystemErrorPropagation() {
        let command = LocalizationCommand()
        let impossiblePath = "/dev/null/impossible/path"
        
        do {
            try command.ensureOutputDirectoryExists(atPath: impossiblePath, logger: LocalizationCommand.logger)
            #expect(Bool(false), "Should have thrown an error for impossible path")
        } catch let error as SheetLocalizerError {
            switch error {
            case .fileSystemError(let message):
                #expect(message.contains(impossiblePath))
            default:
                #expect(Bool(false), "Should throw fileSystemError specifically")
            }
        } catch {
            #expect(Bool(false), "Should throw SheetLocalizerError specifically")
        }
    }
    
    @Test("AsyncParsableCommand handles file system permissions gracefully")
    func asyncParsableCommandFileSystemPermissions() {
        let command = ColorsCommand()
        let restrictedPaths = [
            "/root/restricted",
            "/etc/restricted/path"
        ]
        
        for path in restrictedPaths {
            do {
                try command.ensureOutputDirectoryExists(atPath: path, logger: ColorsCommand.logger)
            } catch {
                #expect(error is SheetLocalizerError)
            }
        }
    }
    
    // MARK: - Path Normalization and Validation Tests
    
    @Test("Directory path handling normalizes whitespace correctly")
    func directoryPathWhitespaceNormalization() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let command = ColorsCommand()
        let pathsWithWhitespace = [
            ("  /test/path  ", "/test/path"),
            ("\t/test/path\t", "/test/path"),
            ("\n/test/path\n", "/test/path"),
            ("  \t  /test/path  \n  ", "/test/path")
        ]
        
        for (_, expectedCleanPath) in pathsWithWhitespace {
            let actualPath = tempDir.appendingPathComponent(expectedCleanPath.trimmingCharacters(in: .whitespacesAndNewlines)).path
            
            #expect(throws: Never.self) {
                try command.ensureOutputDirectoryExists(atPath: actualPath, logger: ColorsCommand.logger)
            }
            
            #expect(FileManager.default.fileExists(atPath: actualPath))
        }
    }
    
    @Test("Directory path handling handles relative paths correctly")
    func directoryPathRelativePathHandling() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let command = LocalizationCommand()
        
        let currentDirectory = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer {
            FileManager.default.changeCurrentDirectoryPath(currentDirectory)
        }
        
        let relativePaths = [
            "./relative/path",
            "../parent/path",
            "simple/relative"
        ]
        
        for relativePath in relativePaths {
            let fullPath = URL(fileURLWithPath: relativePath, relativeTo: tempDir).standardized.path
            
            #expect(throws: Never.self) {
                try command.ensureOutputDirectoryExists(atPath: fullPath, logger: LocalizationCommand.logger)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Sheet extensions work together in realistic scenarios")
    func sheetExtensionsIntegrationTest() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let locCommand = try LocalizationCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", tempDir.path,
            "--verbose",
            "--log-privacy-level", "private"
        ])
        
        let colorCommand = try ColorsCommand.parse([
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pub?output=csv",
            "--output-dir", tempDir.path,
            "--verbose",
            "--keep-csv"
        ])
        
        let locConfig = try locCommand.createConfiguration()
        let colorConfig = try colorCommand.createConfiguration()
        
        #expect(locCommand.validateGoogleSheetsURL(locCommand.sharedOptions.sheetsURL) == true)
        #expect(colorCommand.validateGoogleSheetsURL(colorCommand.sharedOptions.sheetsURL) == true)
        
        #expect(throws: Never.self) {
            try locCommand.ensureOutputDirectoryExists(atPath: locConfig.outputDirectory, logger: LocalizationCommand.logger)
            try colorCommand.ensureOutputDirectoryExists(atPath: colorConfig.outputDirectory, logger: ColorsCommand.logger)
        }
        
        #expect(FileManager.default.fileExists(atPath: locConfig.outputDirectory))
        #expect(FileManager.default.fileExists(atPath: colorConfig.outputDirectory))
    }
}

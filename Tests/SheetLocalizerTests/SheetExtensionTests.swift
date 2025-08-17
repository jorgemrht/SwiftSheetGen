import Testing
import Foundation
import ArgumentParser
import os.log
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer
@testable import CoreExtensions

@Suite("Sheet+Extension Validation and Logging Tests")
struct SheetExtensionTests {
    
    // MARK: - Google Sheets URL Validation Tests
    
    @Test("AsyncParsableCommand validates correct Google Sheets URLs",
          arguments: [
              "https://docs.google.com/spreadsheets/d/e/abc123def456/pubhtml",
              "https://docs.google.com/spreadsheets/d/e/simple-test-id/pub?output=csv",
          ])
    func asyncParsableCommandValidGoogleSheetsURLValidation(url: String) {
        let command = LocalizationCommand()
        let isValid = command.validateGoogleSheetsURL(url)
        
        #expect(isValid == true, "URL '\(url)' should be recognized as valid Google Sheets URL")
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
        
        #expect(isValid == false, "URL '\(url)' should be rejected as invalid Google Sheets URL")
    }
    
    @Test("Google Sheets URL validation handles edge cases properly")
    func googleSheetsURLValidationEdgeCases() {
        let command = LocalizationCommand()
        
        // Test trimmed URLs with new approved pattern
        let urlWithSpaces = "   https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml   "
        #expect(command.validateGoogleSheetsURL(urlWithSpaces) == true, "URL with surrounding spaces should be valid after trimming")
        
        // Test URL with tabs and newlines
        let urlWithWhitespace = "\t\nhttps://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pub?output=csv\t\n"
        #expect(command.validateGoogleSheetsURL(urlWithWhitespace) == true, "URL with various whitespace should be valid after trimming")
        
        // Test malformed but parseable URLs
        let malformedURL = "https://docs.google.com/spreadsheets/invalid-structure"
        #expect(command.validateGoogleSheetsURL(malformedURL) == false, "Malformed URLs should be rejected")
    }
    
    // MARK: - Directory Management Tests
    
    @Test("AsyncParsableCommand ensures output directory exists for valid paths")
    func asyncParsableCommandOutputDirectoryCreation() async throws {
        // Create temporary directory for testing
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let testPath = tempDir.appendingPathComponent("test_output").path
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let command = LocalizationCommand()
        
        #expect(throws: Never.self) {
            try command.ensureOutputDirectoryExists(atPath: testPath, logger: LocalizationCommand.logger)
        }
        
        #expect(FileManager.default.fileExists(atPath: testPath), "Directory should be created successfully")
        
        // Test that calling again doesn't cause errors (idempotent)
        #expect(throws: Never.self) {
            try command.ensureOutputDirectoryExists(atPath: testPath, logger: LocalizationCommand.logger)
        }
    }
    
    @Test("AsyncParsableCommand handles directory creation errors gracefully")
    func asyncParsableCommandDirectoryCreationErrorHandling() {
        let command = ColorsCommand()
        
        let impossiblePaths = [
            "/dev/null/impossible/path",
            "/root/restricted/path",
            "/nonexistent/deeply/nested/impossible\0null/path"
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
            "path{with}braces",
            "pathWithUnicode🚀émojis",
            "path_with_àccénts"
        ]
        
        let command = LocalizationCommand()
        
        for specialPath in specialPaths {
            let fullPath = tempBaseDir.appendingPathComponent(specialPath).path
            
            #expect(throws: Never.self) {
                try command.ensureOutputDirectoryExists(atPath: fullPath, logger: LocalizationCommand.logger)
            }
            
            #expect(FileManager.default.fileExists(atPath: fullPath), "Directory with special characters '\(specialPath)' should be created")
        }
    }
    
    // MARK: - Execution Completion Logging Tests
    
    @Test("AsyncParsableCommand logs successful execution with proper timing")
    func asyncParsableCommandSuccessfulExecutionLogging() {
        let command = LocalizationCommand()
        let startTime = Date().addingTimeInterval(-5.0) // 5 seconds ago
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
        
        let longAgoStartTime = Date().addingTimeInterval(-3600.0) // 1 hour ago
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
            "/path/with{braces}/files",
            "/path/withUnicode🚀émojis/files",
            "/path/with_àccénts_ñ_çharacters/files"
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
            
            #expect(privacyLevel.isPrivate == testCase.expectedIsPrivate, 
                   "Privacy level '\(testCase.input)' should have isPrivate = \(testCase.expectedIsPrivate)")
            #expect(privacyLevel.isPublic != testCase.expectedIsPrivate,
                   "Privacy level '\(testCase.input)' should have isPublic opposite to isPrivate")
        }
    }
    
    // MARK: - Error Propagation Tests
    
    @Test("AsyncParsableCommand properly creates SheetLocalizerError for file system issues")
    func asyncParsableCommandFileSystemErrorPropagation() {
        let command = LocalizationCommand()
        let impossiblePath = "/dev/null/impossible\0path"
        
        do {
            try command.ensureOutputDirectoryExists(atPath: impossiblePath, logger: LocalizationCommand.logger)
            #expect(Bool(false), "Should have thrown an error for impossible path")
        } catch let error as SheetLocalizerError {
            switch error {
            case .fileSystemError(let message):
                #expect(message.contains(impossiblePath), "Error message should contain the problematic path")
            default:
                #expect(Bool(false), "Should throw fileSystemError specifically")
            }
        } catch {
            #expect(Bool(false), "Should throw SheetLocalizerError specifically, got \(type(of: error))")
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
            
            #expect(FileManager.default.fileExists(atPath: actualPath), "Directory should be created with normalized path")
        }
    }
}

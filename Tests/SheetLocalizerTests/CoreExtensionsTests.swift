import Testing
import Foundation
@testable import CoreExtensions

@Suite
struct CoreExtensionsTests {

    // MARK: - String Extension Tests

    @Test("String.trimmedContent removes whitespace and newlines from both ends",
          arguments: [
              ("  hello  ", "hello"),
              ("\nworld\t", "world"),
              ("   multiple   spaces   ", "multiple   spaces"),
              ("\r\n\ttabs\r\n", "tabs"),
              ("", ""),
              ("nospaces", "nospaces")
          ])
    func stringTrimmingValidation(input: String, expected: String) {
        #expect(input.trimmedContent == expected, "String '\(input)' should trim to '\(expected)'")
    }

    @Test("String.isGoogleSheetsURL accurately identifies valid Google Sheets URLs",
          arguments: [
              ("https://docs.google.com/spreadsheets/d/e/2PACX-1vTest12345/pubhtml", true),
              ("https://docs.google.com/spreadsheets/d/e/2PACX-1vTest12345/pub?output=csv", true),
              ("https://docs.google.com/spreadsheets/d/e/abc123xyz/pubhtml", true),
              ("https://docs.google.com/spreadsheets/d/e/long-document-id-12345/pub?output=csv", true),
              ("https://docs.google.com/spreadsheets/d/some-id/edit", false),
              ("https://docs.google.com/spreadsheets/d/1a2b3c4d/export?format=csv", false),
              ("https://docs.google.com/spreadsheets/d/xyz123/edit#gid=456", false),
              ("https://google.com", false),
              ("https://sheets.google.com/invalid", false),
              ("https://docs.google.com/documents/d/123/edit", false),
              ("", false),
              ("not-a-url", false)
          ])
    func googleSheetsURLValidation(url: String, shouldBeValid: Bool) {
        #expect(url.isGoogleSheetsURL == shouldBeValid, 
               "URL '\(url)' should be \(shouldBeValid ? "valid" : "invalid") for Google Sheets")
    }

    @Test("String.googleSheetsDocumentID extracts document IDs from approved Google Sheets URL formats",
          arguments: [
              ("https://docs.google.com/spreadsheets/d/e/2PACX-1vTest12345/pubhtml", "2PACX-1vTest12345"),
              ("https://docs.google.com/spreadsheets/d/e/2PACX-1vTest12345/pub?output=csv", "2PACX-1vTest12345"),
              ("https://docs.google.com/spreadsheets/d/e/abc123xyz/pubhtml", "abc123xyz"),
              ("https://docs.google.com/spreadsheets/d/e/long-document-id-12345/pub?output=csv", "long-document-id-12345"),
              ("https://docs.google.com/spreadsheets/d/1a2b3c4d-5e6f/edit#gid=0", nil),
              ("https://docs.google.com/spreadsheets/d/abc123xyz/pubhtml", nil),
              ("https://docs.google.com/spreadsheets/d/", nil),
              ("https://google.com", nil),
              ("", nil),
              ("https://docs.google.com/documents/d/123/edit", nil)
          ])
    func googleSheetsDocumentIDExtraction(url: String, expectedID: String?) {
        #expect(url.googleSheetsDocumentID == expectedID,
               "URL '\(url)' should extract document ID '\(expectedID ?? "nil")'")
    }

    @Test("String.csvEscaped properly escapes CSV special characters",
          arguments: [
              ("hello", "hello"),
              ("simple", "simple"),
              ("123", "123"),
              ("hello,world", "\"hello,world\""),
              ("a,b,c", "\"a,b,c\""),
              ("hello\"world", "\"hello\"\"world\""),
              ("\"quoted\"", "\"\"\"quoted\"\"\""),
              ("hello\nworld", "\"hello\nworld\""),
              ("hello,world\"test\n", "\"hello,world\"\"test\n\"")
          ])
    func csvEscapingValidation(input: String, expected: String) {
        #expect(input.csvEscaped == expected,
               "String '\(input)' should escape to '\(expected)'")
    }

    @Test("String.isValidLocalizationKey validates localization key format rules",
          arguments: [
              ("valid.key_1", true),
              ("common_button_title", true),
              ("a", true),
              ("login.title.text", true),
              ("settings_notification_sound", true),
              ("profile-user-name", true),
              ("key with space", true),
              ("", false),
              (" key", false),
              ("key ", false),
              ("key\"", false),
              ("key\n", false)
          ])
    func localizationKeyValidation(key: String, shouldBeValid: Bool) {
        #expect(key.isValidLocalizationKey == shouldBeValid,
               "Localization key '\(key)' should be \(shouldBeValid ? "valid" : "invalid")")
    }

    @Test("String.invalidLocalizationKeyReason provides descriptive error messages for invalid keys",
          arguments: [
              ("valid_key", nil),
              ("another.valid_key", nil),
              ("single_a", nil),
              ("", "Key is empty"),
              (" key", "Key starts with a space"),
              ("key ", "Key ends with a space"), 
              ("key\"", "Key contains a double quote (\")"),
              ("key\n", "Key contains a newline")
          ])
    func localizationKeyErrorReasons(key: String, expectedReason: String?) {
        #expect(key.invalidLocalizationKeyReason == expectedReason,
               "Key '\(key)' should have error reason '\(expectedReason ?? "nil")'")
    }

    // MARK: - Array Extension Tests

    @Test("Array.csvRow formats string arrays as properly escaped CSV rows")
    func arrayCsvRowFormatting() {
        let simpleRow = ["hello", "world"]
        #expect(simpleRow.csvRow == "hello,world", 
               "Simple array should format without quotes")
        
        let complexRow = ["hello", "world, with comma", "quotes\"here", "newline\nhere"]
        let expected = "hello,\"world, with comma\",\"quotes\"\"here\",\"newline\nhere\""
        #expect(complexRow.csvRow == expected,
               "Complex array should properly escape CSV special characters")
        
        let emptyRow: [String] = []
        #expect(emptyRow.csvRow == "", "Empty array should produce empty string")
        
        let singleRow = ["single"]
        #expect(singleRow.csvRow == "single", "Single element should not have comma")
    }

    @Test("Array.csvContent converts 2D string arrays to complete CSV format")
    func arrayCsvContentGeneration() {
        let basicRows = [
            ["h1", "h2"],
            ["r1c1", "r1c2"]
        ]
        #expect(basicRows.csvContent == "h1,h2\nr1c1,r1c2",
               "Basic 2D array should format with newline separation")
        
        let singleRowArray = [["single", "row"]]
        #expect(singleRowArray.csvContent == "single,row",
               "Single row array should not have trailing newline")
        
        let emptyRows: [[String]] = []
        #expect(emptyRows.csvContent == "", "Empty 2D array should produce empty string")
        
        let mixedRows = [
            ["Name", "Description", "Value"],
            ["Test Item", "Contains, comma", "Has \"quotes\""]
        ]
        let expectedMixed = [
            ["Name", "Description", "Value"].csvRow,
            ["Test Item", "Contains, comma", "Has \"quotes\""].csvRow
        ].joined(separator: "\n")
        
        #expect(mixedRows.csvContent == expectedMixed,
               "Mixed content should properly escape special characters")
    }

    // MARK: - FileManager Extension Tests

    @Test("FileManager.createDirectoryIfNeeded creates directories safely without errors if they already exist")
    func fileManagerDirectoryCreation() throws {
        let fileManager = FileManager.default
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let testPath = tempDir.appendingPathComponent("testDir").path

        try? fileManager.removeItem(at: tempDir)
        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        try fileManager.createDirectoryIfNeeded(atPath: testPath)
        #expect(fileManager.fileExists(atPath: testPath) == true, 
               "Directory should be created successfully")
        
        try fileManager.createDirectoryIfNeeded(atPath: testPath)
        #expect(fileManager.fileExists(atPath: testPath) == true,
               "Directory should still exist after second creation attempt")
    }
    
    @Test("FileManager.safeRemoveItem removes files and directories safely, returning appropriate status")
    func fileManagerSafeRemoval() throws {
        let fileManager = FileManager.default
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let testPath = tempDir.appendingPathComponent("testDir").path

        try? fileManager.removeItem(at: tempDir)
        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        try fileManager.createDirectoryIfNeeded(atPath: testPath)
        #expect(fileManager.fileExists(atPath: testPath) == true,
               "Test directory should exist before removal")

        let removed = try fileManager.safeRemoveItem(atPath: testPath)
        #expect(removed == true, "First removal should return true")
        #expect(fileManager.fileExists(atPath: testPath) == false,
               "Directory should no longer exist after removal")

        let removedAgain = try fileManager.safeRemoveItem(atPath: testPath)
        #expect(removedAgain == false, 
               "Second removal attempt should return false (file already gone)")
    }
}

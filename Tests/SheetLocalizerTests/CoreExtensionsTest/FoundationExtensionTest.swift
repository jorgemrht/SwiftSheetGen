import Testing
import Foundation
@testable import CoreExtensions

@Suite
struct FoundationExtensionTest {
    
    // MARK: - String Extension Tests
    
    @Test("String.isEmptyOrWhitespace correctly identifies empty and whitespace-only strings",
          arguments: [
              ("", true),
              ("   ", true),
              ("\t\n\r ", true),
              ("hello", false),
              ("  hello  ", false),
              ("a", false)
          ])
    func stringEmptyOrWhitespaceValidation(input: String, expectedEmpty: Bool) {
        #expect(input.isEmptyOrWhitespace == expectedEmpty)
    }
    
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
        #expect(input.trimmedContent == expected)
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
        #expect(url.isGoogleSheetsURL == shouldBeValid)
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
        #expect(url.googleSheetsDocumentID == expectedID)
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
        #expect(input.csvEscaped == expected)
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
        #expect(key.isValidLocalizationKey == shouldBeValid)
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
        #expect(key.invalidLocalizationKeyReason == expectedReason)
    }
    
    // MARK: - Array Extension Tests
    
    @Test("Array.csvRow formats string arrays as properly escaped CSV rows")
    func arrayCsvRowFormatting() {
        let simpleRow = ["hello", "world"]
        #expect(simpleRow.csvRow == "hello,world")
        
        let complexRow = ["hello", "world, with comma", "quotes\"here", "newline\nhere"]
        let expected = "hello,\"world, with comma\",\"quotes\"\"here\",\"newline\nhere\""
        #expect(complexRow.csvRow == expected)
        
        let emptyRow: [String] = []
        #expect(emptyRow.csvRow == "")
        
        let singleRow = ["single"]
        #expect(singleRow.csvRow == "single")
    }
    
    @Test("Array.csvContent converts 2D string arrays to complete CSV format")
    func arrayCsvContentGeneration() {
        let basicRows = [
            ["h1", "h2"],
            ["r1c1", "r1c2"]
        ]
        #expect(basicRows.csvContent == "h1,h2\nr1c1,r1c2")
        
        let singleRowArray = [["single", "row"]]
        #expect(singleRowArray.csvContent == "single,row")
        
        let emptyRows: [[String]] = []
        #expect(emptyRows.csvContent == "")
        
        let mixedRows = [
            ["Name", "Description", "Value"],
            ["Test Item", "Contains, comma", "Has \"quotes\""]
        ]
        let expectedMixed = [
            ["Name", "Description", "Value"].csvRow,
            ["Test Item", "Contains, comma", "Has \"quotes\""].csvRow
        ].joined(separator: "\n")
        
        #expect(mixedRows.csvContent == expectedMixed)
    }
    
    // MARK: - FileManager Extension Tests
    
    @Test("FileManager.createDirectoryIfNeeded creates directories safely")
    func fileManagerDirectoryCreation() throws {
        let fileManager = FileManager.default
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let testPath = tempDir.appendingPathComponent("testDir").path
        
        try? fileManager.removeItem(at: tempDir)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        try fileManager.createDirectoryIfNeeded(atPath: testPath)
        #expect(fileManager.fileExists(atPath: testPath))
        
        try fileManager.createDirectoryIfNeeded(atPath: testPath)
        #expect(fileManager.fileExists(atPath: testPath))
    }
    
    @Test("FileManager.safeRemoveItem removes files and directories safely")
    func fileManagerSafeRemoval() throws {
        let fileManager = FileManager.default
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let testPath = tempDir.appendingPathComponent("testDir").path
        
        try? fileManager.removeItem(at: tempDir)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        try fileManager.createDirectoryIfNeeded(atPath: testPath)
        #expect(fileManager.fileExists(atPath: testPath))
        
        let removed = try fileManager.safeRemoveItem(atPath: testPath)
        #expect(removed == true)
        #expect(fileManager.fileExists(atPath: testPath) == false)
        
        let removedAgain = try fileManager.safeRemoveItem(atPath: testPath)
        #expect(removedAgain == false)
    }
    
    @Test("FileManager extensions handle invalid paths appropriately")
    func fileManagerInvalidPaths() {
        let fileManager = FileManager.default
        
        #expect(throws: FileManagerError.self) {
            try fileManager.createDirectoryIfNeeded(atPath: "")
        }
        
        #expect(throws: FileManagerError.self) {
            try fileManager.createDirectoryIfNeeded(atPath: "   ")
        }
    }
    
    @Test("FileManager extensions handle path conflicts appropriately")
    func fileManagerPathConflicts() throws {
        let fileManager = FileManager.default
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let conflictPath = tempDir.appendingPathComponent("conflict.txt").path
        
        try? fileManager.removeItem(at: tempDir)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let url = URL(fileURLWithPath: conflictPath)
        try "test content".write(to: url, atomically: true, encoding: .utf8)
        #expect(fileManager.fileExists(atPath: conflictPath))
        
        #expect(throws: FileManagerError.pathExistsButNotDirectory.self) {
            try fileManager.createDirectoryIfNeeded(atPath: conflictPath)
        }
    }
    
    @Test("FileManager.createDirectoryIfNeeded respects createIntermediates parameter")
    func fileManagerCreateIntermediatesParameter() throws {
        let fileManager = FileManager.default
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let deepPath = tempDir.appendingPathComponent("level1/level2/level3").path
        
        try? fileManager.removeItem(at: tempDir)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        try fileManager.createDirectoryIfNeeded(atPath: deepPath, createIntermediates: true)
        #expect(fileManager.fileExists(atPath: deepPath))
        
        try fileManager.removeItem(at: tempDir)
        
        #expect(throws: (any Error).self) {
            try fileManager.createDirectoryIfNeeded(atPath: deepPath, createIntermediates: false)
        }
    }
    
    // MARK: - FileManagerError Tests
    
    @Test("FileManagerError provides descriptive error messages")
    func fileManagerErrorMessages() {
        #expect(FileManagerError.invalidPath.errorDescription == "The provided path is invalid or empty")
        #expect(FileManagerError.pathExistsButNotDirectory.errorDescription == "Path exists but is not a directory")
    }
    
    // MARK: - Edge Cases and Additional Coverage Tests
    
    @Test("String extensions handle edge cases correctly")
    func stringExtensionEdgeCases() {
        let veryLongString = String(repeating: "a", count: 10000)
        #expect(!veryLongString.isEmptyOrWhitespace)
        #expect(veryLongString.trimmedContent == veryLongString)
        #expect(!veryLongString.isGoogleSheetsURL)
        #expect(veryLongString.isValidLocalizationKey)
        
        let unicodeString = "Hello 🌍 World"
        #expect(!unicodeString.isEmptyOrWhitespace)
        #expect(unicodeString.trimmedContent == unicodeString)
        #expect(unicodeString.isValidLocalizationKey)
        
        let csvWithUnicode = unicodeString.csvEscaped
        #expect(csvWithUnicode == unicodeString)
    }
    
    @Test("String.isGoogleSheetsURL handles whitespace edge cases")
    func googleSheetsURLWhitespaceHandling() {
        let validURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1v123/pubhtml"
        let urlWithWhitespace = "  \(validURL)  "
        let urlWithTabs = "\t\(validURL)\t"
        let urlWithNewlines = "\n\(validURL)\n"
        
        #expect(urlWithWhitespace.isGoogleSheetsURL == true)
        #expect(urlWithTabs.isGoogleSheetsURL == true) 
        #expect(urlWithNewlines.isGoogleSheetsURL == true)
    }
    
    @Test("String.googleSheetsDocumentID handles malformed URLs")
    func googleSheetsDocumentIDMalformedURLs() {
        let malformedURLs = [
            "https://docs.google.com/spreadsheets/d/e/",
            "https://docs.google.com/spreadsheets/d/e//pubhtml", 
            "https://docs.google.com/spreadsheets/d/e/123",
            "https://docs.google.com/spreadsheets/d/123/pubhtml"
        ]
        
        for url in malformedURLs {
            #expect(url.googleSheetsDocumentID == nil)
        }
    }
    
    @Test("String.csvEscaped handles combined special characters")
    func csvEscapedCombinedSpecialChars() {
        let complexString = "Hello,\"World\"\nNew Line,\tTab"
        let escaped = complexString.csvEscaped
        #expect(escaped == "\"Hello,\"\"World\"\"\nNew Line,\tTab\"")
        
        let onlyComma = "Hello,World"
        #expect(onlyComma.csvEscaped == "\"Hello,World\"")
        
        let onlyQuote = "Hello\"World"  
        #expect(onlyQuote.csvEscaped == "\"Hello\"\"World\"")
        
        let onlyNewline = "Hello\nWorld"
        #expect(onlyNewline.csvEscaped == "\"Hello\nWorld\"")
    }
    
    @Test("Array extensions handle large datasets efficiently")
    func arrayExtensionPerformance() {
        let largeRow = Array(0..<1000).map { "item\($0)" }
        let result = largeRow.csvRow
        #expect(result.contains("item0,item1"))
        #expect(result.contains("item999"))
        
        let largeMatrix = Array(0..<100).map { _ in largeRow }
        let csvContent = largeMatrix.csvContent
        #expect(csvContent.contains("item0,item1"))
        #expect(csvContent.components(separatedBy: "\n").count == 100)
    }
}

import Testing
import Foundation
@testable import CoreExtensions

struct CoreExtensionsTests {

    // MARK: - String Extension Tests

    @Test("String.trimmedContent")
    func test_stringTrimming() {
        #expect("  hello  ".trimmedContent == "hello")
        #expect("\nworld\t".trimmedContent == "world")
        #expect("no-whitespace".trimmedContent == "no-whitespace")
    }

    @Test("String.isGoogleSheetsURL")
    func test_isGoogleSheetsURL() {
        #expect("https://docs.google.com/spreadsheets/d/some-id/edit".isGoogleSheetsURL == true)
        #expect("http://docs.google.com/spreadsheets/d/some-id/pubhtml".isGoogleSheetsURL == true)
        #expect("https://google.com".isGoogleSheetsURL == false)
        #expect("".isGoogleSheetsURL == false)
    }

    @Test("String.googleSheetsDocumentID with edge cases")
    func test_googleSheetsDocumentID() {
        let standardURL = "https://docs.google.com/spreadsheets/d/1a2b3c4d-5e6f/edit#gid=0"
        #expect(standardURL.googleSheetsDocumentID == "1a2b3c4d-5e6f")
        
        let exportURL = "https://docs.google.com/spreadsheets/d/1a2b3c4d-5e6f/export?format=csv"
        #expect(exportURL.googleSheetsDocumentID == "1a2b3c4d-5e6f")

        let noIDURL = "https://docs.google.com/spreadsheets/d/"
        #expect(noIDURL.googleSheetsDocumentID == nil)

        let invalidURL = "https://google.com"
        #expect(invalidURL.googleSheetsDocumentID == nil)
    }

    @Test("String.csvEscaped")
    func test_csvEscaped() {
        #expect("hello".csvEscaped == "hello")
        #expect("hello,world".csvEscaped == "\"hello,world\"")
        #expect("hello\"world".csvEscaped == "\"hello\"\"world\"")
        #expect("hello\nworld".csvEscaped == "\"hello\nworld\"")
    }

    @Test("String.isValidLocalizationKey with edge cases")
    func test_isValidLocalizationKey() {
        // Valid cases
        #expect("valid.key_1".isValidLocalizationKey == true)
        #expect("common_button_title".isValidLocalizationKey == true)
        #expect("a".isValidLocalizationKey == true)

        // Invalid cases
        #expect("".isValidLocalizationKey == false)
        #expect(" key".isValidLocalizationKey == false)
        #expect("key ".isValidLocalizationKey == false)
        #expect("key\"".isValidLocalizationKey == false)
        #expect("key\n".isValidLocalizationKey == false)
        #expect("key with space".isValidLocalizationKey == true) // This might be unexpected, let's check the implementation. Ah, it only checks for prefix/suffix space.
    }

    @Test("String.invalidLocalizationKeyReason")
    func test_invalidLocalizationKeyReason() {
        #expect("valid_key".invalidLocalizationKeyReason == nil)
        #expect("".invalidLocalizationKeyReason == "Key is empty")
        #expect(" key".invalidLocalizationKeyReason == "Key starts with a space")
        #expect("key ".invalidLocalizationKeyReason == "Key ends with a space")
        #expect("key\"".invalidLocalizationKeyReason == "Key contains a double quote (\")")
        #expect("key\n".invalidLocalizationKeyReason == "Key contains a newline")
    }

    // MARK: - Array Extension Tests

    @Test("Array.csvRow")
    func test_arrayCsvRow() {
        let row = ["hello", "world, with comma", "quotes\"here"]
        #expect(row.csvRow == "hello,\"world, with comma\",\"quotes\"\"here\"")
    }

    @Test("Array.csvContent")
    func test_arrayCsvContent() {
        let rows = [
            ["h1", "h2"],
            ["r1c1", "r1c2"]
        ]
        #expect(rows.csvContent == "h1,h2\nr1c1,r1c2")
    }

    // MARK: - FileManager Extension Tests

    @Test("FileManager.createDirectoryIfNeeded & safeRemoveItem")
    func test_fileManagerExtensions() throws {
        let fileManager = FileManager.default
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let testPath = tempDir.appendingPathComponent("testDir").path

        // Clean up in case of previous failed runs
        try? fileManager.removeItem(at: tempDir)

        // Defer cleanup
        defer {
            try? fileManager.removeItem(at: tempDir)
        }

        // Test creation
        try fileManager.createDirectoryIfNeeded(atPath: testPath)
        #expect(fileManager.fileExists(atPath: testPath) == true)

        // Test removal
        let removed = try fileManager.safeRemoveItem(atPath: testPath)
        #expect(removed == true)
        #expect(fileManager.fileExists(atPath: testPath) == false)

        // Test removing non-existent item
        let removedAgain = try fileManager.safeRemoveItem(atPath: testPath)
        #expect(removedAgain == false)
    }
}

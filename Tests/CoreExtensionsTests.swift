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

    @Test("String.googleSheetsDocumentID")
    func test_googleSheetsDocumentID() {
        let url = "https://docs.google.com/spreadsheets/d/1a2b3c4d-5e6f/edit#gid=0"
        #expect(url.googleSheetsDocumentID == "1a2b3c4d-5e6f")
        #expect("https://google.com".googleSheetsDocumentID == nil)
    }

    @Test("String.csvEscaped")
    func test_csvEscaped() {
        #expect("hello".csvEscaped == "hello")
        #expect("hello,world".csvEscaped == "\"hello,world\"")
        #expect("hello\"world".csvEscaped == "\"hello\"\"world\"")
        #expect("hello\nworld".csvEscaped == "\"hello\nworld\"")
    }

    @Test("String.isValidLocalizationKey")
    func test_isValidLocalizationKey() {
        #expect("valid.key_1".isValidLocalizationKey == true)
        #expect("".isValidLocalizationKey == false)
        #expect(" key".isValidLocalizationKey == false)
        #expect("key ".isValidLocalizationKey == false)
        #expect("key\"".isValidLocalizationKey == false)
        #expect("key\n".isValidLocalizationKey == false)
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
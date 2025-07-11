import Testing
@testable import SheetLocalizer

@Suite()
struct GoogleSheetURLTransformerTests {

    @Test("Transform standard URL to CSV")
    func test_transform_standardURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/12345"
        let expected = "https://docs.google.com/spreadsheets/d/12345/pub?output=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }

    @Test("Transform URL with trailing slash to CSV")
    func test_transform_trailingSlashURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/12345/"
        let expected = "https://docs.google.com/spreadsheets/d/12345/pub?output=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }

    @Test("Transform /pubhtml URL to CSV")
    func test_transform_pubhtmlURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/e/some-long-id/pubhtml"
        let expected = "https://docs.google.com/spreadsheets/d/e/some-long-id/pub?output=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }
    
    @Test("Do not transform already correct CSV URL")
    func test_transform_alreadyCSVURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/e/some-long-id/pub?output=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == url)
    }
    
    @Test("Do not transform already correct export format URL")
    func test_transform_alreadyExportURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/12345/export?format=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == url)
    }

    @Test("Throws error for invalid or non-Google Sheets URLs")
    func test_transform_invalidInput() {
        #expect(throws: (any Error).self) {
            _ = try GoogleSheetURLTransformer.transformToCSV("")
        }
        #expect(throws: (any Error).self) {
            _ = try GoogleSheetURLTransformer.transformToCSV("ummmm.com")
        }
        #expect(throws: (any Error).self) {
            _ = try GoogleSheetURLTransformer.transformToCSV("https://www.google.com")
        }
    }
}

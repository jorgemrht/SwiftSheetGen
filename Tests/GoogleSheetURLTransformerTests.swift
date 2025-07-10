import Testing
@testable import SheetLocalizer

struct GoogleSheetURLTransformerTests {

    @Test("Transform standard URL to CSV")
    func test_transform_standardURL() {
        let url = "https://docs.google.com/spreadsheets/d/12345"
        let expected = "https://docs.google.com/spreadsheets/d/12345/pub?output=csv"
        #expect(GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }

    @Test("Transform URL with trailing slash to CSV")
    func test_transform_trailingSlashURL() {
        let url = "https://docs.google.com/spreadsheets/d/12345/"
        let expected = "https://docs.google.com/spreadsheets/d/12345/pub?output=csv"
        #expect(GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }

    @Test("Transform /pubhtml URL to CSV")
    func test_transform_pubhtmlURL() {
        let url = "https://docs.google.com/spreadsheets/d/e/some-long-id/pubhtml"
        let expected = "https://docs.google.com/spreadsheets/d/e/some-long-id/pub?output=csv"
        #expect(GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }
    
    @Test("Do not transform already correct CSV URL")
    func test_transform_alreadyCSVURL() {
        let url = "https://docs.google.com/spreadsheets/d/e/some-long-id/pub?output=csv"
        #expect(GoogleSheetURLTransformer.transformToCSV(url) == url)
    }
    
    @Test("Do not transform already correct export format URL")
    func test_transform_alreadyExportURL() {
        let url = "https://docs.google.com/spreadsheets/d/12345/export?format=csv"
        #expect(GoogleSheetURLTransformer.transformToCSV(url) == url)
    }

    @Test("Handle empty or invalid strings")
    func test_transform_invalidInput() {
        #expect(GoogleSheetURLTransformer.transformToCSV("") == "")
        #expect(GoogleSheetURLTransformer.transformToCSV("not a url") == "not a url/pub?output=csv")
    }
}

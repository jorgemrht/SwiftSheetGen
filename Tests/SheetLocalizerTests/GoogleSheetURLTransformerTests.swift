import Testing
@testable import SheetLocalizer

@Suite()
struct GoogleSheetURLTransformerTests {

    @Test
    func test_transform_standardURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/12345"
        let expected = "https://docs.google.com/spreadsheets/d/12345/pub?output=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }

    @Test
    func test_transform_trailingSlashURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/12345/"
        let expected = "https://docs.google.com/spreadsheets/d/12345/pub?output=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }

    @Test
    func test_transform_pubhtmlURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml"
        let expected = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == expected)
    }
    
    @Test
    func test_transform_alreadyCSVURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == url)
    }
    
    @Test
    func test_transform_alreadyExportURL() throws {
        let url = "https://docs.google.com/spreadsheets/d/12345/export?format=csv"
        #expect(try GoogleSheetURLTransformer.transformToCSV(url) == url)
    }

    @Test
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

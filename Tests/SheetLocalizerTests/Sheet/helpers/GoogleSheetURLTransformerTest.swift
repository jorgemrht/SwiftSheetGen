import Testing
@testable import SheetLocalizer

@Suite("GoogleSheetURLTransformer Tests")
struct GoogleSheetURLTransformerTest {

    @Test("GoogleSheetURLTransformer converts approved Google Sheets URL formats to CSV download URLs",
          arguments: [
              ("https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml",
               "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"),
              ("https://docs.google.com/spreadsheets/d/e/2PACX-1vTest12345/pubhtml",
               "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest12345/pub?output=csv")
          ])
    func googleSheetsURLTransformation(input: String, expected: String) throws {
        let result = try GoogleSheetURLTransformer.transformToCSV(input)
        #expect(result == expected,
               "URL '\(input)' should transform to '\(expected)' but got '\(result)'")
    }
    
    @Test("GoogleSheetURLTransformer preserves already valid CSV download URLs",
          arguments: [
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv",
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest12345/pub?output=csv"
          ])
    func csvURLPreservation(url: String) throws {
        let result = try GoogleSheetURLTransformer.transformToCSV(url)
        #expect(result == url,
               "Already valid CSV URL should remain unchanged: '\(url)'")
    }

    @Test("GoogleSheetURLTransformer rejects invalid URLs with appropriate errors",
          arguments: [
              "",
              "invalid-url",
              "ummmm.com",
              "https://www.google.com",
              "https://sheets.google.com/invalid",
              "https://docs.google.com/documents/d/123/edit",
              "https://example.com/spreadsheets/not-google",
              "not-a-url-at-all",
              "https://docs.google.com/spreadsheets/d/12345",
              "https://docs.google.com/spreadsheets/d/12345/edit",
              "https://docs.google.com/spreadsheets/d/12345/export?format=csv"
          ])
    func invalidURLRejection(invalidURL: String) {
        #expect(throws: (any Error).self) {
            _ = try GoogleSheetURLTransformer.transformToCSV(invalidURL)
        }
    }
}

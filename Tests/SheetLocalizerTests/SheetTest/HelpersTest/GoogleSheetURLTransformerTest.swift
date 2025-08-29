import Testing
@testable import SheetLocalizer

@Suite("GoogleSheetURLTransformer Tests")
struct GoogleSheetURLTransformerTest {

    @Test("GoogleSheetURLTransformer converts pubhtml URLs to CSV format")
    func pubhtmlURLTransformation() throws {
        let pubhtmlURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml"
        let expectedCSV = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
        
        let result = try GoogleSheetURLTransformer.transformToCSV(pubhtmlURL)
        #expect(result == expectedCSV)
    }
    
    @Test("GoogleSheetURLTransformer preserves CSV URLs unchanged")
    func csvURLPreservation() throws {
        let csvURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
        
        let result = try GoogleSheetURLTransformer.transformToCSV(csvURL)
        #expect(result == csvURL)
    }

    @Test("GoogleSheetURLTransformer rejects empty URLs")
    func emptyURLRejection() {
        #expect(throws: (any Error).self) {
            _ = try GoogleSheetURLTransformer.transformToCSV("")
        }
    }
    
    @Test("GoogleSheetURLTransformer rejects non-Google URLs")
    func nonGoogleURLRejection() {
        let invalidURLs = [
            "https://www.google.com",
            "https://example.com/spreadsheets/not-google",
            "invalid-url"
        ]
        
        for url in invalidURLs {
            #expect(throws: (any Error).self) {
                _ = try GoogleSheetURLTransformer.transformToCSV(url)
            }
        }
    }
    
    @Test("GoogleSheetURLTransformer rejects Google Docs URLs")
    func googleDocsURLRejection() {
        let docsURL = "https://docs.google.com/documents/d/123/edit"
        
        #expect(throws: (any Error).self) {
            _ = try GoogleSheetURLTransformer.transformToCSV(docsURL)
        }
    }
}

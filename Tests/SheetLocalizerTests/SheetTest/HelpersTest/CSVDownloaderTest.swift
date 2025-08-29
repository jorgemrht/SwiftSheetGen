import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct CSVDownloaderTest {
    
    @Test("CSVDownloader rejects empty URLs")
    func emptyURLValidation() async {
        let downloader = CSVDownloader()
        
        let isValid = await downloader.validateURL("")
        #expect(isValid == false)
    }
    
    @Test("CSVDownloader recognizes valid Google Sheets URLs",
          arguments: [
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml",
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
          ])
    func validGoogleSheetsURLRecognition(url: String) {
        #expect(CSVDownloader.isValidGoogleSheetURL(url))
    }
    
    @Test("CSVDownloader rejects invalid URLs",
          arguments: [
              "https://google.com",
              "https://docs.google.com/documents/d/123/edit",
              "https://sheets.google.com/invalid"
          ])
    func invalidURLRejection(url: String) {
        #expect(!CSVDownloader.isValidGoogleSheetURL(url))
    }
    
    @Test("CSVDownloader throws error for empty URL input")
    func emptyURLInputValidation() async {
        let downloader = CSVDownloader()
        let tempDir = SharedTestData.createTempDirectory()
        let outputPath = tempDir.appendingPathComponent("output.csv").path
        
        await #expect(throws: SheetLocalizerError.self) {
            try await downloader.download(from: "", to: outputPath)
        }
    }
    
    @Test("CSVDownloader throws error for empty output path")
    func emptyOutputPathValidation() async {
        let downloader = CSVDownloader()
        let validURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml"
        
        await #expect(throws: SheetLocalizerError.self) {
            try await downloader.download(from: validURL, to: "")
        }
    }
    
    @Test("CSVDownloader creates default instance")
    func defaultInstanceCreation() {
        let downloader = CSVDownloader.createWithDefaults()
        #expect(type(of: downloader) == CSVDownloader.self)
    }
}

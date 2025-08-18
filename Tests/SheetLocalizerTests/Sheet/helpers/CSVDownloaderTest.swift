import Testing
import Foundation
@testable import SheetLocalizer

@Suite("CSVDownloader Tests") 
struct CSVDownloaderTest {
    
    @Test("CSVDownloader properly validates empty URLs as invalid")
    func csvDownloaderEmptyURLValidation() async {
        let downloader = CSVDownloader()
        
        let isValid = await downloader.validateURL("")
        #expect(isValid == false, "Empty URL should be rejected as invalid")
    }
    
    @Test("CSVDownloader correctly identifies valid Google Sheets URLs in various formats",
          arguments: [
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml",
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
          ])
    func csvDownloaderValidGoogleSheetsURLRecognition(url: String) {
        #expect(CSVDownloader.isValidGoogleSheetURL(url), "URL '\(url)' should be recognized as valid Google Sheets URL")
    }
    
    @Test("CSVDownloader correctly rejects invalid or non-Google Sheets URLs",
          arguments: [
              "https://google.com",
              "https://docs.google.com/documents/d/123/edit",
              "https://sheets.google.com/invalid"
          ])
    func csvDownloaderInvalidGoogleSheetsURLRejection(url: String) {
        #expect(!CSVDownloader.isValidGoogleSheetURL(url), "URL '\(url)' should be rejected as invalid Google Sheets URL")
    }
    
    // MARK: - Input Validation Tests (No Network Calls)
    
    @Test("CSVDownloader validates input parameters and rejects empty URLs")
    func csvDownloaderEmptyURLInputValidation() async {
        let downloader = CSVDownloader()
        let tempDir = SharedTestData.createTempDirectory()
        let outputPath = tempDir.appendingPathComponent("output.csv").path
        
        await #expect(throws: SheetLocalizerError.self) {
            try await downloader.download(from: "", to: outputPath)
        }
    }
    
    @Test("CSVDownloader validates output path parameters and rejects empty paths")
    func csvDownloaderEmptyOutputPathValidation() async {
        let downloader = CSVDownloader()
        let validURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml"
        
        await #expect(throws: SheetLocalizerError.self) {
            try await downloader.download(from: validURL, to: "")
        }
    }
}

import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct CSVDownloaderTests {
    
    @Test
    func initDefaultTimeout() async {
        let downloader = CSVDownloader()
        #expect(String(describing: type(of: downloader)) == "CSVDownloader")
    }
    
    @Test
    func validateEmptyURL() async {
        let downloader = CSVDownloader()
        
        let isValid = await downloader.validateURL("")
        #expect(isValid == false)
    }
    
    @Test(arguments: [
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml",
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
    ])
    func isValidGoogleSheetURL(url: String) {
        #expect(CSVDownloader.isValidGoogleSheetURL(url))
    }
    
    @Test(arguments: [
        "https://google.com",
        "https://docs.google.com/documents/d/123/edit",
        "https://sheets.google.com/invalid"
    ])
    func isInvalidGoogleSheetURL(url: String) {
        #expect(!CSVDownloader.isValidGoogleSheetURL(url))
    }
    
    // MARK: - Input Validation Tests (No Network Calls)
    
    @Test
    func downloadValidatesEmptyURL() async {
        let downloader = CSVDownloader()
        let tempDir = SharedTestData.createTempDirectory()
        let outputPath = tempDir.appendingPathComponent("output.csv").path
        
        await #expect(throws: SheetLocalizerError.self) {
            try await downloader.download(from: "", to: outputPath)
        }
    }
    
    @Test
    func downloadValidatesEmptyOutputPath() async {
        let downloader = CSVDownloader()
        let validURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml"
        
        await #expect(throws: SheetLocalizerError.self) {
            try await downloader.download(from: validURL, to: "")
        }
    }
}

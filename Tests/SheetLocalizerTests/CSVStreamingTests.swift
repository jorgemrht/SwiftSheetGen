import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct CSVStreamingTests {
    
    @Test
    func streamingParserRealLocalization() async throws {
        let tempFile = createTempFile(content: SharedTestData.localizationCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = try await CSVParser.parseStream(fileURL: tempFile)
        
        #expect(result.count > 0)
        #expect(result[0].count == 7)
        
        let dataRows = result.filter { $0.first != "[END]" && $0.first != "[Check]" && $0.count >= 7 }
        #expect(dataRows.count >= 1) // At least some data rows
    }
    
    private func createTempFile(content: String) -> URL {
        SharedTestData.createTempFile(content: content)
    }
}

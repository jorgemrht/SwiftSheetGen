import Testing
import Foundation
@testable import SheetLocalizer

@Suite("ColorGenerator Tests")
struct ColorGeneratorTest {
    
    @Test("ColorGenerator successfully processes CSV data and generates complete color files")
    func colorGeneratorValidProcessingAndFileGeneration() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try SharedTestData.colorsCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        let colorDynamicFile = tempDir.appendingPathComponent("Color+Dynamic.swift")
        
        #expect(FileManager.default.fileExists(atPath: colorsFile.path))
        #expect(FileManager.default.fileExists(atPath: colorDynamicFile.path))
        
        let colorsContent = try String(contentsOf: colorsFile, encoding: .utf8)
        let dynamicContent = try String(contentsOf: colorDynamicFile, encoding: .utf8)
        
        #expect(colorsContent.contains("import SwiftUI"))
        #expect(colorsContent.contains("extension Color"))
        #expect(colorsContent.contains("primaryBackgroundColor"))
        
        #expect(dynamicContent.contains("import SwiftUI"))
        #expect(dynamicContent.contains("extension Color"))
        #expect(dynamicContent.contains("init(light:") || dynamicContent.contains("userInterfaceStyle"))
    }
    
    @Test("ColorGenerator handles various error conditions appropriately",
          arguments: [
              ("/non/existent/file.csv", "non-existent"),
              ("invalid,csv,data\nno,header,found", "invalid-header"),
              ("Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]", "insufficient-data"),
              ("Items a revisar,,,,,Desc\nCheck,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]\n,[COMMENT],[ANY HEX VALUE],[Light HEX VALUE],[DARK HEX VALUE],Common\n[END],,,,, ", "no-valid-entries")
          ])
    func colorGeneratorErrorHandling(csvContent: String, errorType: String) async {
        let generator = ColorGenerator()
        
        if errorType == "non-existent" {
            await #expect(throws: (any Error).self) {
                try await generator.generate(from: csvContent)
            }
        } else {
            let tempFile = SharedTestData.createTempFile(content: csvContent)
            defer { try? FileManager.default.removeItem(at: tempFile) }
            
            await #expect(throws: SheetLocalizerError.self) {
                try await generator.generate(from: tempFile.path)
            }
        }
    }
    
    @Test("ColorGenerator filters invalid rows while preserving valid color definitions")
    func colorGeneratorSelectiveRowProcessing() async throws {
        let csvWithMixedRows = """
        Items a revisar,,,,,Desc
        Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
        ,[COMMENT],[ANY HEX VALUE],[Light HEX VALUE],[DARK HEX VALUE],Common
        ,primaryBackgroundColor,#FFF,#FFF,#FFF,Valid color
        ,,#AAA,#AAA,#AAA,Invalid empty name
        ,validColor,#BBB,#BBB,#BBB,Another valid color
        [END],,,,,
        """
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try csvWithMixedRows.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        let content = try String(contentsOf: colorsFile, encoding: .utf8)
        
        #expect(content.contains("primaryBackgroundColor"))
        #expect(content.contains("validColor"))
        #expect(!content.contains("Invalid empty name"))
    }
}

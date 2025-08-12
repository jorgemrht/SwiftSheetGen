import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct ColorGeneratorTests {
    
    @Test
    func generateThrowsErrorForNonExistentFile() async {
        let generator = ColorGenerator()
        
        await #expect(throws: (any Error).self) {
            try await generator.generate(from: "/non/existent/file.csv")
        }
    }
    
    @Test
    func generateThrowsErrorForInvalidCSV() async {
        let invalidCSV = """
        invalid,csv,data
        no,header,found
        """
        
        let tempFile = SharedTestData.createTempFile(content: invalidCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = ColorGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    @Test
    func generateThrowsErrorForInsufficientData() async {
        let insufficientCSV = """
        Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
        """
        
        let tempFile = SharedTestData.createTempFile(content: insufficientCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = ColorGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    @Test
    func generateSucceedsWithValidCSV() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try SharedTestData.colorsCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(
            outputDirectory: tempDir.path,
            cleanupTemporaryFiles: false
        )
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
    
    @Test
    func generateHandlesEmptyColorEntries() async {
        let csvWithNoValidEntries = """
        Items a revisar,,,,,Desc
        Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
        ,[COMMENT],[ANY HEX VALUE],[Light HEX VALUE],[DARK HEX VALUE],Common
        [END],,,,,
        """
        
        let tempFile = SharedTestData.createTempFile(content: csvWithNoValidEntries)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = ColorGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    @Test
    func generateSkipsRowsWithEmptyNames() async throws {
        let csvWithEmptyNames = """
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
        try csvWithEmptyNames.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(
            outputDirectory: tempDir.path,
            cleanupTemporaryFiles: false
        )
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        let content = try String(contentsOf: colorsFile, encoding: .utf8)
        
        #expect(content.contains("primaryBackgroundColor"))
        #expect(content.contains("validColor"))
        #expect(!content.contains("Invalid empty name"))
    }
}

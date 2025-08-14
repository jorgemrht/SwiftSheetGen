import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct ColorGeneratorTests {
    
    @Test("ColorGenerator throws appropriate error when attempting to process non-existent CSV files")
    func colorGeneratorNonExistentFileHandling() async {
        let generator = ColorGenerator()
        
        await #expect(throws: (any Error).self) {
            try await generator.generate(from: "/non/existent/file.csv")
        }
    }
    
    @Test("ColorGenerator rejects CSV files with invalid header structure for color generation")
    func colorGeneratorInvalidCSVHeaderRejection() async {
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
    
    @Test("ColorGenerator validates CSV content and rejects files with headers but no color data")
    func colorGeneratorInsufficientDataValidation() async {
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
    
    @Test("ColorGenerator successfully processes valid CSV data and generates SwiftUI color extensions")
    func colorGeneratorValidCSVProcessingAndFileGeneration() async throws {
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
        
        #expect(FileManager.default.fileExists(atPath: colorsFile.path), "Colors.swift file should be generated")
        #expect(FileManager.default.fileExists(atPath: colorDynamicFile.path), "Color+Dynamic.swift file should be generated")
        
        let colorsContent = try String(contentsOf: colorsFile, encoding: .utf8)
        let dynamicContent = try String(contentsOf: colorDynamicFile, encoding: .utf8)
        
        #expect(colorsContent.contains("import SwiftUI"), "Generated colors file should import SwiftUI")
        #expect(colorsContent.contains("extension Color"), "Generated colors should extend Color")
        #expect(colorsContent.contains("primaryBackgroundColor"), "Color definitions from CSV should be included")
        
        #expect(dynamicContent.contains("import SwiftUI"), "Dynamic color extensions should import SwiftUI")
        #expect(dynamicContent.contains("extension Color"), "Dynamic colors should extend Color")
        #expect(dynamicContent.contains("init(light:") || dynamicContent.contains("userInterfaceStyle"), "Dynamic colors should support light/dark mode functionality")
    }
    
    @Test("ColorGenerator appropriately handles CSV files with no valid color entries")
    func colorGeneratorEmptyColorEntriesHandling() async {
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
    
    @Test("ColorGenerator intelligently filters out invalid rows while preserving valid color definitions")
    func colorGeneratorSelectiveRowProcessing() async throws {
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
        
        #expect(content.contains("primaryBackgroundColor"), "Valid color entries should be included in generated code")
        #expect(content.contains("validColor"), "All valid color names should be processed")
        #expect(!content.contains("Invalid empty name"), "Rows with empty names should be excluded from generated code")
    }
}

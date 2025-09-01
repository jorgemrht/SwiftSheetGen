import Testing
import Foundation
@testable import SheetLocalizer

@Suite("ColorGenerator Tests")
struct ColorGeneratorTest {
    
    @Test
    func defaultInitialization() {
        let generator = ColorGenerator()
        #expect(type(of: generator) == ColorGenerator.self)
    }
    
    @Test
    func customInitialization() {
        let config = ColorConfig(outputDirectory: "/tmp/test", cleanupTemporaryFiles: true)
        let generator = ColorGenerator(config: config)
        #expect(type(of: generator) == ColorGenerator.self)
    }
    
    @Test
    func processesValidCSV() async throws {
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
    }
    
    @Test("ColorGenerator handles error conditions",
          arguments: [
              ("/non/existent/file.csv", "non-existent file"),
              ("", "empty path")
          ])
    func handlesErrors(csvPath: String, _: String) async {
        let generator = ColorGenerator()
        
        await #expect(throws: (any Error).self) {
            try await generator.generate(from: csvPath)
        }
    }
    
    @Test("ColorGenerator handles invalid CSV structures", 
          arguments: [
              ("invalid,csv,content\nno,proper,headers", "invalid headers"),
              ("Items a revisar,,,,,Desc\nCheck,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]", "insufficient data")
          ])
    func handlesInvalidCSV(csvContent: String, _: String) async {
        let tempFile = SharedTestData.createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = ColorGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    @Test
    func createsOutputDirectory() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let outputDir = tempDir.appendingPathComponent("nested/output/path")
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try SharedTestData.colorsCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(outputDirectory: outputDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        #expect(FileManager.default.fileExists(atPath: outputDir.path))
    }
    
    @Test("ColorGenerator respects cleanup configuration",
          arguments: [true, false])
    func respectsCleanupConfig(cleanupEnabled: Bool) async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try SharedTestData.colorsCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: cleanupEnabled)
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Colors.swift").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Color+Dynamic.swift").path))
    }
}
import Testing
import Foundation
@testable import SheetLocalizer

@Suite("ColorGenerator Tests")
struct ColorGeneratorTest {
    
    // MARK: - Test Default Initialization
    
    @Test("ColorGenerator initializes with default config")
    func colorGeneratorDefaultInitialization() {
        let generator = ColorGenerator()
        
        // Test passes if no exception is thrown during initialization
        #expect(type(of: generator) == ColorGenerator.self)
    }
    
    @Test("ColorGenerator initializes with custom config")
    func colorGeneratorCustomInitialization() {
        let config = ColorConfig(outputDirectory: "/tmp/test", cleanupTemporaryFiles: true)
        let generator = ColorGenerator(config: config)
        
        // Test passes if no exception is thrown during initialization
        #expect(type(of: generator) == ColorGenerator.self)
    }
    
    // MARK: - Test CSV Processing
    
    @Test("ColorGenerator processes valid CSV successfully")
    func colorGeneratorProcessesValidCSV() async throws {
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
        #expect(colorsContent.contains("import SwiftUI"))
        #expect(colorsContent.contains("extension Color"))
    }
    
    @Test("ColorGenerator handles non-existent CSV file")
    func colorGeneratorHandlesNonExistentCSV() async {
        let generator = ColorGenerator()
        
        await #expect(throws: (any Error).self) {
            try await generator.generate(from: "/non/existent/file.csv")
        }
    }
    
    @Test("ColorGenerator handles CSV with invalid structure")
    func colorGeneratorHandlesInvalidCSVStructure() async {
        let invalidCSV = "invalid,csv,content\nno,proper,headers"
        let tempFile = SharedTestData.createTempFile(content: invalidCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = ColorGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    @Test("ColorGenerator handles CSV with insufficient data")
    func colorGeneratorHandlesInsufficientData() async {
        let headerOnlyCSV = """
        Items a revisar,,,,,Desc
        Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
        """
        let tempFile = SharedTestData.createTempFile(content: headerOnlyCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = ColorGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    // MARK: - Test Row Processing
    
    @Test("ColorGenerator filters invalid rows correctly")
    func colorGeneratorFiltersInvalidRows() async throws {
        let csvWithMixedRows = """
        Items a revisar,,,,,Desc
        Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
        ,[COMMENT],[ANY HEX VALUE],[Light HEX VALUE],[DARK HEX VALUE],Common
        ,validColor,#FF0000,#FF0000,#FF0000,Valid color
        ,,#00FF00,#00FF00,#00FF00,Empty name - should be skipped
        ,[INVALID],#0000FF,#0000FF,#0000FF,Invalid bracket name - should be skipped
        ,emptyHexColor,,,,Empty hex values - should be skipped
        ,anotherValidColor,#FFFF00,#FFFF00,#FFFF00,Another valid color
        [END],,,,,
        """
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("mixed_colors.csv")
        try csvWithMixedRows.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        let content = try String(contentsOf: colorsFile, encoding: .utf8)
        
        // Should contain valid colors
        #expect(content.contains("validColor"))
        #expect(content.contains("anotherValidColor"))
        
        // Should not contain invalid/empty entries
        #expect(!content.contains("Empty name"))
        #expect(!content.contains("INVALID"))
        #expect(!content.contains("emptyHexColor"))
    }
    
    // MARK: - Test File Generation
    
    @Test("ColorGenerator generates both required files")
    func colorGeneratorGeneratesBothFiles() async throws {
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
        
        // Verify Colors.swift content
        #expect(colorsContent.contains("import SwiftUI"))
        #expect(colorsContent.contains("extension Color"))
        #expect(!colorsContent.isEmpty)
        
        // Verify Color+Dynamic.swift content
        #expect(dynamicContent.contains("import SwiftUI"))
        #expect(dynamicContent.contains("extension Color"))
        #expect(!dynamicContent.isEmpty)
    }
    
    // MARK: - Test Output Directory Creation
    
    @Test("ColorGenerator creates output directory if it doesn't exist")
    func colorGeneratorCreatesOutputDirectory() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let outputDir = tempDir.appendingPathComponent("nested/output/path")
        
        // Verify directory doesn't exist initially
        #expect(!FileManager.default.fileExists(atPath: outputDir.path))
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try SharedTestData.colorsCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(outputDirectory: outputDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        // Verify directory and files were created
        #expect(FileManager.default.fileExists(atPath: outputDir.path))
        #expect(FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("Colors.swift").path))
        #expect(FileManager.default.fileExists(atPath: outputDir.appendingPathComponent("Color+Dynamic.swift").path))
    }
    
    // MARK: - Test Tuist Project Detection
    
    @Test("ColorGenerator detects Tuist project correctly")
    func colorGeneratorDetectsTuistProject() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        // Create Project.swift file to simulate Tuist project
        let projectFile = tempDir.appendingPathComponent("Project.swift")
        try "// Tuist Project".write(to: projectFile, atomically: true, encoding: .utf8)
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try SharedTestData.colorsCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        // Should complete successfully (Tuist detection doesn't throw errors)
        try await generator.generate(from: csvFile.path)
        
        // Files should still be generated
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        let colorDynamicFile = tempDir.appendingPathComponent("Color+Dynamic.swift")
        
        #expect(FileManager.default.fileExists(atPath: colorsFile.path))
        #expect(FileManager.default.fileExists(atPath: colorDynamicFile.path))
    }
    
    // MARK: - Test Cleanup Configuration
    
    @Test("ColorGenerator respects cleanup configuration")
    func colorGeneratorRespectsCleanupConfig() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try SharedTestData.colorsCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        // Test with cleanup disabled
        let configNoCleanup = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: false)
        let generatorNoCleanup = ColorGenerator(config: configNoCleanup)
        
        try await generatorNoCleanup.generate(from: csvFile.path)
        
        // CSV file should still exist
        #expect(FileManager.default.fileExists(atPath: csvFile.path))
        
        // Generated files should exist
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Colors.swift").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Color+Dynamic.swift").path))
    }
}
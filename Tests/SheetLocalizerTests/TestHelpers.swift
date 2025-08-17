import Testing
import Foundation
import os.log
@testable import SheetLocalizer
@testable import CoreExtensions
@testable import SwiftSheetGenCLICore

// MARK: - Unified Test Helpers for SwiftSheetGen

@Suite
struct TestHelpers {
    
    // MARK: - Common Test Data
    
    enum TestValidation {
        static let validGoogleSheetsURLs = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pubhtml",
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQ_uwh3K0yVANXJuUpCS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv",
            "https://docs.google.com/spreadsheets/d/e/abc123def456/pubhtml",
            "https://docs.google.com/spreadsheets/d/e/simple-test-id/pub?output=csv"
        ]
        
        static let invalidURLs = [
            "",
            "not-a-url",
            "https://google.com",
            "https://sheets.google.com/invalid",
            "https://docs.google.com/documents/d/123/edit",
            "https://example.com/spreadsheets/not-google",
            "https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit#gid=0",
            "https://docs.google.com/spreadsheets/d/abc123def456/export?format=csv&gid=789",
            "https://docs.google.com/spreadsheets/d/simple-id/pub?output=csv"
        ]
        
        static let specialPathCharacters = [
            "path with spaces",
            "path-with-dashes_and_underscores",
            "path.with.dots",
            "path(with)parentheses",
            "path[with]brackets",
            "pathWithUnicode🚀émojis",
            "path_with_àccénts"
        ]
    }
    
    // MARK: - Test Environment Setup
    
    static func createIsolatedTestEnvironment() -> (baseDir: URL, cleanup: () -> Void) {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SwiftSheetGenTest_\(UUID().uuidString)")
        
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let cleanup: () -> Void = {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        return (tempDir, cleanup)
    }
    
    // MARK: - Configuration Test Helpers
    
    static func createTestLocalizationConfig(
        outputDir: String = "/test/output",
        enumName: String = "TestL10n",
        useStringsCatalog: Bool = false,
        cleanup: Bool = false
    ) -> LocalizationConfig {
        return LocalizationConfig.custom(
            outputDirectory: outputDir,
            enumName: enumName,
            sourceDirectory: outputDir,
            csvFileName: "test_localizations.csv",
            cleanupTemporaryFiles: cleanup,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: useStringsCatalog
        )
    }
    
    static func createTestColorConfig(
        outputDir: String = "/test/output",
        cleanup: Bool = false
    ) -> ColorConfig {
        return ColorConfig.custom(
            outputDirectory: outputDir,
            csvFileName: "test_colors.csv",
            cleanupTemporaryFiles: cleanup
        )
    }
    
    // MARK: - Validation Helpers
    
    static func validateGeneratedLocalizationFiles(
        at baseDir: URL,
        languages: [String],
        enumName: String,
        useStringsCatalog: Bool = false
    ) throws {
        if useStringsCatalog {
            let catalogFile = baseDir.appendingPathComponent("Localizable.xcstrings")
            #expect(FileManager.default.fileExists(atPath: catalogFile.path),
                   "Strings catalog should exist")
        } else {
            for language in languages {
                let langDir = baseDir.appendingPathComponent("\(language).lproj")
                let stringsFile = langDir.appendingPathComponent("Localizable.strings")
                
                #expect(FileManager.default.fileExists(atPath: langDir.path),
                       "Language directory \(language).lproj should exist")
                #expect(FileManager.default.fileExists(atPath: stringsFile.path),
                       "Strings file for \(language) should exist")
            }
            
            let enumFile = baseDir.appendingPathComponent("\(enumName).swift")
            #expect(FileManager.default.fileExists(atPath: enumFile.path),
                   "Enum file \(enumName).swift should exist")
        }
    }
    
    static func validateGeneratedColorFiles(at baseDir: URL) throws {
        let colorsFile = baseDir.appendingPathComponent("Colors.swift")
        let dynamicFile = baseDir.appendingPathComponent("Color+Dynamic.swift")
        
        #expect(FileManager.default.fileExists(atPath: colorsFile.path),
               "Colors.swift should exist")
        #expect(FileManager.default.fileExists(atPath: dynamicFile.path),
               "Color+Dynamic.swift should exist")
        
        let colorsContent = try String(contentsOf: colorsFile, encoding: .utf8)
        #expect(colorsContent.contains("import SwiftUI"),
               "Colors file should import SwiftUI")
        
        let dynamicContent = try String(contentsOf: dynamicFile, encoding: .utf8)
        #expect(dynamicContent.contains("extension Color"),
               "Dynamic file should extend Color")
    }
    
    // MARK: - Performance Testing Helpers
    
    static func measureGenerationPerformance<T>(
        operation: () async throws -> T,
        expectedMaxDuration: TimeInterval = 5.0
    ) async throws -> T {
        let startTime = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(duration < expectedMaxDuration,
               "Operation should complete within \(expectedMaxDuration) seconds, took \(duration)")
        
        return result
    }
    
    // MARK: - Test Data Helpers
    
    static func createTestCSVContent(
        type: TestDataType,
        includeProblematicData: Bool = false
    ) -> String {
        switch type {
        case .localization:
            var content = SharedTestData.localizationCSV
            if includeProblematicData {
                content += """
                \n"", "test", "with\"quotes", "text", "Test", "Test", "Test"
                "", "test", "with,comma", "text", "Test", "Test", "Test"
                "", "test", "empty_translation", "text", "", "", ""
                """
            }
            return content
            
        case .colors:
            var content = SharedTestData.colorsCSV
            if includeProblematicData {
                content += """
                \n,colorWithMissingHex,,,,"Missing hex values test"
                ,colorWithInvalidHex,#GGGGGG,#INVALID,#123,"Invalid hex test"
                ,"color,WithComma",#FFFFFF,#000000,#333333,"Comma in name test"
                """
            }
            return content
        }
    }
    
    enum TestDataType {
        case localization
        case colors
    }
    
    // MARK: - Validation Tests
    
    @Test("Test helpers create valid configurations")
    func helpersValidation() {
        let locConfig = TestHelpers.createTestLocalizationConfig()
        #expect(locConfig.enumName == "TestL10n")
        #expect(locConfig.outputDirectory == "/test/output")
        
        let colorConfig = TestHelpers.createTestColorConfig()
        #expect(colorConfig.outputDirectory == "/test/output")
        #expect(colorConfig.csvFileName == "test_colors.csv")
    }
    
    @Test("Test environment isolation works correctly")
    func environmentIsolation() {
        let (baseDir, cleanup) = TestHelpers.createIsolatedTestEnvironment()
        defer { cleanup() }
        
        #expect(FileManager.default.fileExists(atPath: baseDir.path))
        #expect(baseDir.path.contains("SwiftSheetGenTest_"))
        
        let (baseDir2, cleanup2) = TestHelpers.createIsolatedTestEnvironment()
        defer { cleanup2() }
        
        #expect(baseDir.path != baseDir2.path)
    }
    
    @Test("Test data generation includes expected content")
    func dataGeneration() {
        let localizationCSV = TestHelpers.createTestCSVContent(type: .localization)
        #expect(localizationCSV.contains("common"))
        #expect(localizationCSV.contains("login"))
        
        let colorsCSV = TestHelpers.createTestCSVContent(type: .colors)
        #expect(colorsCSV.contains("primaryBackgroundColor"))
        #expect(colorsCSV.contains("#FFF"))
        
        let problematicData = TestHelpers.createTestCSVContent(
            type: .localization, 
            includeProblematicData: true
        )
        #expect(problematicData.contains("with\"quotes"))
        #expect(problematicData.contains("with,comma"))
    }
}

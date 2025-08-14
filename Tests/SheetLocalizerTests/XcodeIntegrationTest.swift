import Testing
import Foundation
import os.log
@testable import SheetLocalizer
@testable import CoreExtensions

@Suite("Simple Xcode Integration Tests")
struct XcodeIntegrationTest {
    
    // MARK: - Color Assets Integration Tests
    
    @Test("Colors generation creates proper file structure")
    func colorsGenerationFileStructure() async throws {
        let tempDir = try createTestDirectory()
        defer { cleanupTestDirectory(tempDir) }
        
        let config = ColorConfig(
            outputDirectory: tempDir,
            csvFileName: "test_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = ColorGenerator(config: config)
        let csvContent = SharedTestData.colorsCSV
        
        let tempCSVFile = "\(tempDir)/test_colors.csv"
        try csvContent.write(toFile: tempCSVFile, atomically: true, encoding: .utf8)
        
        try await generator.generate(from: tempCSVFile)
        
        let colorsFile = "\(tempDir)/Colors.swift"
        let dynamicFile = "\(tempDir)/Color+Dynamic.swift"
        
        #expect(FileManager.default.fileExists(atPath: colorsFile))
        #expect(FileManager.default.fileExists(atPath: dynamicFile))
        
        let colorsContent = try String(contentsOfFile: colorsFile, encoding: .utf8)
        #expect(colorsContent.contains("import SwiftUI"))
        #expect(colorsContent.contains("primaryBackgroundColor"))
        
        let dynamicContent = try String(contentsOfFile: dynamicFile, encoding: .utf8)
        #expect(dynamicContent.contains("extension Color"))
        #expect(dynamicContent.contains("userInterfaceStyle"))
    }
    
    // MARK: - Localizable Strings Integration Tests
    
    @Test("Localization generation creates proper .lproj structure")
    func localizationGenerationLprojStructure() async throws {
        let tempDir = try createTestDirectory()
        defer { cleanupTestDirectory(tempDir) }
        
        let config = LocalizationConfig(
            outputDirectory: tempDir,
            enumName: "TestL10n",
            sourceDirectory: tempDir,
            csvFileName: "test_localizations.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        let generator = LocalizationGenerator(config: config)
        let csvContent = SharedTestData.localizationCSV
        
        let tempCSVFile = "\(tempDir)/test_localizations.csv"
        try csvContent.write(toFile: tempCSVFile, atomically: true, encoding: .utf8)
        
        try await generator.generate(from: tempCSVFile)
        
        let esDir = "\(tempDir)/es.lproj"
        let enDir = "\(tempDir)/en.lproj"
        let frDir = "\(tempDir)/fr.lproj"
        
        #expect(FileManager.default.fileExists(atPath: esDir))
        #expect(FileManager.default.fileExists(atPath: enDir))
        #expect(FileManager.default.fileExists(atPath: frDir))
        
        let esStrings = "\(esDir)/Localizable.strings"
        let enStrings = "\(enDir)/Localizable.strings"
        let frStrings = "\(frDir)/Localizable.strings"
        
        #expect(FileManager.default.fileExists(atPath: esStrings))
        #expect(FileManager.default.fileExists(atPath: enStrings))
        #expect(FileManager.default.fileExists(atPath: frStrings))
        
        let enumFile = "\(tempDir)/TestL10n.swift"
        #expect(FileManager.default.fileExists(atPath: enumFile))
        
        let enumContent = try String(contentsOfFile: enumFile, encoding: .utf8)
        #expect(enumContent.contains("enum TestL10n"))
        #expect(enumContent.contains("commonAppNameText"))
        
        let esContent = try String(contentsOfFile: esStrings, encoding: .utf8)
        #expect(esContent.contains("jorgemrht"))
        
        let enContent = try String(contentsOfFile: enStrings, encoding: .utf8)
        #expect(enContent.contains("My App"))
        
        let frContent = try String(contentsOfFile: frStrings, encoding: .utf8)
        #expect(frContent.contains("Mon App"))
    }
    
    // MARK: - Strings Catalog (.xcstrings) Integration Tests
    
    @Test("Strings catalog generation creates proper .xcstrings file")
    func stringsCatalogGenerationXcstringsFile() async throws {
        let tempDir = try createTestDirectory()
        defer { cleanupTestDirectory(tempDir) }
        
        let config = LocalizationConfig(
            outputDirectory: tempDir,
            enumName: "CatalogL10n",
            sourceDirectory: tempDir,
            csvFileName: "test_catalog.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: true
        )
        
        let generator = LocalizationGenerator(config: config)
        let csvContent = SharedTestData.localizationCSV
        
        let tempCSVFile = "\(tempDir)/test_catalog.csv"
        try csvContent.write(toFile: tempCSVFile, atomically: true, encoding: .utf8)
        
        try await generator.generate(from: tempCSVFile)
        
        let catalogFile = "\(tempDir)/Localizable.xcstrings"
        #expect(FileManager.default.fileExists(atPath: catalogFile))
        
        let enumFile = "\(tempDir)/CatalogL10n.swift"
        #expect(FileManager.default.fileExists(atPath: enumFile))
        
        // Verify .xcstrings content structure
        let catalogData = try Data(contentsOf: URL(fileURLWithPath: catalogFile))
        let catalog = try JSONSerialization.jsonObject(with: catalogData) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        #expect(catalogDict["version"] as? String == "1.0")
        #expect(catalogDict["sourceLanguage"] as? String == "es")
        
        let strings = catalogDict["strings"] as? [String: Any]
        let stringsDict = try #require(strings)
        
        #expect(stringsDict.keys.contains("common_app_name_text"))
        #expect(stringsDict.keys.contains("login_title_text"))
        
        // Verify enum content
        let enumContent = try String(contentsOfFile: enumFile, encoding: .utf8)
        #expect(enumContent.contains("enum CatalogL10n"))
        #expect(enumContent.contains("commonAppNameText"))
    }
    
    // MARK: - Cross-Integration Tests
    
    @Test("Combined generation workflow with colors and localizations")
    func combinedGenerationWorkflow() async throws {
        let tempDir = try createTestDirectory()
        defer { cleanupTestDirectory(tempDir) }
        
        // Setup subdirectories
        let colorsDir = "\(tempDir)/Colors"
        let localizablesDir = "\(tempDir)/Localizables"
        
        try FileManager.default.createDirectory(atPath: colorsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: localizablesDir, withIntermediateDirectories: true)
        
        // Generate colors
        let colorConfig = ColorConfig(
            outputDirectory: colorsDir,
            csvFileName: "colors.csv",
            cleanupTemporaryFiles: false
        )
        
        let colorGenerator = ColorGenerator(config: colorConfig)
        let colorCSVFile = "\(colorsDir)/colors.csv"
        try SharedTestData.colorsCSV.write(toFile: colorCSVFile, atomically: true, encoding: .utf8)
        
        try await colorGenerator.generate(from: colorCSVFile)
        
        // Generate localizations
        let localizationConfig = LocalizationConfig(
            outputDirectory: localizablesDir,
            enumName: "AppStrings",
            sourceDirectory: localizablesDir,
            csvFileName: "localizations.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        let localizationGenerator = LocalizationGenerator(config: localizationConfig)
        let localizationCSVFile = "\(localizablesDir)/localizations.csv"
        try SharedTestData.localizationCSV.write(toFile: localizationCSVFile, atomically: true, encoding: .utf8)
        
        try await localizationGenerator.generate(from: localizationCSVFile)
        
        // Colors verification
        #expect(FileManager.default.fileExists(atPath: "\(colorsDir)/Colors.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(colorsDir)/Color+Dynamic.swift"))
        
        // Localizations verification
        #expect(FileManager.default.fileExists(atPath: "\(localizablesDir)/AppStrings.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(localizablesDir)/es.lproj/Localizable.strings"))
        #expect(FileManager.default.fileExists(atPath: "\(localizablesDir)/en.lproj/Localizable.strings"))
        #expect(FileManager.default.fileExists(atPath: "\(localizablesDir)/fr.lproj/Localizable.strings"))
        
        let colorsContent = try String(contentsOfFile: "\(colorsDir)/Colors.swift", encoding: .utf8)
        #expect(colorsContent.contains("primaryBackgroundColor"))
        
        let appStringsContent = try String(contentsOfFile: "\(localizablesDir)/AppStrings.swift", encoding: .utf8)
        #expect(appStringsContent.contains("enum AppStrings"))
        #expect(appStringsContent.contains("commonAppNameText"))
    }
    
    // MARK: - Test Helpers
    
    private func createTestDirectory() throws -> String {
        let tempDir = NSTemporaryDirectory() + "/xcode-simple-test-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    private func cleanupTestDirectory(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}

import Testing
import Foundation
@testable import SheetLocalizer

@Suite("LocalizationGenerator Tests")
struct LocalizationGeneratorTest {
    
    // MARK: - Basic Functionality Tests
    
    @Test("LocalizationGenerator processes CSV data and generates localization files")
    func localizationGeneratorBasicProcessing() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("localization.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "TestStrings",
            sourceDirectory: tempDir.path,
            csvFileName: "localization.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        let enumFile = tempDir.appendingPathComponent("TestStrings.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
        
        // Verify localization directories were created
        let esDir = tempDir.appendingPathComponent("es.lproj")
        let enDir = tempDir.appendingPathComponent("en.lproj")
        let frDir = tempDir.appendingPathComponent("fr.lproj")
        
        #expect(FileManager.default.fileExists(atPath: esDir.path))
        #expect(FileManager.default.fileExists(atPath: enDir.path))
        #expect(FileManager.default.fileExists(atPath: frDir.path))
    }
    
    @Test("LocalizationGenerator handles empty CSV gracefully")
    func localizationGeneratorHandlesEmptyCSV() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("empty.csv")
        try "".write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "EmptyStrings",
            sourceDirectory: tempDir.path,
            csvFileName: "empty.csv"
        )
        
        let generator = LocalizationGenerator(config: config)
        
        do {
            try await generator.generate(from: csvFile.path)
            #expect(Bool(false), "Should throw error for empty CSV")
        } catch let error as SheetLocalizerError {
            switch error {
            case .csvParsingError, .insufficientData:
                #expect(Bool(true)) 
            default:
                #expect(Bool(false), "Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - CSV Structure Validation Tests
    
    @Test("LocalizationGenerator validates CSV structure correctly")
    func localizationGeneratorCSVValidation() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let testCases: [(name: String, content: String, shouldPass: Bool)] = [
            ("valid_structure", SharedTestData.localizationCSV, true),
            ("missing_header", "incomplete,data\nrow1,row2", false),
            ("insufficient_rows", "[Check],[View],[Item]\nrow1,row2,row3", false),
            ("malformed_data", "header1,header2\nrow1", false)
        ]
        
        for testCase in testCases {
            let csvFile = tempDir.appendingPathComponent("\(testCase.name).csv")
            try testCase.content.write(to: csvFile, atomically: true, encoding: .utf8)
            
            let config = LocalizationConfig(
                outputDirectory: tempDir.appendingPathComponent(testCase.name).path,
                enumName: "TestEnum",
                sourceDirectory: tempDir.path,
                csvFileName: "\(testCase.name).csv"
            )
            
            let generator = LocalizationGenerator(config: config)
            
            if testCase.shouldPass {
                do {
                    try await generator.generate(from: csvFile.path)
                    #expect(Bool(true), "Should succeed for \(testCase.name)")
                } catch {
                    #expect(Bool(false), "Should not fail for valid structure: \(error)")
                }
            } else {
                do {
                    try await generator.generate(from: csvFile.path)
                    #expect(Bool(false), "Should fail for \(testCase.name)")
                } catch {
                    #expect(error is SheetLocalizerError, "Should throw SheetLocalizerError")
                }
            }
        }
    }
    
    // MARK: - Configuration Tests
    
    @Test("LocalizationGenerator respects different configuration options")
    func localizationGeneratorConfigurationOptions() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("config_test.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        // Test different enum names
        let enumNames = ["CustomL10n", "AppStrings", "Localized"]
        
        for enumName in enumNames {
            let enumOutputDir = tempDir.appendingPathComponent(enumName)
            try FileManager.default.createDirectory(at: enumOutputDir, withIntermediateDirectories: true)
            
            let config = LocalizationConfig(
                outputDirectory: enumOutputDir.path,
                enumName: enumName,
                sourceDirectory: tempDir.path,
                csvFileName: "config_test.csv",
                cleanupTemporaryFiles: false
            )
            
            let generator = LocalizationGenerator(config: config)
            try await generator.generate(from: csvFile.path)
            
            // Verify enum file with correct name (should be in sourceDirectory, not outputDirectory/enumName)
            let enumFile = tempDir.appendingPathComponent("\(enumName).swift")
            #expect(FileManager.default.fileExists(atPath: enumFile.path), "Enum file should exist for \(enumName)")
            
            if FileManager.default.fileExists(atPath: enumFile.path) {
                // Verify enum content contains correct name
                let enumContent = try String(contentsOf: enumFile, encoding: .utf8)
                #expect(enumContent.contains("enum \(enumName)"), "Enum should be named \(enumName)")
            }
        }
    }
    
    @Test("LocalizationGenerator handles strings catalog generation")
    func localizationGeneratorStringsCatalog() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("catalog_test.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "CatalogStrings",
            sourceDirectory: tempDir.path,
            csvFileName: "catalog_test.csv",
            cleanupTemporaryFiles: false,
            useStringsCatalog: true
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        // Verify strings catalog was generated
        let catalogFile = tempDir.appendingPathComponent("Localizable.xcstrings")
        #expect(FileManager.default.fileExists(atPath: catalogFile.path))
        
        // Verify catalog structure
        let catalogData = try Data(contentsOf: catalogFile)
        let catalogJSON = try JSONSerialization.jsonObject(with: catalogData) as? [String: Any]
        #expect(catalogJSON != nil)
        
        if let catalog = catalogJSON {
            #expect(catalog["sourceLanguage"] != nil)
            #expect(catalog["strings"] != nil)
            #expect(catalog["version"] as? String == "1.0")
        }
    }
    
    // MARK: - Language Processing Tests
    
    @Test("LocalizationGenerator processes multiple languages correctly")
    func localizationGeneratorMultiLanguageProcessing() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("multilang.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "MultiLangStrings",
            sourceDirectory: tempDir.path,
            csvFileName: "multilang.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        // Expected languages from SharedTestData.localizationCSV
        let expectedLanguages = ["es", "en", "fr"]
        
        for language in expectedLanguages {
            let langDir = tempDir.appendingPathComponent("\(language).lproj")
            #expect(FileManager.default.fileExists(atPath: langDir.path), "Directory should exist for \(language)")
            
            let stringsFile = langDir.appendingPathComponent("Localizable.strings")
            #expect(FileManager.default.fileExists(atPath: stringsFile.path), "Strings file should exist for \(language)")
            
            // Verify strings file content
            let content = try String(contentsOf: stringsFile, encoding: .utf8)
            #expect(!content.isEmpty, "Strings file should not be empty for \(language)")
            #expect(content.contains("="), "Strings file should contain key-value pairs")
        }
    }
    
    // MARK: - Template Variable Tests
    
    @Test("LocalizationGenerator handles template variables correctly")
    func localizationGeneratorTemplateVariables() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("template_vars.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "TemplateStrings",
            sourceDirectory: tempDir.path,
            csvFileName: "template_vars.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        // Check that template variables are preserved in strings files
        let enStringsFile = tempDir.appendingPathComponent("en.lproj/Localizable.strings")
        let content = try String(contentsOf: enStringsFile, encoding: .utf8)
        
        // Template variables are converted to format specifiers in .strings files
        #expect(content.contains("%@"), "Should contain format specifiers for template variables")
        #expect(content.contains("Version %@"), "Should contain Version template")
        #expect(content.contains("Build %@"), "Should contain Build template")
        #expect(content.contains("active users"), "Should contain user count template")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("LocalizationGenerator handles file system errors gracefully")
    func localizationGeneratorFileSystemErrors() async throws {
        // Test with non-existent CSV file
        let config = LocalizationConfig(
            outputDirectory: "/tmp/nonexistent",
            enumName: "ErrorTest",
            sourceDirectory: "/tmp",
            csvFileName: "nonexistent.csv"
        )
        
        let generator = LocalizationGenerator(config: config)
        
        do {
            try await generator.generate(from: "/nonexistent/path/file.csv")
            #expect(Bool(false), "Should throw error for non-existent file")
        } catch {
            // File system errors are typically NSError, but we expect some error
            #expect(Bool(true), "Should throw some error for non-existent file")
        }
    }
    
    @Test("LocalizationGenerator validates entry structure")
    func localizationGeneratorEntryValidation() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Create CSV with malformed entries
        let malformedCSV = """
        "[Check]", "[View]", "[Item]", "[Type]", "es", "en", "fr"
        "", "", "", "text", "valor", "value", "valeur"
        "", "view", "", "text", "otro", "other", "autre"
        "", "view", "item", "", "final", "final", "final"
        "[END]"
        """
        
        let csvFile = tempDir.appendingPathComponent("malformed.csv")
        try malformedCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "MalformedTest",
            sourceDirectory: tempDir.path,
            csvFileName: "malformed.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        
        // Should handle malformed entries gracefully
        do {
            try await generator.generate(from: csvFile.path)
            // Verify that only valid entries were processed
            let enumFile = tempDir.appendingPathComponent("MalformedTest.swift")
            let enumContent = try String(contentsOf: enumFile, encoding: .utf8)
            
            // Only the complete entry should be included
            #expect(enumContent.contains("case "), "Should contain at least one valid case")
        } catch {
            // It's also acceptable to throw an error for malformed data
            #expect(error is SheetLocalizerError)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("LocalizationGenerator handles large datasets efficiently")
    func localizationGeneratorPerformance() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("large_dataset.csv")
        try SharedTestData.largeCSVData.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "LargeDataset",
            sourceDirectory: tempDir.path,
            csvFileName: "large_dataset.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        try await generator.generate(from: csvFile.path)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let executionTime = endTime - startTime
        #expect(executionTime < 10.0, "Large dataset processing should complete within 10 seconds")
        
        // Verify files were generated
        let enumFile = tempDir.appendingPathComponent("LargeDataset.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
    }
    
    // MARK: - Integration Tests
    
    @Test("LocalizationGenerator integrates with Xcode projects")
    func localizationGeneratorXcodeIntegration() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Create a mock Xcode project
        try SharedTestData.createMockXcodeProject(in: tempDir, name: "TestProject")
        
        let csvFile = tempDir.appendingPathComponent("integration_test.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "IntegrationTest",
            sourceDirectory: tempDir.path,
            csvFileName: "integration_test.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        // Verify files were generated and potentially added to project
        let enumFile = tempDir.appendingPathComponent("IntegrationTest.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
        
        let languages = ["es", "en", "fr"]
        for language in languages {
            let langDir = tempDir.appendingPathComponent("\(language).lproj")
            #expect(FileManager.default.fileExists(atPath: langDir.path))
        }
    }
    
    // MARK: - Configuration Edge Cases
    
    @Test("LocalizationGenerator handles special characters in paths and content")
    func localizationGeneratorSpecialCharacters() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let specialCharCSV = """
        "[Check]", "[View]", "[Item]", "[Type]", "es", "en", "fr"
        "", "común", "título_especial", "text", "Título & Descripción", "Title & Description", "Titre & Description"
        "", "común", "emoji_test", "text", "Hola 👋 Mundo", "Hello 👋 World", "Bonjour 👋 Monde"
        "", "común", "quotes_test", "text", "Dice: \\"Hola\\"", "Says: \\"Hello\\"", "Dit: \\"Bonjour\\""
        "[END]"
        """
        
        let csvFile = tempDir.appendingPathComponent("special_chars.csv")
        try specialCharCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "SpecialCharsTest",
            sourceDirectory: tempDir.path,
            csvFileName: "special_chars.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        let enumFile = tempDir.appendingPathComponent("SpecialCharsTest.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
        
        let esStringsFile = tempDir.appendingPathComponent("es.lproj/Localizable.strings")
        let content = try String(contentsOf: esStringsFile, encoding: .utf8)
        
        #expect(content.contains("👋"), "Should preserve emoji characters")
        #expect(content.contains("&"), "Should preserve ampersand characters")
        #expect(content.contains("\\\""), "Should properly escape quotes")
    }
}

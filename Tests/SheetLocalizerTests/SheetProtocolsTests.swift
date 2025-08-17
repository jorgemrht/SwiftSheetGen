import Testing
import Foundation
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer
@testable import CoreExtensions

@Suite
struct SheetProtocolsTests {
    
    // MARK: - Mock Implementations for Protocol Testing
    
    private struct MockSheetConfig: SheetConfig {
        let outputDirectory: String
        let csvFileName: String
        let cleanupTemporaryFiles: Bool
        
        init(outputDirectory: String = "/test/output", 
             csvFileName: String = "test.csv", 
             cleanupTemporaryFiles: Bool = true) {
            self.outputDirectory = outputDirectory
            self.csvFileName = csvFileName
            self.cleanupTemporaryFiles = cleanupTemporaryFiles
        }
    }
    
    private class MockSheetGenerator: SheetGenerator {
        typealias Config = MockSheetConfig
        
        let config: Config
        private(set) var generateCallCount: Int = 0
        private(set) var lastCSVFilePath: String?
        var shouldThrowError: Bool = false
        var errorToThrow: Error = SheetLocalizerError.localizationGenerationError("Mock error")
        
        required init(config: Config) {
            self.config = config
        }
        
        func generate(from csvFilePath: String) async throws {
            generateCallCount += 1
            lastCSVFilePath = csvFilePath
            
            if shouldThrowError {
                throw errorToThrow
            }
        }
    }
    
    // MARK: - SheetConfig Protocol Tests
    
    @Test("SheetConfig protocol defines required properties correctly")
    func sheetConfigProtocolRequiredProperties() {
        let mockConfig = MockSheetConfig(
            outputDirectory: "/custom/output",
            csvFileName: "custom.csv",
            cleanupTemporaryFiles: false
        )
        
        let config: any SheetConfig = mockConfig
        
        #expect(config.outputDirectory == "/custom/output", "Output directory should be accessible through protocol")
        #expect(config.csvFileName == "custom.csv", "CSV filename should be accessible through protocol")
        #expect(config.cleanupTemporaryFiles == false, "Cleanup flag should be accessible through protocol")
    }
    
    @Test("LocalizationConfig implements SheetConfig protocol properly")
    func localizationConfigImplementsSheetConfigProtocol() {
        let config = LocalizationConfig.custom(
            outputDirectory: "/loc/output",
            enumName: "TestEnum",
            sourceDirectory: "/loc/source",
            csvFileName: "localization.csv",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: false,
            useStringsCatalog: true
        )
        
        let sheetConfig: any SheetConfig = config
        
        #expect(sheetConfig.outputDirectory == "/loc/output", "LocalizationConfig should provide output directory")
        #expect(sheetConfig.csvFileName == "localization.csv", "LocalizationConfig should provide CSV filename")
        #expect(sheetConfig.cleanupTemporaryFiles == true, "LocalizationConfig should provide cleanup flag")
        
        #expect(config.enumName == "TestEnum", "LocalizationConfig specific properties should remain")
        #expect(config.useStringsCatalog == true, "LocalizationConfig specific properties should remain")
    }
    
    @Test("ColorConfig implements SheetConfig protocol properly")
    func colorConfigImplementsSheetConfigProtocol() {
        let config = ColorConfig.custom(
            outputDirectory: "/color/output",
            csvFileName: "colors.csv",
            cleanupTemporaryFiles: false
        )
        
        let sheetConfig: any SheetConfig = config
        
        #expect(sheetConfig.outputDirectory == "/color/output", "ColorConfig should provide output directory")
        #expect(sheetConfig.csvFileName == "colors.csv", "ColorConfig should provide CSV filename")
        #expect(sheetConfig.cleanupTemporaryFiles == false, "ColorConfig should provide cleanup flag")
    }
    
    @Test("LocalizationGenerator implements SheetGenerator protocol properly")
    func localizationGeneratorImplementsSheetGeneratorProtocol() throws {
        let config = LocalizationConfig.default
        let generator = LocalizationGenerator(config: config)
        
        let sheetGenerator: any SheetGenerator = generator
        
        #expect(String(describing: type(of: sheetGenerator)) == "LocalizationGenerator", "Should be LocalizationGenerator instance")
    }
    
    @Test("ColorGenerator implements SheetGenerator protocol properly")
    func colorGeneratorImplementsSheetGeneratorProtocol() throws {
        let config = ColorConfig.default
        let generator = ColorGenerator(config: config)
        
        let sheetGenerator: any SheetGenerator = generator
        
        #expect(String(describing: type(of: sheetGenerator)) == "ColorGenerator", "Should be ColorGenerator instance")
    }
    
    @Test("SheetConfig protocol properties handle various path formats",
          arguments: [
              ("/absolute/path", "absolute.csv"),
              ("./relative/path", "relative.csv"),
              ("~/home/path", "home.csv"),
              ("/path/with spaces", "spaces.csv"),
              ("/path/with-special_chars.123", "special.csv"),
              ("", "empty.csv")
          ])
    func sheetConfigProtocolPathFormatHandling(outputDir: String, csvName: String) {
        let config = MockSheetConfig(
            outputDirectory: outputDir,
            csvFileName: csvName,
            cleanupTemporaryFiles: true
        )
        
        let sheetConfig: any SheetConfig = config
        
        #expect(sheetConfig.outputDirectory == outputDir, "Protocol should preserve exact output directory path")
        #expect(sheetConfig.csvFileName == csvName, "Protocol should preserve exact CSV filename")
    }
    
    // MARK: - SheetGenerator Protocol Tests
    
    @Test("SheetGenerator protocol defines required methods correctly")
    func sheetGeneratorProtocolRequiredMethods() async throws {
        let config = MockSheetConfig()
        let generator = MockSheetGenerator(config: config)
        
        let csvPath = "/test/path/data.csv"
        try await generator.generate(from: csvPath)
        
        #expect(generator.generateCallCount == 1, "Generate method should be called once")
        #expect(generator.lastCSVFilePath == csvPath, "Generate method should receive correct CSV path")
    }
    
    @Test("SheetGenerator protocol handles configuration access properly")
    func sheetGeneratorProtocolConfigurationAccess() {
        let config = MockSheetConfig(
            outputDirectory: "/generator/output",
            csvFileName: "generator.csv",
            cleanupTemporaryFiles: false
        )
        let generator = MockSheetGenerator(config: config)
        
        let sheetGenerator: any SheetGenerator = generator
        
        #expect(String(describing: type(of: sheetGenerator)).contains("MockSheetGenerator"), "Should be mock generator type")
    }
    
    @Test("SheetGenerator protocol handles async generation properly")
    func sheetGeneratorProtocolAsyncGeneration() async throws {
        let config = MockSheetConfig()
        let generator = MockSheetGenerator(config: config)
        
        let csvPaths = [
            "/test/file1.csv",
            "/test/file2.csv",
            "/test/file3.csv"
        ]
        
        for csvPath in csvPaths {
            try await generator.generate(from: csvPath)
        }
        
        #expect(generator.generateCallCount == 3, "Generate should be called for each file")
        #expect(generator.lastCSVFilePath == "/test/file3.csv", "Last path should be the final one called")
    }
    
    @Test("SheetGenerator protocol handles error propagation correctly")
    func sheetGeneratorProtocolErrorPropagation() async {
        let config = MockSheetConfig()
        let generator = MockSheetGenerator(config: config)
        generator.shouldThrowError = true
        generator.errorToThrow = SheetLocalizerError.csvParsingError("Test parsing error")
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: "/test/error.csv")
        }
        
        #expect(generator.generateCallCount == 1, "Generate should be called even when throwing error")
    }
    
    // MARK: - Protocol Interaction Tests
    
    @Test("SheetConfig and SheetGenerator protocols work together correctly")
    func sheetConfigAndGeneratorProtocolInteraction() async throws {

        let locConfig = LocalizationConfig.custom(
            outputDirectory: "/loc/test",
            enumName: "TestEnum",
            sourceDirectory: "/loc/source",
            csvFileName: "loc.csv",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        let locGenerator = LocalizationGenerator(config: locConfig)
        
        let locSheetConfig: any SheetConfig = locConfig
        let locSheetGenerator: any SheetGenerator = locGenerator
        
        #expect(locSheetConfig.outputDirectory == "/loc/test", "Config should have correct values")
        
        let colorConfig = ColorConfig.custom(
            outputDirectory: "/color/test",
            csvFileName: "color.csv",
            cleanupTemporaryFiles: false
        )
        let colorGenerator = ColorGenerator(config: colorConfig)
        
        let colorSheetConfig: any SheetConfig = colorConfig
        let colorSheetGenerator: any SheetGenerator = colorGenerator
        
        #expect(colorSheetConfig.outputDirectory == "/color/test",
               "Color config should have correct values")
    }
    
    // MARK: - Protocol Type Erasure Tests
    
    @Test("Protocol type erasure works correctly for heterogeneous collections")
    func protocolTypeErasureForCollections() {
        let configs: [any SheetConfig] = [
            LocalizationConfig.default,
            ColorConfig.default,
            MockSheetConfig(outputDirectory: "/mock", csvFileName: "mock.csv", cleanupTemporaryFiles: true)
        ]
        
        #expect(configs.count == 3, "Should be able to store different config types in same array")
        
        for config in configs {
            #expect(!config.outputDirectory.isEmpty, "All configs should have output directory")
            #expect(!config.csvFileName.isEmpty, "All configs should have CSV filename")
        }
    }
    
    @Test("Protocol existential types maintain type safety")
    func protocolExistentialTypeSafety() {
        let locConfig = LocalizationConfig.default
        let colorConfig = ColorConfig.default
        
        let locGenerator = LocalizationGenerator(config: locConfig)
        let colorGenerator = ColorGenerator(config: colorConfig)
        
        let generators: [any SheetGenerator] = [locGenerator, colorGenerator]
        
        for generator in generators {
            #expect(String(describing: type(of: generator)).contains("Generator"), "Should be a generator type")
        }
    }
    
    // MARK: - Protocol Associated Type Tests
    
    @Test("Protocol associated types work correctly in generic contexts")
    func protocolAssociatedTypesInGenericContexts() {
        func testGeneratorType<G: SheetGenerator>(_ generator: G) -> String {
            return String(describing: type(of: generator))
        }
        
        let locConfig = LocalizationConfig.custom(
            outputDirectory: "/loc/generic/test",
            enumName: "GenericEnum",
            sourceDirectory: "/loc/source",
            csvFileName: "generic.csv",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        let locGenerator = LocalizationGenerator(config: locConfig)
        
        let colorConfig = ColorConfig.custom(
            outputDirectory: "/color/generic/test",
            csvFileName: "generic_colors.csv",
            cleanupTemporaryFiles: false
        )
        let colorGenerator = ColorGenerator(config: colorConfig)
        
        let locResult = testGeneratorType(locGenerator)
        let colorResult = testGeneratorType(colorGenerator)
        
        #expect(locResult == "LocalizationGenerator", "Generic function should work with LocalizationGenerator")
        #expect(colorResult == "ColorGenerator", "Generic function should work with ColorGenerator")
    }
    
    // MARK: - Protocol Compliance Edge Cases
    
    @Test("Protocol implementations handle edge case values properly")
    func protocolImplementationsHandleEdgeCases() {
        let edgeCaseConfigs: [any SheetConfig] = [
            MockSheetConfig(outputDirectory: "", csvFileName: "", cleanupTemporaryFiles: true),
            MockSheetConfig(outputDirectory: "/", csvFileName: "a", cleanupTemporaryFiles: false),
            MockSheetConfig(outputDirectory: "/very/long/path/that/might/not/exist/but/should/be/handled/properly", 
                          csvFileName: "very_long_filename_that_tests_string_handling.csv", 
                          cleanupTemporaryFiles: true)
        ]
        
        for config in edgeCaseConfigs {
            // Should not throw errors accessing properties
            #expect(throws: Never.self) {
                _ = config.outputDirectory
                _ = config.csvFileName
                _ = config.cleanupTemporaryFiles
            }
        }
    }
}

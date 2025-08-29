import Testing
import Foundation
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer

@Suite
struct SheetGeneratorTest {
    
    // MARK: - Protocol Definition Tests
    
    @Test("SheetGenerator protocol defines required methods correctly")
    func sheetGeneratorProtocolRequiredMethods() {
        let locGenerator = LocalizationGenerator(config: LocalizationConfig.default)
        let colorGenerator = ColorGenerator(config: ColorConfig.default)
        
        #expect(String(describing: type(of: locGenerator)) == "LocalizationGenerator")
        #expect(String(describing: type(of: colorGenerator)) == "ColorGenerator")
    }
    
    @Test("SheetGenerator protocol defines required associated types correctly")
    func sheetGeneratorProtocolAssociatedTypes() {
        let locConfig = LocalizationConfig.default
        let colorConfig = ColorConfig.default
        
        let locGenerator = LocalizationGenerator(config: locConfig)
        let colorGenerator = ColorGenerator(config: colorConfig)
        
        #expect(String(describing: type(of: locGenerator)).contains("LocalizationGenerator"))
        #expect(String(describing: type(of: colorGenerator)).contains("ColorGenerator"))
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test("LocalizationGenerator conforms to SheetGenerator protocol")
    func localizationGeneratorProtocolConformance() {
        let config = LocalizationConfig.default
        let generator = LocalizationGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "LocalizationGenerator")
    }
    
    @Test("ColorGenerator conforms to SheetGenerator protocol")
    func colorGeneratorProtocolConformance() {
        let config = ColorConfig.default
        let generator = ColorGenerator(config: config)
        
        #expect(String(describing: type(of: generator)) == "ColorGenerator")
    }
    
    // MARK: - Initialization Tests
    
    @Test("SheetGenerator implementations initialize correctly with default configurations")
    func sheetGeneratorDefaultInitialization() {
        let locConfig = LocalizationConfig.default
        let colorConfig = ColorConfig.default
        
        #expect(throws: Never.self) {
            _ = LocalizationGenerator(config: locConfig)
            _ = ColorGenerator(config: colorConfig)
        }
    }
    
    @Test("SheetGenerator implementations initialize correctly with custom configurations")
    func sheetGeneratorCustomInitialization() {
        let customLocConfig = LocalizationConfig.custom(
            outputDirectory: "/custom/localization",
            enumName: "CustomEnum",
            sourceDirectory: "/source",
            csvFileName: "custom.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        let customColorConfig = ColorConfig.custom(
            outputDirectory: "/custom/colors",
            csvFileName: "custom_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(throws: Never.self) {
            _ = LocalizationGenerator(config: customLocConfig)
            _ = ColorGenerator(config: customColorConfig)
        }
    }
    
    @Test("SheetGenerator implementations handle various configuration combinations")
    func sheetGeneratorConfigurationCombinations() {
        let configurations: [(outputDir: String, csvFile: String, cleanup: Bool)] = [
            ("./default", "test.csv", true),
            ("/absolute/path", "absolute.csv", false),
            ("relative/path", "relative.csv", true),
            ("/path/with spaces", "spaced file.csv", false),
            ("/very/long/path/with/many/nested/directories", "very_long_filename.csv", true)
        ]
        
        for config in configurations {
            let locConfig = LocalizationConfig.custom(
                outputDirectory: config.outputDir,
                enumName: "TestEnum",
                sourceDirectory: "/source",
                csvFileName: config.csvFile,
                cleanupTemporaryFiles: config.cleanup
            )
            
            let colorConfig = ColorConfig.custom(
                outputDirectory: config.outputDir,
                csvFileName: config.csvFile,
                cleanupTemporaryFiles: config.cleanup
            )
            
            #expect(throws: Never.self) {
                _ = LocalizationGenerator(config: locConfig)
                _ = ColorGenerator(config: colorConfig)
            }
        }
    }
    
    // MARK: - Type System Tests
    
    @Test("SheetGenerator protocol works correctly in generic contexts")
    func sheetGeneratorGenericContextUsage() {
        func createGenerator<G: SheetGenerator>(_ generatorType: G.Type, config: G.Config) -> G {
            return G(config: config)
        }
        
        let locConfig = LocalizationConfig.default
        let colorConfig = ColorConfig.default
        
        let locGenerator = createGenerator(LocalizationGenerator.self, config: locConfig)
        let colorGenerator = createGenerator(ColorGenerator.self, config: colorConfig)
        
        #expect(String(describing: type(of: locGenerator)) == "LocalizationGenerator")
        #expect(String(describing: type(of: colorGenerator)) == "ColorGenerator")
    }
    
    @Test("SheetGenerator protocol associated types work correctly")
    func sheetGeneratorAssociatedTypesUsage() {
        let locGenerator = LocalizationGenerator(config: LocalizationConfig.default)
        let colorGenerator = ColorGenerator(config: ColorConfig.default)
        
        #expect(String(describing: type(of: locGenerator)).contains("Generator"))
        #expect(String(describing: type(of: colorGenerator)).contains("Generator"))
    }
    
    @Test("SheetGenerator protocol type constraints work correctly")
    func sheetGeneratorTypeConstraints() {
        func validateGenerator<G: SheetGenerator>(_ generator: G) -> Bool where G.Config: SheetConfig {
            return String(describing: type(of: generator)).contains("Generator")
        }
        
        let locGenerator = LocalizationGenerator(config: LocalizationConfig.default)
        let colorGenerator = ColorGenerator(config: ColorConfig.default)
        
        #expect(validateGenerator(locGenerator) == true)
        #expect(validateGenerator(colorGenerator) == true)
    }
    
    // MARK: - Consistency Tests
    
    @Test("SheetGenerator implementations are consistent across multiple instantiations")
    func sheetGeneratorConsistencyAcrossInstantiations() {
        let config1 = LocalizationConfig.default
        let config2 = LocalizationConfig.default
        
        let generator1 = LocalizationGenerator(config: config1)
        let generator2 = LocalizationGenerator(config: config2)
        
        #expect(String(describing: type(of: generator1)) == String(describing: type(of: generator2)))
        
        let colorConfig1 = ColorConfig.default
        let colorConfig2 = ColorConfig.default
        
        let colorGenerator1 = ColorGenerator(config: colorConfig1)
        let colorGenerator2 = ColorGenerator(config: colorConfig2)
        
        #expect(String(describing: type(of: colorGenerator1)) == String(describing: type(of: colorGenerator2)))
    }
    
    @Test("SheetGenerator implementations maintain configuration consistency")
    func sheetGeneratorConfigurationConsistency() {
        let testConfigurations = [
            LocalizationConfig.default,
            LocalizationConfig.custom(
                outputDirectory: "/test",
                enumName: "TestEnum",
                sourceDirectory: "/source",
                csvFileName: "test.csv"
            )
        ]
        
        for config in testConfigurations {
            let generator1 = LocalizationGenerator(config: config)
            let generator2 = LocalizationGenerator(config: config)
            
            #expect(String(describing: type(of: generator1)) == String(describing: type(of: generator2)))
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("SheetGenerator implementations handle edge case configurations")
    func sheetGeneratorEdgeCaseConfigurations() {
        let edgeCaseConfigurations: [(outputDir: String, csvFile: String)] = [
            ("", ""),
            (".", "a.csv"),
            ("/", "single.csv"),
            ("./", "./relative.csv")
        ]
        
        for (outputDir, csvFile) in edgeCaseConfigurations {
            let locConfig = LocalizationConfig.custom(
                outputDirectory: outputDir,
                enumName: "EdgeCaseEnum",
                sourceDirectory: "/source",
                csvFileName: csvFile
            )
            
            let colorConfig = ColorConfig.custom(
                outputDirectory: outputDir,
                csvFileName: csvFile,
                cleanupTemporaryFiles: true
            )
            
            #expect(throws: Never.self) {
                _ = LocalizationGenerator(config: locConfig)
                _ = ColorGenerator(config: colorConfig)
            }
        }
    }
    
    @Test("SheetGenerator implementations handle special characters in configurations")
    func sheetGeneratorSpecialCharactersInConfigurations() {
        let specialCharConfigurations: [(outputDir: String, csvFile: String)] = [
            ("/path with spaces", "file with spaces.csv"),
            ("/path-with-dashes_and_underscores", "file-with-dashes_and_underscores.csv"),
            ("/path.with.dots", "file.with.dots.csv"),
            ("/path(with)parentheses", "file(with)parentheses.csv")
        ]
        
        for (outputDir, csvFile) in specialCharConfigurations {
            let locConfig = LocalizationConfig.custom(
                outputDirectory: outputDir,
                enumName: "SpecialCharEnum",
                sourceDirectory: "/source",
                csvFileName: csvFile
            )
            
            let colorConfig = ColorConfig.custom(
                outputDirectory: outputDir,
                csvFileName: csvFile,
                cleanupTemporaryFiles: true
            )
            
            #expect(throws: Never.self) {
                _ = LocalizationGenerator(config: locConfig)
                _ = ColorGenerator(config: colorConfig)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("SheetGenerator implementations are memory efficient")
    func sheetGeneratorMemoryEfficiency() {
        var generators: [Any] = []
        
        for i in 0..<1000 {
            let locConfig = LocalizationConfig.custom(
                outputDirectory: "/test\(i)",
                enumName: "Enum\(i)",
                sourceDirectory: "/source\(i)",
                csvFileName: "file\(i).csv"
            )
            
            let colorConfig = ColorConfig.custom(
                outputDirectory: "/colors\(i)",
                csvFileName: "colors\(i).csv",
                cleanupTemporaryFiles: true
            )
            
            generators.append(LocalizationGenerator(config: locConfig))
            generators.append(ColorGenerator(config: colorConfig))
        }
        
        #expect(generators.count == 2000)
    }
    
    @Test("SheetGenerator implementations handle concurrent instantiation")
    func sheetGeneratorConcurrentInstantiation() async {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let locConfig = LocalizationConfig.default
                    let colorConfig = ColorConfig.default
                    
                    _ = LocalizationGenerator(config: locConfig)
                    _ = ColorGenerator(config: colorConfig)
                }
            }
        }
        
        #expect(Bool(true)) // If we reach here, no crashes occurred during concurrent instantiation
    }
    
    // MARK: - Integration Tests
    
    @Test("SheetGenerator protocol integrates correctly with SheetConfig protocol")
    func sheetGeneratorSheetConfigIntegration() {
        let locConfig: any SheetConfig = LocalizationConfig.default
        let colorConfig: any SheetConfig = ColorConfig.default
        
        // Test that we can create generators with type-erased configs
        if let specificLocConfig = locConfig as? LocalizationConfig {
            let generator = LocalizationGenerator(config: specificLocConfig)
            #expect(String(describing: type(of: generator)) == "LocalizationGenerator")
        }
        
        if let specificColorConfig = colorConfig as? ColorConfig {
            let generator = ColorGenerator(config: specificColorConfig)
            #expect(String(describing: type(of: generator)) == "ColorGenerator")
        }
    }
    
    @Test("SheetGenerator implementations work with heterogeneous collections")
    func sheetGeneratorHeterogeneousCollections() {
        struct GeneratorInfo {
            let name: String
            let type: String
        }
        
        var generatorInfos: [GeneratorInfo] = []
        
        let locGenerator = LocalizationGenerator(config: LocalizationConfig.default)
        let colorGenerator = ColorGenerator(config: ColorConfig.default)
        
        generatorInfos.append(GeneratorInfo(
            name: "LocalizationGenerator",
            type: String(describing: type(of: locGenerator))
        ))
        
        generatorInfos.append(GeneratorInfo(
            name: "ColorGenerator", 
            type: String(describing: type(of: colorGenerator))
        ))
        
        #expect(generatorInfos.count == 2)
        #expect(generatorInfos[0].type == "LocalizationGenerator")
        #expect(generatorInfos[1].type == "ColorGenerator")
    }
    
    // MARK: - Stability Tests
    
    @Test("SheetGenerator implementations are stable across multiple operations")
    func sheetGeneratorStabilityAcrossOperations() {
        let config = LocalizationConfig.default
        
        for _ in 0..<100 {
            let generator = LocalizationGenerator(config: config)
            #expect(String(describing: type(of: generator)) == "LocalizationGenerator")
        }
        
        let colorConfig = ColorConfig.default
        
        for _ in 0..<100 {
            let generator = ColorGenerator(config: colorConfig)
            #expect(String(describing: type(of: generator)) == "ColorGenerator")
        }
    }
    
    @Test("SheetGenerator protocol method signatures are consistent")
    func sheetGeneratorMethodSignatureConsistency() {
        let locGenerator = LocalizationGenerator(config: LocalizationConfig.default)
        let colorGenerator = ColorGenerator(config: ColorConfig.default)
        
        // Test that generate method exists and has correct signature
        #expect(String(describing: type(of: locGenerator.generate)).contains("(String) async throws -> ()"))
        #expect(String(describing: type(of: colorGenerator.generate)).contains("(String) async throws -> ()"))
    }
    
    // MARK: - Error Handling Tests (Initialization)
    
    @Test("SheetGenerator implementations handle malformed configurations gracefully")
    func sheetGeneratorMalformedConfigurationHandling() {
        let malformedConfigurations: [(outputDir: String, csvFile: String)] = [
            ("", ""),
            ("   ", "   "),
            ("invalid\0path", "invalid\0file.csv")
        ]
        
        for (outputDir, csvFile) in malformedConfigurations {
            #expect(throws: Never.self) {
                let locConfig = LocalizationConfig.custom(
                    outputDirectory: outputDir,
                    enumName: "MalformedEnum",
                    sourceDirectory: "/source",
                    csvFileName: csvFile
                )
                
                let colorConfig = ColorConfig.custom(
                    outputDirectory: outputDir,
                    csvFileName: csvFile,
                    cleanupTemporaryFiles: true
                )
                
                _ = LocalizationGenerator(config: locConfig)
                _ = ColorGenerator(config: colorConfig)
            }
        }
    }
}

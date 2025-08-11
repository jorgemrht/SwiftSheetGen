import Testing
import Foundation
@testable import SheetLocalizer

// MARK: - Configuration Defaults Tests

@Suite
struct ConfigurationDefaultsTests {
    
    @Test
    func test_defaultLocalizationConfigValues() {
        let config = LocalizationConfig.default
        
        #expect(!config.outputDirectory.isEmpty)
        #expect(!config.enumName.isEmpty)
        #expect(!config.sourceDirectory.isEmpty)
        #expect(!config.csvFileName.isEmpty)
        #expect(config.csvFileName.hasSuffix(".csv"))
        
        #expect(config.cleanupTemporaryFiles == true)
        #expect(config.unifiedLocalizationDirectory == true)
        #expect(config.useStringsCatalog == false)
    }
    
    @Test
    func test_defaultColorConfigValues() {
        let config = ColorConfig.default
        
        #expect(!config.outputDirectory.isEmpty)
        #expect(!config.csvFileName.isEmpty)
        #expect(config.csvFileName.hasSuffix(".csv"))
        
        #expect(config.cleanupTemporaryFiles == true)
    }
    
    @Test
    func test_configurationFactoryMethodsConsistency() {

        let custom1 = LocalizationConfig.custom(
            outputDirectory: "Test1",
            enumName: "Test1Enum",
            sourceDirectory: "Test1Source",
            csvFileName: "test1.csv",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        let custom2 = LocalizationConfig(
            outputDirectory: "Test1",
            enumName: "Test1Enum",
            sourceDirectory: "Test1Source",
            csvFileName: "test1.csv",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        #expect(custom1.outputDirectory == custom2.outputDirectory)
        #expect(custom1.enumName == custom2.enumName)
        #expect(custom1.sourceDirectory == custom2.sourceDirectory)
        #expect(custom1.csvFileName == custom2.csvFileName)
        #expect(custom1.cleanupTemporaryFiles == custom2.cleanupTemporaryFiles)
        #expect(custom1.unifiedLocalizationDirectory == custom2.unifiedLocalizationDirectory)
        #expect(custom1.useStringsCatalog == custom2.useStringsCatalog)
    }
}

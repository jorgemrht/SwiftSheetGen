import Testing
import Foundation
@testable import SwiftSheetGenCLICore
@testable import SheetLocalizer

@Suite
struct SheetConfigTest {
    
    
    @Test
    func localizationConfigSheetConfigImplementation() {
        let config = LocalizationConfig.default
        
        #expect(config.outputDirectory == "./")
        #expect(config.csvFileName == "localizables.csv")
        #expect(config.cleanupTemporaryFiles == true)
        
        let customConfig = LocalizationConfig.custom(
            outputDirectory: "/custom/path",
            enumName: "CustomEnum", 
            sourceDirectory: "/source",
            csvFileName: "custom.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        #expect(customConfig.outputDirectory == "/custom/path")
        #expect(customConfig.csvFileName == "custom.csv")
        #expect(customConfig.cleanupTemporaryFiles == false)
    }
    
    @Test
    func colorConfigSheetConfigImplementation() {
        let config = ColorConfig.default
        
        #expect(config.outputDirectory == "Colors")
        #expect(config.csvFileName == "generated_colors.csv")
        #expect(config.cleanupTemporaryFiles == true)
        
        let customConfig = ColorConfig.custom(
            outputDirectory: "/custom/colors",
            csvFileName: "my_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(customConfig.outputDirectory == "/custom/colors")
        #expect(customConfig.csvFileName == "my_colors.csv")
        #expect(customConfig.cleanupTemporaryFiles == false)
    }
    
    
    @Test
    func sheetConfigPathFormatHandling() {
        let pathFormats = [
            "./relative",
            "/absolute/path",
            "../parent/path",
            "simple/path",
            "/path/with spaces",
            "/path-with-dashes_and_underscores",
            "/path/with.dots"
        ]
        
        for outputPath in pathFormats {
            let locConfig = LocalizationConfig.custom(
                outputDirectory: outputPath,
                enumName: "TestEnum",
                sourceDirectory: "/source",
                csvFileName: "test.csv"
            )
            
            let colorConfig = ColorConfig.custom(
                outputDirectory: outputPath,
                csvFileName: "test.csv",
                cleanupTemporaryFiles: true
            )
            
            #expect(locConfig.outputDirectory == outputPath)
            #expect(colorConfig.outputDirectory == outputPath)
        }
    }
    
    @Test
    func sheetConfigCSVFileNameHandling() {
        let csvFileNames = [
            "simple.csv",
            "file_with_underscores.csv",
            "file-with-dashes.csv",
            "file.with.dots.csv",
            "file with spaces.csv",
            "very_long_filename_with_many_characters_123.csv",
            "UPPERCASE.CSV",
            "MixedCase.CSV"
        ]
        
        for csvFileName in csvFileNames {
            let locConfig = LocalizationConfig.custom(
                outputDirectory: "./test",
                enumName: "TestEnum",
                sourceDirectory: "/source",
                csvFileName: csvFileName
            )
            
            let colorConfig = ColorConfig.custom(
                outputDirectory: "./test",
                csvFileName: csvFileName,
                cleanupTemporaryFiles: true
            )
            
            #expect(locConfig.csvFileName == csvFileName)
            #expect(colorConfig.csvFileName == csvFileName)
        }
    }
    
    @Test
    func sheetConfigCleanupFlagsHandling() {
        let cleanupValues = [true, false]
        
        for cleanupValue in cleanupValues {
            let locConfig = LocalizationConfig.custom(
                outputDirectory: "./test",
                enumName: "TestEnum",
                sourceDirectory: "/source",
                csvFileName: "test.csv",
                cleanupTemporaryFiles: cleanupValue
            )
            
            let colorConfig = ColorConfig.custom(
                outputDirectory: "./test",
                csvFileName: "test.csv",
                cleanupTemporaryFiles: cleanupValue
            )
            
            #expect(locConfig.cleanupTemporaryFiles == cleanupValue)
            #expect(colorConfig.cleanupTemporaryFiles == cleanupValue)
        }
    }
    
    
    @Test
    func sheetConfigGenericContextUsage() {
        func processConfig<T: SheetConfig>(_ config: T) -> (String, String, Bool) {
            return (config.outputDirectory, config.csvFileName, config.cleanupTemporaryFiles)
        }
        
        let locConfig = LocalizationConfig.default
        let colorConfig = ColorConfig.default
        
        let locResult = processConfig(locConfig)
        let colorResult = processConfig(colorConfig)
        
        #expect(locResult.0 == "./")
        #expect(locResult.1 == "localizables.csv")
        #expect(locResult.2 == true)
        
        #expect(colorResult.0 == "Colors")
        #expect(colorResult.1 == "generated_colors.csv")
        #expect(colorResult.2 == true)
    }
    
    @Test
    func sheetConfigTypeErasureHeterogeneousCollections() {
        let configs: [any SheetConfig] = [
            LocalizationConfig.default,
            ColorConfig.default,
            LocalizationConfig.custom(
                outputDirectory: "/custom",
                enumName: "Custom",
                sourceDirectory: "/src",
                csvFileName: "custom.csv"
            ),
            ColorConfig.custom(
                outputDirectory: "/custom/colors",
                csvFileName: "custom_colors.csv",
                cleanupTemporaryFiles: true
            )
        ]
        
        #expect(configs.count == 4)
        
        for config in configs {
            #expect(!config.outputDirectory.isEmpty)
            #expect(!config.csvFileName.isEmpty)
            #expect(config.csvFileName.hasSuffix(".csv"))
            #expect(config.cleanupTemporaryFiles == true || config.cleanupTemporaryFiles == false)
        }
        
        let outputDirectories = configs.map { $0.outputDirectory }
        #expect(outputDirectories.contains("./"))
        #expect(outputDirectories.contains("Colors"))
        #expect(outputDirectories.contains("/custom"))
        #expect(outputDirectories.contains("/custom/colors"))
    }
    
    @Test
    func sheetConfigExistentialTypeSafety() {
        let locConfig: any SheetConfig = LocalizationConfig.default
        let colorConfig: any SheetConfig = ColorConfig.default
        
        func extractProperties(from config: any SheetConfig) -> (directory: String, filename: String, cleanup: Bool) {
            return (config.outputDirectory, config.csvFileName, config.cleanupTemporaryFiles)
        }
        
        let locProperties = extractProperties(from: locConfig)
        let colorProperties = extractProperties(from: colorConfig)
        
        #expect(locProperties.directory == "./")
        #expect(locProperties.filename == "localizables.csv")
        #expect(locProperties.cleanup == true)
        
        #expect(colorProperties.directory == "Colors")
        #expect(colorProperties.filename == "generated_colors.csv")
        #expect(colorProperties.cleanup == true)
    }
    
    
    @Test
    func sheetConfigImplementationConsistency() {
        let locConfig1 = LocalizationConfig.default
        let locConfig2 = LocalizationConfig.default
        
        #expect(locConfig1.outputDirectory == locConfig2.outputDirectory)
        #expect(locConfig1.csvFileName == locConfig2.csvFileName)
        #expect(locConfig1.cleanupTemporaryFiles == locConfig2.cleanupTemporaryFiles)
        
        let colorConfig1 = ColorConfig.default
        let colorConfig2 = ColorConfig.default
        
        #expect(colorConfig1.outputDirectory == colorConfig2.outputDirectory)
        #expect(colorConfig1.csvFileName == colorConfig2.csvFileName)
        #expect(colorConfig1.cleanupTemporaryFiles == colorConfig2.cleanupTemporaryFiles)
    }
    
    @Test
    func sheetConfigCustomConfigurationHandling() {
        let customParams = [
            (dir: "/path1", csv: "file1.csv", cleanup: true),
            (dir: "/path2", csv: "file2.csv", cleanup: false),
            (dir: "./relative", csv: "relative.csv", cleanup: true),
            (dir: "../parent", csv: "parent_file.csv", cleanup: false)
        ]
        
        for params in customParams {
            let locConfig = LocalizationConfig.custom(
                outputDirectory: params.dir,
                enumName: "TestEnum",
                sourceDirectory: "/src",
                csvFileName: params.csv,
                cleanupTemporaryFiles: params.cleanup
            )
            
            let colorConfig = ColorConfig.custom(
                outputDirectory: params.dir,
                csvFileName: params.csv,
                cleanupTemporaryFiles: params.cleanup
            )
            
            #expect(locConfig.outputDirectory == params.dir)
            #expect(locConfig.csvFileName == params.csv)
            #expect(locConfig.cleanupTemporaryFiles == params.cleanup)
            
            #expect(colorConfig.outputDirectory == params.dir)
            #expect(colorConfig.csvFileName == params.csv)
            #expect(colorConfig.cleanupTemporaryFiles == params.cleanup)
        }
    }
    
    
    @Test
    func sheetConfigEdgeCaseValues() {
        let edgeCases = [
            (dir: "", csv: "", cleanup: true),
            (dir: "/", csv: "a.csv", cleanup: false),
            (dir: ".", csv: ".csv", cleanup: true),
            (dir: "/very/long/path/with/many/nested/directories/that/might/cause/issues", csv: "very_long_filename_with_many_characters_that_might_cause_filesystem_issues.csv", cleanup: false)
        ]
        
        for edgeCase in edgeCases {
            #expect(throws: Never.self) {
                let locConfig = LocalizationConfig.custom(
                    outputDirectory: edgeCase.dir,
                    enumName: "EdgeCase",
                    sourceDirectory: "/src",
                    csvFileName: edgeCase.csv,
                    cleanupTemporaryFiles: edgeCase.cleanup
                )
                
                let colorConfig = ColorConfig.custom(
                    outputDirectory: edgeCase.dir,
                    csvFileName: edgeCase.csv,
                    cleanupTemporaryFiles: edgeCase.cleanup
                )
                
                #expect(locConfig.outputDirectory == edgeCase.dir)
                #expect(colorConfig.outputDirectory == edgeCase.dir)
            }
        }
    }
    
    @Test
    func sheetConfigPropertyStability() {
        let locConfig = LocalizationConfig.custom(
            outputDirectory: "/stable/test",
            enumName: "StableEnum",
            sourceDirectory: "/src",
            csvFileName: "stable.csv",
            cleanupTemporaryFiles: false
        )
        
        let colorConfig = ColorConfig.custom(
            outputDirectory: "/stable/colors",
            csvFileName: "stable_colors.csv",
            cleanupTemporaryFiles: true
        )
        
        for _ in 0..<100 {
            #expect(locConfig.outputDirectory == "/stable/test")
            #expect(locConfig.csvFileName == "stable.csv")
            #expect(locConfig.cleanupTemporaryFiles == false)
            
            #expect(colorConfig.outputDirectory == "/stable/colors")
            #expect(colorConfig.csvFileName == "stable_colors.csv")
            #expect(colorConfig.cleanupTemporaryFiles == true)
        }
    }
    
    
    @Test
    func sheetConfigMemoryEfficiency() {
        var configs: [any SheetConfig] = []
        
        for i in 0..<1000 {
            configs.append(LocalizationConfig.custom(
                outputDirectory: "/test\(i)",
                enumName: "Enum\(i)",
                sourceDirectory: "/src\(i)",
                csvFileName: "file\(i).csv",
                cleanupTemporaryFiles: i % 2 == 0
            ))
            
            configs.append(ColorConfig.custom(
                outputDirectory: "/colors\(i)",
                csvFileName: "colors\(i).csv",
                cleanupTemporaryFiles: i % 2 == 1
            ))
        }
        
        #expect(configs.count == 2000)
        
        for (index, config) in configs.enumerated() {
            #expect(!config.outputDirectory.isEmpty)
            #expect(!config.csvFileName.isEmpty)
            
            if index % 2 == 0 {
                #expect(config.outputDirectory.hasPrefix("/test"))
            } else {
                #expect(config.outputDirectory.hasPrefix("/colors"))
            }
        }
    }
    
    @Test
    func sheetConfigConcurrentAccess() async {
        let locConfig = LocalizationConfig.default
        let colorConfig = ColorConfig.default
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    #expect(locConfig.outputDirectory == "./")
                    #expect(locConfig.csvFileName == "localizables.csv")
                    #expect(locConfig.cleanupTemporaryFiles == true)
                    
                    #expect(colorConfig.outputDirectory == "Colors")
                    #expect(colorConfig.csvFileName == "generated_colors.csv")
                    #expect(colorConfig.cleanupTemporaryFiles == true)
                }
            }
        }
    }
}

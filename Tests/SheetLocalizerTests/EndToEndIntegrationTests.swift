import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct EndToEndIntegrationTests {
    
    @Test
    func completeLocalizationWorkflowFromCSVToFiles() async throws {
        let localizationCSV = SharedTestData.localizationCSV
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("localization.csv")
        try localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "AppStrings",
            sourceDirectory: tempDir.path,
            csvFileName: "localization.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let enumFile = tempDir.appendingPathComponent("AppStrings.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
        
        let esFile = tempDir.appendingPathComponent("es.lproj/Localizable.strings")
        #expect(FileManager.default.fileExists(atPath: esFile.path))
        
        let enFile = tempDir.appendingPathComponent("en.lproj/Localizable.strings")
        #expect(FileManager.default.fileExists(atPath: enFile.path))
        
        let frFile = tempDir.appendingPathComponent("fr.lproj/Localizable.strings")
        #expect(FileManager.default.fileExists(atPath: frFile.path))
        
        let enumContent = try String(contentsOf: enumFile, encoding: .utf8)
        #expect(enumContent.contains("enum AppStrings"))
        #expect(enumContent.contains("commonAppNameText"))
        #expect(enumContent.contains("loginTitleText"))
        
        let esContent = try String(contentsOf: esFile, encoding: .utf8)
        #expect(esContent.contains("common_app_name_text\" = \"jorgemrht\""))
        #expect(esContent.contains("login_title_text\" = \"Login\""))
        
        let enContent = try String(contentsOf: enFile, encoding: .utf8)
        #expect(enContent.contains("common_app_name_text\" = \"My App\""))
        #expect(enContent.contains("login_title_text\" = \"Login\""))
        
        let frContent = try String(contentsOf: frFile, encoding: .utf8)
        #expect(frContent.contains("common_app_name_text\" = \"Mon App\""))
        #expect(frContent.contains("login_title_text\" = \"Connexion\""))
    }
    
    @Test
    func completeColorWorkflowFromCSVToFiles() async throws {
        let colorCSV = SharedTestData.colorsCSV
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("colors.csv")
        try colorCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(
            outputDirectory: tempDir.path,
            csvFileName: "colors.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        #expect(FileManager.default.fileExists(atPath: colorsFile.path))
        
        let dynamicFile = tempDir.appendingPathComponent("Color+Dynamic.swift")
        #expect(FileManager.default.fileExists(atPath: dynamicFile.path))
        
        let colorsContent = try String(contentsOf: colorsFile, encoding: .utf8)
        #expect(colorsContent.contains("import SwiftUI"))
        #expect(colorsContent.contains("extension ShapeStyle"))
        #expect(colorsContent.contains("primaryBackgroundColor"))
        #expect(colorsContent.contains("secondaryBackgroundColor"))
        #expect(colorsContent.contains("primaryTextColor"))
        #expect(colorsContent.contains("secondaryTextColor"))
        #expect(colorsContent.contains("placeholderTextColor"))
        #expect(colorsContent.contains("ColorPaletteGrid"))
        
        let dynamicContent = try String(contentsOf: dynamicFile, encoding: .utf8)
        #expect(dynamicContent.contains("import SwiftUI"))
        #expect(dynamicContent.contains("extension Color"))
        #expect(dynamicContent.contains("init(light:"))
        #expect(dynamicContent.contains("init(any:"))
        #expect(dynamicContent.contains("userInterfaceStyle"))
    }
    
    @Test
    func stringsCatalogGenerationWorkflow() async throws {

        let localizationCSV = SharedTestData.localizationCSV
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("localization.csv")
        try localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "L10n",
            sourceDirectory: tempDir.path,
            csvFileName: "localization.csv",
            cleanupTemporaryFiles: false,
            useStringsCatalog: true
        )
        
        let generator = LocalizationGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let catalogFile = tempDir.appendingPathComponent("Localizable.xcstrings")
        #expect(FileManager.default.fileExists(atPath: catalogFile.path))
        
        let catalogData = try Data(contentsOf: catalogFile)
        let catalog = try JSONSerialization.jsonObject(with: catalogData) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        #expect(catalogDict["version"] as? String == "1.0")
        #expect(catalogDict["sourceLanguage"] as? String == "es")
        
        let strings = catalogDict["strings"] as? [String: Any]
        let stringsDict = try #require(strings)
        
        #expect(stringsDict.keys.contains("common_app_name_text"))
        #expect(stringsDict.keys.contains("login_title_text"))
        #expect(stringsDict.keys.contains("settings_notifications_text"))
    }
    
    @Test
    func recoveryFromPartiallyCorruptedCSV() async throws {
        let partiallyCorruptedCSV = SharedTestData.localizationCSV
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("corrupted.csv")
        try partiallyCorruptedCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "L10n",
            sourceDirectory: tempDir.path,
            csvFileName: "corrupted.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        
        do {
            try await generator.generate(from: csvFile.path)
            
            let enumFile = tempDir.appendingPathComponent("L10n.swift")
            if FileManager.default.fileExists(atPath: enumFile.path) {
                let content = try String(contentsOf: enumFile, encoding: .utf8)
                #expect(content.contains("commonAppNameText"))
            }
        } catch {
            #expect(error is SheetLocalizerError)
        }
    }
    
    @Test
    func multiLanguageLocalizationGeneration() async throws {
        let multiLangCSV = SharedTestData.localizationCSV
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("multilang.csv")
        try multiLangCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "MultiLang",
            sourceDirectory: tempDir.path,
            csvFileName: "multilang.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let languages = ["es", "en", "fr"]
        for lang in languages {
            let langFile = tempDir.appendingPathComponent("\(lang).lproj/Localizable.strings")
            #expect(FileManager.default.fileExists(atPath: langFile.path))
            
            let content = try String(contentsOf: langFile, encoding: .utf8)
            #expect(content.contains("common_app_name_text"))
            #expect(content.contains("login_title_text"))
            #expect(content.contains("settings_notifications_text"))
        }
        
        let esFile = tempDir.appendingPathComponent("es.lproj/Localizable.strings")
        let esContent = try String(contentsOf: esFile, encoding: .utf8)
        #expect(esContent.contains("jorgemrht"))
        
        let enFile = tempDir.appendingPathComponent("en.lproj/Localizable.strings")
        let enContent = try String(contentsOf: enFile, encoding: .utf8)
        #expect(enContent.contains("My App"))
        
        let frFile = tempDir.appendingPathComponent("fr.lproj/Localizable.strings")
        let frContent = try String(contentsOf: frFile, encoding: .utf8)
        #expect(frContent.contains("Mon App"))
    }
    
    @Test
    func largeDatasetProcessingIntegration() async throws {
      
        var largeCsvContent = "[Check], [View], [Item], [Type], es, en, fr\n"
        
        let views = ["login", "profile", "settings", "dashboard", "help"]
        let items = ["title", "subtitle", "button", "label", "message", "error", "success", "warning"]
        let _ = ["text"]
        
        for view in views {
            for item in items {
                for i in 1...50 {
                    largeCsvContent += """
                    "", \(view), \(item)\(i), text, "Spanish \(view) \(item) \(i)", "English \(view) \(item) \(i)", "French \(view) \(item) \(i)"
                    
                    """
                }
            }
        }
        largeCsvContent += "[END], , , , , , \n"
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("large_dataset.csv")
        try largeCsvContent.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "LargeL10n",
            sourceDirectory: tempDir.path,
            csvFileName: "large_dataset.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        
        let startTime = Date()
        try await generator.generate(from: csvFile.path)
        let endTime = Date()
        
        let processingTime = endTime.timeIntervalSince(startTime)
        
        #expect(processingTime < 30.0)
        
        let enumFile = tempDir.appendingPathComponent("LargeL10n.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
        
        let enumContent = try String(contentsOf: enumFile, encoding: .utf8)
        #expect(enumContent.contains("loginTitle1Text"))
        #expect(enumContent.contains("profileButton50Text"))
    }
    
    @Test
    func platformSpecificColorGeneration() async throws {
        let platformColorCSV = SharedTestData.colorsCSV
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("platform_colors.csv")
        try platformColorCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = ColorConfig(
            outputDirectory: tempDir.path,
            csvFileName: "platform_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let dynamicFile = tempDir.appendingPathComponent("Color+Dynamic.swift")
        let dynamicContent = try String(contentsOf: dynamicFile, encoding: .utf8)
        
        #expect(dynamicContent.contains("#if canImport(UIKit)"))
        #expect(dynamicContent.contains("#if canImport(AppKit)"))
        #expect(dynamicContent.contains("NSColor"))
        #expect(dynamicContent.contains("UIColor"))
        #expect(dynamicContent.contains("userInterfaceStyle"))
        #expect(dynamicContent.contains("appearance.name"))
        #expect(dynamicContent.contains("#if os(watchOS)"))
    }
    
    @Test
    func directoryStructureCreationAndCleanup() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let outputDir = tempDir.appendingPathComponent("Generated/Localization")
        
        let localizationCSV = SharedTestData.localizationCSV
        
        let csvFile = tempDir.appendingPathComponent("test.csv")
        try localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: outputDir.path,
            enumName: "Test",
            sourceDirectory: outputDir.path,
            csvFileName: "test.csv",
            cleanupTemporaryFiles: true
        )
        
        let generator = LocalizationGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        #expect(FileManager.default.fileExists(atPath: outputDir.path))
        
        let esDir = outputDir.appendingPathComponent("es.lproj")
        #expect(FileManager.default.fileExists(atPath: esDir.path))
        
        let enDir = outputDir.appendingPathComponent("en.lproj")
        #expect(FileManager.default.fileExists(atPath: enDir.path))
        
        let enumFile = outputDir.appendingPathComponent("Test.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
        
        let esFile = esDir.appendingPathComponent("Localizable.strings")
        #expect(FileManager.default.fileExists(atPath: esFile.path))
        
        let enFile = enDir.appendingPathComponent("Localizable.strings")
        #expect(FileManager.default.fileExists(atPath: enFile.path))
    }
    
    @Test
    func differentConfigurationCombinations() async throws {
        let csvContent = SharedTestData.localizationCSV
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("config_test.csv")
        try csvContent.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config1 = LocalizationConfig(
            outputDirectory: tempDir.appendingPathComponent("Localizations").path,
            enumName: "Config1",
            sourceDirectory: tempDir.appendingPathComponent("Enums").path,
            csvFileName: "config_test.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: false
        )
        
        let generator1 = LocalizationGenerator(config: config1)
        try await generator1.generate(from: csvFile.path)
        
        let enumDir = tempDir.appendingPathComponent("Enums")
        let localizationDir = tempDir.appendingPathComponent("Localizations")
        
        #expect(FileManager.default.fileExists(atPath: enumDir.appendingPathComponent("Config1.swift").path))
        #expect(FileManager.default.fileExists(atPath: localizationDir.appendingPathComponent("es.lproj/Localizable.strings").path))
        
        let config2 = LocalizationConfig(
            outputDirectory: tempDir.appendingPathComponent("Unified").path,
            enumName: "Config2",
            sourceDirectory: tempDir.appendingPathComponent("Unified").path,
            csvFileName: "config_test.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: true
        )
        
        let generator2 = LocalizationGenerator(config: config2)
        try await generator2.generate(from: csvFile.path)
        
        let unifiedDir = tempDir.appendingPathComponent("Unified")
        #expect(FileManager.default.fileExists(atPath: unifiedDir.appendingPathComponent("Localizable.xcstrings").path))
    }
}

import Testing
import Foundation
@testable import SheetLocalizer

@Suite("LocalizationGenerator Tests")
struct LocalizationGeneratorTest {
    
    @Test
    func defaultInitialization() {
        let generator = LocalizationGenerator()
        #expect(type(of: generator) == LocalizationGenerator.self)
    }
    
    @Test
    func customInitialization() {
        let config = LocalizationConfig(
            outputDirectory: "/tmp/test",
            enumName: "TestStrings",
            sourceDirectory: "/tmp/test",
            csvFileName: "test.csv",
            cleanupTemporaryFiles: true,
            useStringsCatalog: false
        )
        let generator = LocalizationGenerator(config: config)
        #expect(type(of: generator) == LocalizationGenerator.self)
    }
    
    @Test
    func localizationGeneratorProcessesValidCSV() async throws {
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
        
        let esDir = tempDir.appendingPathComponent("es.lproj")
        let enDir = tempDir.appendingPathComponent("en.lproj")
        let frDir = tempDir.appendingPathComponent("fr.lproj")
        
        #expect(FileManager.default.fileExists(atPath: esDir.path))
        #expect(FileManager.default.fileExists(atPath: enDir.path))
        #expect(FileManager.default.fileExists(atPath: frDir.path))
        
        #expect(FileManager.default.fileExists(atPath: esDir.appendingPathComponent("Localizable.strings").path))
        #expect(FileManager.default.fileExists(atPath: enDir.appendingPathComponent("Localizable.strings").path))
        #expect(FileManager.default.fileExists(atPath: frDir.appendingPathComponent("Localizable.strings").path))
    }
    
    @Test
    func localizationGeneratorHandlesNonExistentCSV() async {
        let generator = LocalizationGenerator()
        
        await #expect(throws: (any Error).self) {
            try await generator.generate(from: "/non/existent/file.csv")
        }
    }
    
    @Test
    func localizationGeneratorHandlesEmptyCSV() async {
        let tempFile = SharedTestData.createTempFile(content: "")
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = LocalizationGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    @Test
    func localizationGeneratorHandlesInvalidHeader() async {
        let invalidCSV = "invalid,csv,content\nno,proper,headers,here"
        let tempFile = SharedTestData.createTempFile(content: invalidCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = LocalizationGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    @Test
    func localizationGeneratorHandlesInsufficientData() async {
        let headerOnlyCSV = """
        [Check],[View],[Item],[Type],es,en,fr
        """
        let tempFile = SharedTestData.createTempFile(content: headerOnlyCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let generator = LocalizationGenerator()
        
        await #expect(throws: SheetLocalizerError.self) {
            try await generator.generate(from: tempFile.path)
        }
    }
    
    
    @Test
    func localizationGeneratorFiltersInvalidRows() async throws {
        let csvWithMixedRows = """
        [Check],[View],[Item],[Type],es,en,fr
        ,common,validEntry,text,Entrada válida,Valid entry,Entrée valide
        ,[COMMENT],skipThis,text,Should be skipped,Should be skipped,Should be skipped
        ,common,,text,Empty item - should be skipped,Empty item - should be skipped,Empty item - should be skipped
        ,,validItem,text,Empty view - should be skipped,Empty view - should be skipped,Empty view - should be skipped
        ,common,validItem,,Empty type - should be skipped,Empty type - should be skipped,Empty type - should be skipped
        ,[INVALID],bracketView,text,Invalid bracket - should be skipped,Invalid bracket - should be skipped,Invalid bracket - should be skipped
        ,common,anotherValidEntry,text,Otra entrada válida,Another valid entry,Une autre entrée valide
        [END]
        """
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("mixed_localization.csv")
        try csvWithMixedRows.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "FilteredStrings",
            sourceDirectory: tempDir.path,
            csvFileName: "mixed_localization.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        let enumFile = tempDir.appendingPathComponent("FilteredStrings.swift")
        let enumContent = try String(contentsOf: enumFile, encoding: .utf8)
        
        #expect(enumContent.contains("validEntry"))
        #expect(enumContent.contains("anotherValidEntry"))
        
        #expect(!enumContent.contains("skipThis"))
        #expect(!enumContent.contains("Empty"))
        #expect(!enumContent.contains("INVALID"))
        #expect(!enumContent.contains("bracketView"))
    }
    
    
    @Test
    func localizationGeneratorGeneratesStringsCatalog() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("catalog_test.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "CatalogTest",
            sourceDirectory: tempDir.path,
            csvFileName: "catalog_test.csv",
            cleanupTemporaryFiles: false,
            useStringsCatalog: true
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        let catalogFile = tempDir.appendingPathComponent("Localizable.xcstrings")
        #expect(FileManager.default.fileExists(atPath: catalogFile.path))
        
        let catalogData = try Data(contentsOf: catalogFile)
        let catalogContent = String(data: catalogData, encoding: .utf8)!
        
        #expect(catalogContent.contains("sourceLanguage"))
        #expect(catalogContent.contains("version"))
        #expect(catalogContent.contains("strings"))
        
        #expect(throws: Never.self) {
            try JSONSerialization.jsonObject(with: catalogData)
        }
    }
    
    @Test
    func localizationGeneratorStringsCatalogIncludesAllLanguages() async throws {
        let csvWithMultipleLanguages = """
        [Check],[View],[Item],[Type],es,en,fr,de
        ,common,greeting,text,Hola,Hello,Bonjour,Hallo
        ,common,goodbye,text,Adiós,Goodbye,Au revoir,Auf Wiedersehen
        [END]
        """
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("multilang.csv")
        try csvWithMultipleLanguages.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "MultiLang",
            sourceDirectory: tempDir.path,
            csvFileName: "multilang.csv",
            cleanupTemporaryFiles: false,
            useStringsCatalog: true
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        let catalogFile = tempDir.appendingPathComponent("Localizable.xcstrings")
        let catalogData = try Data(contentsOf: catalogFile)
        let catalogContent = String(data: catalogData, encoding: .utf8)!
        
        #expect(catalogContent.contains("\"es\""))
        #expect(catalogContent.contains("\"en\""))
        #expect(catalogContent.contains("\"fr\""))
        #expect(catalogContent.contains("\"de\""))
        
        #expect(catalogContent.contains("common_greeting_text"))
        #expect(catalogContent.contains("common_goodbye_text"))
    }
    
    
    @Test
    func localizationGeneratorProcessesTemplateVariables() async throws {
        let csvWithTemplates = """
        [Check],[View],[Item],[Type],es,en,fr
        ,common,user_greeting,text,Hola {{username}},Hello {{username}},Bonjour {{username}}
        ,common,item_count,text,Tienes {{count}} elementos,You have {{count}} items,Vous avez {{count}} éléments
        ,common,multiple_vars,text,{{user}} tiene {{count}} mensajes,{{user}} has {{count}} messages,{{user}} a {{count}} messages
        [END]
        """
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("templates.csv")
        try csvWithTemplates.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "Templates",
            sourceDirectory: tempDir.path,
            csvFileName: "templates.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        let esStringsFile = tempDir.appendingPathComponent("es.lproj/Localizable.strings")
        let esContent = try String(contentsOf: esStringsFile, encoding: .utf8)
        
        #expect(esContent.contains("%@"), "Should convert template variables to %@")
        #expect(!esContent.contains("{{"), "Should not contain original template syntax")
        #expect(!esContent.contains("}}"), "Should not contain original template syntax")
        
        #expect(esContent.contains("Hola %@"), "Should convert {{username}} to %@")
        #expect(esContent.contains("Tienes %@ elementos"), "Should convert {{count}} to %@")
        #expect(esContent.contains("%@ tiene %@ mensajes"), "Should convert multiple variables to %@")
    }
    
    
    @Test
    func localizationGeneratorHandlesSpecialCharacters() async throws {
        let csvWithSpecialChars = """
        [Check],[View],[Item],[Type],es,en,fr
        ,common,emoji_test,text,Hola 👋 Mundo,Hello 👋 World,Bonjour 👋 Monde
        ,common,ampersand_test,text,Título & Descripción,Title & Description,Titre & Description
        ,common,quotes_test,text,Dice: "Hola",Says: "Hello",Dit: "Bonjour"
        ,common,special_chars,text,Ñoño español ñ,Special chars test,Caractères spéciaux àèé
        [END]
        """
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("special_chars.csv")
        try csvWithSpecialChars.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "SpecialChars",
            sourceDirectory: tempDir.path,
            csvFileName: "special_chars.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        let esStringsFile = tempDir.appendingPathComponent("es.lproj/Localizable.strings")
        let esContent = try String(contentsOf: esStringsFile, encoding: .utf8)
        
        #expect(esContent.contains("👋"), "Should preserve emoji characters")
        #expect(esContent.contains("&"), "Should preserve ampersand characters")
        #expect(esContent.contains("ñ"), "Should preserve Spanish characters")
        #expect(esContent.contains("Dice: Hola"), "Should handle quotes correctly")
    }
    
    
    @Test
    func localizationGeneratorCreatesNestedDirectories() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let nestedOutputDir = tempDir.appendingPathComponent("deeply/nested/output")
        
        #expect(!FileManager.default.fileExists(atPath: nestedOutputDir.path))
        
        let csvFile = tempDir.appendingPathComponent("localization.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: nestedOutputDir.path,
            enumName: "NestedTest",
            sourceDirectory: nestedOutputDir.path,
            csvFileName: "localization.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvFile.path)
        
        #expect(FileManager.default.fileExists(atPath: nestedOutputDir.path))
        #expect(FileManager.default.fileExists(atPath: nestedOutputDir.appendingPathComponent("NestedTest.swift").path))
        #expect(FileManager.default.fileExists(atPath: nestedOutputDir.appendingPathComponent("es.lproj").path))
        #expect(FileManager.default.fileExists(atPath: nestedOutputDir.appendingPathComponent("en.lproj").path))
        #expect(FileManager.default.fileExists(atPath: nestedOutputDir.appendingPathComponent("fr.lproj").path))
    }
    
    
    @Test
    func localizationGeneratorDetectsTuistProject() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let tuistVersionFile = tempDir.appendingPathComponent(".tuist-version")
        try "4.0.0".write(to: tuistVersionFile, atomically: true, encoding: .utf8)
        
        let csvFile = tempDir.appendingPathComponent("localization.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "TuistTest",
            sourceDirectory: tempDir.path,
            csvFileName: "localization.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        
        try await generator.generate(from: csvFile.path)
        
        let enumFile = tempDir.appendingPathComponent("TuistTest.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
        
        let languages = ["es", "en", "fr"]
        for language in languages {
            let langDir = tempDir.appendingPathComponent("\(language).lproj")
            #expect(FileManager.default.fileExists(atPath: langDir.path))
        }
    }
    
    
    @Test
    func localizationGeneratorRespectsCleanupConfig() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvFile = tempDir.appendingPathComponent("localization.csv")
        try SharedTestData.localizationCSV.write(to: csvFile, atomically: true, encoding: .utf8)
        
        let configNoCleanup = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "NoCleanupTest",
            sourceDirectory: tempDir.path,
            csvFileName: "localization.csv",
            cleanupTemporaryFiles: false
        )
        
        let generatorNoCleanup = LocalizationGenerator(config: configNoCleanup)
        try await generatorNoCleanup.generate(from: csvFile.path)
        
        #expect(FileManager.default.fileExists(atPath: csvFile.path))
        
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("NoCleanupTest.swift").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("es.lproj").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("en.lproj").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("fr.lproj").path))
    }
    
    
    @Test
    func localizationGeneratorXcodeIntegration() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
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
        
        let enumFile = tempDir.appendingPathComponent("IntegrationTest.swift")
        #expect(FileManager.default.fileExists(atPath: enumFile.path))
        
        let languages = ["es", "en", "fr"]
        for language in languages {
            let langDir = tempDir.appendingPathComponent("\(language).lproj")
            let stringsFile = langDir.appendingPathComponent("Localizable.strings")
            #expect(FileManager.default.fileExists(atPath: langDir.path))
            #expect(FileManager.default.fileExists(atPath: stringsFile.path))
        }
    }
}
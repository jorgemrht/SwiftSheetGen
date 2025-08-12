import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct ModelsValidationTests {
    
    @Test
    func localizationEntryValidData() {
        let entry = LocalizationEntry(
            view: "login",
            item: "title", 
            type: "text",
            translations: ["en": "Login", "es": "Iniciar sesión"]
        )
        
        #expect(entry.view == "login")
        #expect(entry.item == "title")
        #expect(entry.type == "text")
        #expect(entry.translations["en"] == "Login")
        #expect(entry.translations["es"] == "Iniciar sesión")
    }
    
    @Test
    func localizationEntryKeyGeneration() {
        let entry = LocalizationEntry(
            view: "profile",
            item: "user_name",
            type: "text",
            translations: ["en": "Username"]
        )
        
        let expectedKey = "profile_user_name_text"
        #expect(entry.key == expectedKey)
    }
    
    @Test
    func localizationEntryEmptyTranslations() {
        let entry = LocalizationEntry(
            view: "common",
            item: "empty",
            type: "text",
            translations: [:]
        )
        
        #expect(entry.translations.isEmpty)
        #expect(entry.key == "common_empty_text")
    }
    
    @Test
    func localizationEntrySpecialCharacters() {
        let entry = LocalizationEntry(
            view: "test",
            item: "special",
            type: "text",
            translations: [
                "en": "Text with \"quotes\" and symbols: @#$%",
                "es": "Texto con acentos: áéíóú ñ"
            ]
        )
        
        #expect(entry.translations["en"]?.contains("\"quotes\"") == true)
        #expect(entry.translations["es"]?.contains("áéíóú") == true)
    }
    
    // MARK: - ColorEntry Tests
    
    @Test
    func colorEntryAllHexValues() {
        let entry = ColorEntry(
            name: "primaryColor",
            anyHex: "#FF0000",
            lightHex: "#FF3333",
            darkHex: "#CC0000"
        )
        
        #expect(entry.name == "primaryColor")
        #expect(entry.anyHex == "#FF0000")
        #expect(entry.lightHex == "#FF3333")
        #expect(entry.darkHex == "#CC0000")
    }
    
    @Test
    func colorEntryNilAnyHex() {
        let entry = ColorEntry(
            name: "backgroundColor",
            anyHex: nil,
            lightHex: "#FFFFFF",
            darkHex: "#000000"
        )
        
        #expect(entry.name == "backgroundColor")
        #expect(entry.anyHex == nil)
        #expect(entry.lightHex == "#FFFFFF")
        #expect(entry.darkHex == "#000000")
    }
    
    @Test
    func colorEntryRequiredValues() {
        let entry = ColorEntry(
            name: "accentColor",
            anyHex: nil,
            lightHex: "#00AAFF",
            darkHex: nil
        )
        
        #expect(entry.name == "accentColor")
        #expect(entry.anyHex == nil)
        #expect(entry.lightHex == "#00AAFF")
        #expect(entry.darkHex == nil)
    }
    
    @Test
    func test_localizationRowCreation() {
        let row = LocalizationRow(
            view: "login",
            item: "title",
            type: "text",
            translations: ["en": "Login", "es": "Iniciar sesión", "fr": "Connexion"]
        )
        
        #expect(row.view == "login")
        #expect(row.item == "title")
        #expect(row.type == "text")
        #expect(row.translations["en"] == "Login")
        #expect(row.translations["es"] == "Iniciar sesión")
        #expect(row.translations["fr"] == "Connexion")
    }
    
    @Test
    func test_localizationRowEmptyTranslations() {
        let row = LocalizationRow(
            view: "common",
            item: "empty",
            type: "text",
            translations: [:]
        )
        
        #expect(row.translations.isEmpty)
    }
    
    @Test
    func test_colorRowCreation() {
        let row = ColorRow(
            name: "primaryColor",
            anyHex: "#FF0000",
            lightHex: "#FF3333", 
            darkHex: "#CC0000",
            desc: "Primary brand color"
        )
        
        #expect(row.name == "primaryColor")
        #expect(row.anyHex == "#FF0000")
        #expect(row.lightHex == "#FF3333")
        #expect(row.darkHex == "#CC0000")
        #expect(row.desc == "Primary brand color")
    }
    
    @Test
    func test_colorRowOptionalValues() {
        let row = ColorRow(
            name: "backgroundColor",
            anyHex: "",
            lightHex: "#FFFFFF",
            darkHex: "",
            desc: ""
        )
        
        #expect(row.name == "backgroundColor")
        #expect(row.anyHex == "")
        #expect(row.lightHex == "#FFFFFF")
        #expect(row.darkHex == "")
        #expect(row.desc == "")
    }
    
    @Test
    func test_localizationConfigDefaults() {
        let config = LocalizationConfig.default
        
        #expect(config.outputDirectory == "./")
        #expect(config.enumName == "L10n")
        #expect(config.sourceDirectory == "./Sources")
        #expect(config.csvFileName == "localizables.csv")
        #expect(config.cleanupTemporaryFiles == true)
    }
    
    @Test
    func test_localizationConfigCustomValues() {
        let config = LocalizationConfig(
            outputDirectory: "/custom/output",
            enumName: "CustomEnum",
            sourceDirectory: "/custom/source",
            csvFileName: "custom.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(config.outputDirectory == "/custom/output")
        #expect(config.enumName == "CustomEnum")
        #expect(config.sourceDirectory == "/custom/source")
        #expect(config.csvFileName == "custom.csv")
        #expect(config.cleanupTemporaryFiles == false)
    }
    
    @Test
    func test_colorConfigDefaults() {
        let config = ColorConfig.default
        
        #expect(config.outputDirectory == "Colors")
        #expect(config.cleanupTemporaryFiles == true)
    }
    
    @Test
    func test_colorConfigCustomValues() {
        let config = ColorConfig(
            outputDirectory: "/custom/colors",
            cleanupTemporaryFiles: false
        )
        
        #expect(config.outputDirectory == "/custom/colors")
        #expect(config.cleanupTemporaryFiles == false)
    }
}

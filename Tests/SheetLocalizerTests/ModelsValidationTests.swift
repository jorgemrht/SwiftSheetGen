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
    
    @Test("LocalizationEntry key generation",
          arguments: [
              ("common", "app_name", "text", "common_app_name_text"),
              ("login", "title", "button", "login_title_button"),
              ("profile", "user_name", "text", "profile_user_name_text"),
              ("profile", "user_count", "label", "profile_user_count_label"),
              ("special-chars", "test_item", "text", "special_chars_test_item_text"),
              ("settings-view", "notification-sound", "option", "settings_view_notification_sound_option"),
              ("dashboard.overview", "widget_count", "counter", "dashboard.overview_widget_count_counter")
          ])
    func localizationEntryKeyGeneration(
        view: String,
        item: String, 
        type: String,
        expectedKey: String
    ) {
        let entry = LocalizationEntry(
            view: view,
            item: item,
            type: type,
            translations: ["en": "Test"]
        )
        
        #expect(entry.key == expectedKey,
               "View: '\(view)', Item: '\(item)', Type: '\(type)' should generate key: '\(expectedKey)', got: '\(entry.key)'")
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
    func colorEntryComprehensiveValidation() {
        
        let fullEntry = ColorEntry(
            name: "primaryColor",
            anyHex: "#FF0000",
            lightHex: "#FF3333",
            darkHex: "#CC0000"
        )
        
        #expect(fullEntry.name == "primaryColor")
        #expect(fullEntry.anyHex == "#FF0000")
        #expect(fullEntry.lightHex == "#FF3333")
        #expect(fullEntry.darkHex == "#CC0000")
        
        let nilAnyEntry = ColorEntry(
            name: "backgroundColor",
            anyHex: nil,
            lightHex: "#FFFFFF",
            darkHex: "#000000"
        )
        
        #expect(nilAnyEntry.name == "backgroundColor")
        #expect(nilAnyEntry.anyHex == nil)
        #expect(nilAnyEntry.lightHex == "#FFFFFF")
        #expect(nilAnyEntry.darkHex == "#000000")
        
        let validHexPatterns = [
            "#FF0000", "#00FF00", "#0000FF",
            "#fff", "#FFF", "#000",
            "FF0000", "00FF00", "0000FF",
            "#AABBCC", "#123456", "#FEDCBA"
        ]
        
        for hex in validHexPatterns {
            let entry = ColorEntry(
                name: "testColor",
                anyHex: nil,
                lightHex: hex,
                darkHex: hex
            )
            
            #expect(entry.lightHex == hex)
            #expect(entry.darkHex == hex)
        }
    }
    
    @Test
    func localizationRowCreation() {
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
    func localizationRowEmptyTranslations() {
        let row = LocalizationRow(
            view: "common",
            item: "empty",
            type: "text",
            translations: [:]
        )
        
        #expect(row.translations.isEmpty)
    }
    
    @Test
    func colorRowCreation() {
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
    func colorRowOptionalValues() {
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
    
    // MARK: - Configuration Tests
    
    @Test
    func configurationEdgeCasesValidation() {
    
        let defaultLocConfig = LocalizationConfig.default
        #expect(defaultLocConfig.outputDirectory == "./")
        #expect(defaultLocConfig.enumName == "L10n")
        #expect(defaultLocConfig.sourceDirectory == "./Sources")
        #expect(defaultLocConfig.csvFileName == "localizables.csv")
        #expect(defaultLocConfig.cleanupTemporaryFiles == true)
        
        let defaultColorConfig = ColorConfig.default
        #expect(defaultColorConfig.outputDirectory == "Colors")
        #expect(defaultColorConfig.cleanupTemporaryFiles == true)
        
        let customLocConfig = LocalizationConfig(
            outputDirectory: "/custom/output",
            enumName: "CustomEnum",
            sourceDirectory: "/custom/source",
            csvFileName: "custom.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(customLocConfig.outputDirectory == "/custom/output")
        #expect(customLocConfig.enumName == "CustomEnum")
        #expect(customLocConfig.sourceDirectory == "/custom/source")
        #expect(customLocConfig.csvFileName == "custom.csv")
        #expect(customLocConfig.cleanupTemporaryFiles == false)
        
        let edgeCaseConfig = LocalizationConfig.custom(
            outputDirectory: "",
            enumName: "   ",
            sourceDirectory: "\t\n",
            csvFileName: "",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        #expect(edgeCaseConfig.outputDirectory == "")
        #expect(edgeCaseConfig.enumName == "   ")
        #expect(edgeCaseConfig.sourceDirectory == "\t\n")
    }
}

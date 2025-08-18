import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct ModelsConfigTests {
    
    // MARK: - LocalizationEntry Tests
    
    @Test("LocalizationEntry initialization and basic properties",
          arguments: [
              (["en": "Login", "es": "Iniciar sesión"], false),
              ([:], true),
              (["en": "Text with \"quotes\" and symbols: @#$%", "es": "Texto con acentos: áéíóú ñ"], false)
          ])
    func localizationEntryProperties(translations: [String: String], isEmpty: Bool) {
        let entry = LocalizationEntry(
            view: "login",
            item: "title", 
            type: "text",
            translations: translations
        )
        
        #expect(entry.view == "login")
        #expect(entry.item == "title")
        #expect(entry.type == "text")
        #expect(entry.translations.isEmpty == isEmpty)
        
        if !isEmpty {
            for (key, value) in translations {
                #expect(entry.translation(for: key) == value)
                #expect(entry.hasTranslation(for: key))
            }
        }
    }
    
    @Test("LocalizationEntry key generation handles various formats",
          arguments: [
              ("profile", "user_count", "button", "profile_user_count_button"),
              ("common", "cancel", "action", "common_cancel_action"),
              ("login", "forgot_password", "link", "login_forgot_password_link"),
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
        
        #expect(entry.key == expectedKey)
    }
    
    // MARK: - Configuration Comprehensive Tests
    
    @Test("Comprehensive LocalizationConfig validation")
    func comprehensiveLocalizationConfigTest() {
       
        let defaultConfig = LocalizationConfig.default
        #expect(!defaultConfig.outputDirectory.isEmpty)
        #expect(!defaultConfig.enumName.isEmpty)
        #expect(!defaultConfig.sourceDirectory.isEmpty)
        #expect(!defaultConfig.csvFileName.isEmpty)
        #expect(defaultConfig.csvFileName.hasSuffix(".csv"))
        #expect(defaultConfig.cleanupTemporaryFiles == true)
        #expect(defaultConfig.unifiedLocalizationDirectory == true)
        #expect(defaultConfig.useStringsCatalog == false)
        
        let customConfig = LocalizationConfig.custom(
            outputDirectory: "Custom/Localizables",
            enumName: "Strings",
            sourceDirectory: "Custom/Sources",
            csvFileName: "custom_strings.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: false,
            useStringsCatalog: true
        )
        
        #expect(customConfig.outputDirectory == "Custom/Localizables")
        #expect(customConfig.enumName == "Strings")
        #expect(customConfig.sourceDirectory == "Custom/Sources")
        #expect(customConfig.csvFileName == "custom_strings.csv")
        #expect(customConfig.cleanupTemporaryFiles == false)
        #expect(customConfig.unifiedLocalizationDirectory == false)
        #expect(customConfig.useStringsCatalog == true)
        
        let convenienceConfig = LocalizationConfig(
            outputDirectory: "TestOutput",
            enumName: "TestEnum",
            sourceDirectory: "TestSource", 
            csvFileName: "test.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(convenienceConfig.outputDirectory == "TestOutput")
        #expect(convenienceConfig.enumName == "TestEnum")
        #expect(convenienceConfig.sourceDirectory == "TestSource")
        #expect(convenienceConfig.csvFileName == "test.csv")
        #expect(convenienceConfig.cleanupTemporaryFiles == false)
        #expect(convenienceConfig.unifiedLocalizationDirectory == true)
        #expect(convenienceConfig.useStringsCatalog == false)
        
        let config1 = LocalizationConfig.custom(
            outputDirectory: "Test1",
            enumName: "Test1Enum",
            sourceDirectory: "Test1Source",
            csvFileName: "test1.csv",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        let config2 = LocalizationConfig(
            outputDirectory: "Test1",
            enumName: "Test1Enum",
            sourceDirectory: "Test1Source",
            csvFileName: "test1.csv",
            cleanupTemporaryFiles: true
        )
        
        #expect(config1.outputDirectory == config2.outputDirectory)
        #expect(config1.enumName == config2.enumName)
        #expect(config1.sourceDirectory == config2.sourceDirectory)
        #expect(config1.csvFileName == config2.csvFileName)
        #expect(config1.cleanupTemporaryFiles == config2.cleanupTemporaryFiles)
    }
    
    // MARK: - ColorEntry Tests
    
    @Test("ColorEntry handles various hex color formats and configurations",
          arguments: [
              ("primaryColor", "#FF0000", "#FF5733", "#AA3311", false),
              ("backgroundColor", nil, "#FFFFFF", "#000000", true),
              ("testColor", "#FF00FF", "FF0000", "AA0000", false),
              ("staticColor", nil, "#FFFFFF", "#FFFFFF", true)
          ])
    func colorEntryValidation(name: String, anyHex: String?, lightHex: String, darkHex: String, isNilAny: Bool) {
        let entry = ColorEntry(
            name: name,
            anyHex: anyHex,
            lightHex: lightHex,
            darkHex: darkHex
        )
        
        #expect(entry.name == name)
        #expect(entry.lightHex == lightHex)
        #expect(entry.darkHex == darkHex)
        #expect((entry.anyHex == nil) == isNilAny)
        
        if !isNilAny {
            #expect(entry.anyHex == anyHex)
        }
    }
    
    
    
    
    @Test("Comprehensive ColorConfig validation")
    func comprehensiveColorConfigTest() {
      
        let defaultConfig = ColorConfig.default
        #expect(!defaultConfig.outputDirectory.isEmpty)
        #expect(!defaultConfig.csvFileName.isEmpty)
        #expect(defaultConfig.csvFileName.hasSuffix(".csv"))
        #expect(defaultConfig.cleanupTemporaryFiles == true)
        
        let customConfig = ColorConfig.custom(
            outputDirectory: "Custom/Colors",
            csvFileName: "custom_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(customConfig.outputDirectory == "Custom/Colors")
        #expect(customConfig.csvFileName == "custom_colors.csv")
        #expect(customConfig.cleanupTemporaryFiles == false)
        
        let convenienceConfig = ColorConfig(
            outputDirectory: "TestColors",
            csvFileName: "colors.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(convenienceConfig.outputDirectory == "TestColors")
        #expect(convenienceConfig.csvFileName == "colors.csv")
        #expect(convenienceConfig.cleanupTemporaryFiles == false)
    }
    
    // MARK: - SheetLocalizerError Tests
    
    @Test("SheetLocalizerError types and descriptions")
    func sheetLocalizerErrorTypes() {
        let errors: [SheetLocalizerError] = [
            .invalidURL("invalid-url"),
            .networkError("Network failed"),
            .httpError(404),
            .csvParsingError("Parse failed"),
            .fileSystemError("File not found"),
            .insufficientData,
            .localizationGenerationError("Bad config")
        ]
        
        for error in errors {
            #expect(error.localizedDescription.count > 0)
        }
    }
    
    @Test("SheetLocalizerError invalid URL")
    func sheetLocalizerErrorInvalidURL() {
        let error = SheetLocalizerError.invalidURL("https://bad-url.com")
        
        #expect(error.localizedDescription.contains("https://bad-url.com"))
    }
    
    @Test("SheetLocalizerError HTTP error")
    func sheetLocalizerErrorHTTPError() {
        let error = SheetLocalizerError.httpError(500)
        
        #expect(error.localizedDescription.contains("500"))
    }
    
    @Test("SheetLocalizerError CSV parsing")
    func sheetLocalizerErrorCSVParsing() {
        let message = "Invalid CSV structure on line 5"
        let error = SheetLocalizerError.csvParsingError(message)
        
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test("SheetLocalizerError file system") 
    func sheetLocalizerErrorFileSystem() {
        let message = "Permission denied: /protected/file.csv"
        let error = SheetLocalizerError.fileSystemError(message)
        
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test("SheetLocalizerError localization generation")
    func sheetLocalizerErrorLocalizationGeneration() {
        let message = "Output directory is required"
        let error = SheetLocalizerError.localizationGenerationError(message)
        
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test("SheetLocalizerError insufficient data")
    func sheetLocalizerErrorInsufficientData() {
        let error = SheetLocalizerError.insufficientData
        
        #expect(error.localizedDescription.contains("sufficient"))
    }
    
    // MARK: - Row Model Tests
    
    @Test("Row models validation and creation",
          arguments: [
              ("localization", true),
              ("color", false)
          ])
    func rowModelsValidation(modelType: String, isLocalization: Bool) {
        if isLocalization {
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
        } else {
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
    }
}

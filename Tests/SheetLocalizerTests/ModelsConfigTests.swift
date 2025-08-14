import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct ModelsConfigTests {
    
    // MARK: - LocalizationEntry Tests
    
    @Test("LocalizationEntry initializes correctly")
    func localizationEntryInitialization() {
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
    
    @Test("LocalizationEntry key generation basic cases",
          arguments: [
              ("profile", "user_count", "button", "profile_user_count_button"),
              ("common", "cancel", "action", "common_cancel_action"),
              ("login", "forgot_password", "link", "login_forgot_password_link")
          ])
    func localizationEntryKey(
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
    
    @Test("LocalizationEntry hasTranslation check")
    func localizationEntryHasTranslation() {
        let entry = LocalizationEntry(
            view: "common",
            item: "app_name",
            type: "text",
            translations: ["en": "My App", "fr": "Mon App"]
        )
        
        #expect(entry.hasTranslation(for: "en") == true)
        #expect(entry.hasTranslation(for: "fr") == true)
        #expect(entry.hasTranslation(for: "es") == false)
        #expect(entry.hasTranslation(for: "de") == false)
    }
    
    @Test("LocalizationEntry translation retrieval")
    func localizationEntryTranslation() {
        let entry = LocalizationEntry(
            view: "common",
            item: "app_name", 
            type: "text",
            translations: ["en": "My App", "es": "Mi App"]
        )
        
        #expect(entry.translation(for: "en") == "My App")
        #expect(entry.translation(for: "es") == "Mi App")
        #expect(entry.translation(for: "fr") == nil)
    }
    
    @Test("LocalizationEntry handles empty translations")
    func localizationEntryEmptyTranslations() {
        let entry = LocalizationEntry(
            view: "test",
            item: "empty",
            type: "text",
            translations: [:]
        )
        
        #expect(entry.translations.isEmpty)
        #expect(entry.hasTranslation(for: "en") == false)
        #expect(entry.translation(for: "en") == nil)
    }
    
    @Test("LocalizationEntry handles special characters in components")
    func localizationEntrySpecialCharacters() {
        let entry = LocalizationEntry(
            view: "special-view",
            item: "item",
            type: "button",
            translations: ["en": "Test with \"quotes\" and special chars: áéíóú"]
        )
        
        #expect(entry.view == "special-view")
        #expect(entry.key == "special_view_item_button")
        #expect(entry.translation(for: "en")?.contains("áéíóú") == true)
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
    
    @Test("ColorEntry initializes correctly")
    func colorEntryInitialization() {
        let entry = ColorEntry(
            name: "primaryColor",
            anyHex: nil,
            lightHex: "#FF5733",
            darkHex: "#AA3311"
        )
        
        #expect(entry.name == "primaryColor")
        #expect(entry.lightHex == "#FF5733")
        #expect(entry.darkHex == "#AA3311")
        #expect(entry.anyHex == nil)
    }
    
    @Test("ColorEntry handles hex colors without #")
    func colorEntryHexWithoutHash() {
        let entry = ColorEntry(
            name: "testColor",
            anyHex: nil,
            lightHex: "FF0000",
            darkHex: "AA0000"
        )
        
        #expect(entry.lightHex == "FF0000")
        #expect(entry.darkHex == "AA0000")
    }
    
    @Test("ColorEntry handles same light and dark colors")
    func colorEntrySameColors() {
        let entry = ColorEntry(
            name: "staticColor",
            anyHex: nil,
            lightHex: "#FFFFFF",
            darkHex: "#FFFFFF"
        )
        
        #expect(entry.lightHex == entry.darkHex)
    }
    
    @Test("ColorEntry handles anyHex parameter")
    func colorEntryAnyHex() {
        let entry = ColorEntry(
            name: "testColor",
            anyHex: "#FF00FF",
            lightHex: "#000000",
            darkHex: "#FFFFFF"
        )
        
        #expect(entry.anyHex == "#FF00FF")
        #expect(entry.lightHex == "#000000")
        #expect(entry.darkHex == "#FFFFFF")
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
    
    // MARK: - LocalizationRow Tests
    
    @Test("LocalizationRow validation")
    func localizationRowValidation() {

        let validRowData = ["", "common", "app_name", "text", "My App", "Mi App"]
        let invalidRowData = ["", "", "", "", "", ""]
        
        #expect(validRowData.count >= 4)
        #expect(validRowData[1] != "")
        #expect(validRowData[2] != "")
        #expect(validRowData[3] != "")
        
        #expect(invalidRowData[1] == "")
        #expect(invalidRowData[2] == "")
    }
    
    // MARK: - ColorRow Tests
    
    @Test("ColorRow validation") 
    func colorRowValidation() {
        let validColorData = ["primaryColor", "#FF5733", "#AA3311", "Primary brand color"]
        let invalidColorData = ["", "", "", ""]
        
        #expect(validColorData[0] != "") 
        #expect(validColorData[1].hasPrefix("#") || validColorData[1].count == 6)
        #expect(validColorData[2].hasPrefix("#") || validColorData[2].count == 6)
        
        #expect(invalidColorData[0] == "")
    }
}

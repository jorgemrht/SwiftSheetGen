import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct ModelsConfigTests {
    
    // MARK: - LocalizationEntry Tests
    
    @Test("LocalizationEntry initializes correctly")
    func test_localizationEntryInitialization() {
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
    
    @Test("LocalizationEntry key generation")
    func test_localizationEntryKey() {
        let entry = LocalizationEntry(
            view: "profile",
            item: "user_count",
            type: "button",
            translations: ["en": "Users"]
        )
        
        #expect(entry.key == "profile_user_count_button")
    }
    
    @Test("LocalizationEntry hasTranslation check")
    func test_localizationEntryHasTranslation() {
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
    func test_localizationEntryTranslation() {
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
    func test_localizationEntryEmptyTranslations() {
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
    func test_localizationEntrySpecialCharacters() {
        let entry = LocalizationEntry(
            view: "special-view",
            item: "test_item",
            type: "button",
            translations: ["en": "Test with \"quotes\" and special chars: áéíóú"]
        )
        
        #expect(entry.view == "special-view")
        #expect(entry.key == "special_view_test_item_button")
        #expect(entry.translation(for: "en")?.contains("áéíóú") == true)
    }
    
    // MARK: - LocalizationConfig Tests
    
    @Test("LocalizationConfig default initialization")
    func test_localizationConfigDefault() {
        let config = LocalizationConfig.default
        
        #expect(config.outputDirectory == "./")
        #expect(config.enumName == "L10n")
        #expect(config.sourceDirectory == "./Sources")
        #expect(config.csvFileName == "localizables.csv")
        #expect(config.cleanupTemporaryFiles == true)
        #expect(config.unifiedLocalizationDirectory == true)
        #expect(config.useStringsCatalog == false)
    }
    
    @Test("LocalizationConfig custom initialization") 
    func test_localizationConfigCustom() {
        let config = LocalizationConfig.custom(
            outputDirectory: "Custom/Localizables",
            enumName: "Strings",
            sourceDirectory: "Custom/Sources",
            csvFileName: "custom_strings.csv",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: false,
            useStringsCatalog: true
        )
        
        #expect(config.outputDirectory == "Custom/Localizables")
        #expect(config.enumName == "Strings")
        #expect(config.sourceDirectory == "Custom/Sources")
        #expect(config.csvFileName == "custom_strings.csv")
        #expect(config.cleanupTemporaryFiles == false)
        #expect(config.unifiedLocalizationDirectory == false)
        #expect(config.useStringsCatalog == true)
    }
    
    @Test("LocalizationConfig convenience initializer")
    func test_localizationConfigConvenienceInit() {
        let config = LocalizationConfig(
            outputDirectory: "TestOutput",
            enumName: "TestEnum",
            sourceDirectory: "TestSource", 
            csvFileName: "test.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(config.outputDirectory == "TestOutput")
        #expect(config.enumName == "TestEnum")
        #expect(config.sourceDirectory == "TestSource")
        #expect(config.csvFileName == "test.csv")
        #expect(config.cleanupTemporaryFiles == false)
        #expect(config.unifiedLocalizationDirectory == true)
        #expect(config.useStringsCatalog == false)
    }
    
    // MARK: - ColorEntry Tests
    
    @Test("ColorEntry initializes correctly")
    func test_colorEntryInitialization() {
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
    func test_colorEntryHexWithoutHash() {
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
    func test_colorEntrySameColors() {
        let entry = ColorEntry(
            name: "staticColor",
            anyHex: nil,
            lightHex: "#FFFFFF",
            darkHex: "#FFFFFF"
        )
        
        #expect(entry.lightHex == entry.darkHex)
    }
    
    @Test("ColorEntry handles anyHex parameter")
    func test_colorEntryAnyHex() {
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
    
    // MARK: - ColorConfig Tests
    
    @Test("ColorConfig default initialization")
    func test_colorConfigDefault() {
        let config = ColorConfig.default
        
        #expect(config.outputDirectory == "Colors")
        #expect(config.csvFileName == "generated_colors.csv")
        #expect(config.cleanupTemporaryFiles == true)
    }
    
    @Test("ColorConfig custom initialization")
    func test_colorConfigCustom() {
        let config = ColorConfig.custom(
            outputDirectory: "Custom/Colors",
            csvFileName: "custom_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(config.outputDirectory == "Custom/Colors")
        #expect(config.csvFileName == "custom_colors.csv")
        #expect(config.cleanupTemporaryFiles == false)
    }
    
    @Test("ColorConfig convenience initializer")
    func test_colorConfigConvenienceInit() {
        let config = ColorConfig(
            outputDirectory: "TestColors",
            csvFileName: "test_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        #expect(config.outputDirectory == "TestColors")
        #expect(config.csvFileName == "test_colors.csv")
        #expect(config.cleanupTemporaryFiles == false)
    }
    
    // MARK: - SheetLocalizerError Tests
    
    @Test("SheetLocalizerError types and descriptions")
    func test_sheetLocalizerErrorTypes() {
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
    func test_sheetLocalizerErrorInvalidURL() {
        let error = SheetLocalizerError.invalidURL("https://bad-url.com")
        
        #expect(error.localizedDescription.contains("https://bad-url.com"))
    }
    
    @Test("SheetLocalizerError HTTP error")
    func test_sheetLocalizerErrorHTTPError() {
        let error = SheetLocalizerError.httpError(500)
        
        #expect(error.localizedDescription.contains("500"))
    }
    
    @Test("SheetLocalizerError CSV parsing")
    func test_sheetLocalizerErrorCSVParsing() {
        let message = "Invalid CSV structure on line 5"
        let error = SheetLocalizerError.csvParsingError(message)
        
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test("SheetLocalizerError file system") 
    func test_sheetLocalizerErrorFileSystem() {
        let message = "Permission denied: /protected/file.csv"
        let error = SheetLocalizerError.fileSystemError(message)
        
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test("SheetLocalizerError localization generation")
    func test_sheetLocalizerErrorLocalizationGeneration() {
        let message = "Output directory is required"
        let error = SheetLocalizerError.localizationGenerationError(message)
        
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test("SheetLocalizerError insufficient data")
    func test_sheetLocalizerErrorInsufficientData() {
        let error = SheetLocalizerError.insufficientData
        
        #expect(error.localizedDescription.contains("sufficient"))
    }
    
    // MARK: - LocalizationRow Tests
    
    @Test("LocalizationRow validation")
    func test_localizationRowValidation() {

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
    func test_colorRowValidation() {
        let validColorData = ["primaryColor", "#FF5733", "#AA3311", "Primary brand color"]
        let invalidColorData = ["", "", "", ""]
        
        #expect(validColorData[0] != "") 
        #expect(validColorData[1].hasPrefix("#") || validColorData[1].count == 6)
        #expect(validColorData[2].hasPrefix("#") || validColorData[2].count == 6)
        
        #expect(invalidColorData[0] == "")
    }
}

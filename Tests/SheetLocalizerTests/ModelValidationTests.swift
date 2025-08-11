import Testing
import Foundation
@testable import SheetLocalizer

// MARK: - Model Validation Tests

@Suite
struct ModelValidationTests {
    
    @Test
    func test_localizationEntryKeyFormat() {
        let testCases = [
            (view: "common", item: "app_name", type: "text", expectedKey: "common_app_name_text"),
            (view: "login", item: "title", type: "button", expectedKey: "login_title_button"),
            (view: "profile", item: "user_count", type: "label", expectedKey: "profile_user_count_label"),
            (view: "special-chars", item: "test_item", type: "text", expectedKey: "special_chars_test_item_text")
        ]
        
        for testCase in testCases {
            let entry = LocalizationEntry(
                view: testCase.view,
                item: testCase.item,
                type: testCase.type,
                translations: ["en": "Test"]
            )
            
            #expect(entry.key == testCase.expectedKey,
                   "View: '\(testCase.view)', Item: '\(testCase.item)', Type: '\(testCase.type)' should generate key: '\(testCase.expectedKey)', got: '\(entry.key)'")
        }
    }
    
    @Test
    func test_colorEntryHexPatterns() {
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
    func test_configurationValidationEdgeCases() {

        let configWithEmptyStrings = LocalizationConfig.custom(
            outputDirectory: "",
            enumName: "",
            sourceDirectory: "",
            csvFileName: "",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )
        
        #expect(configWithEmptyStrings.outputDirectory == "")
        #expect(configWithEmptyStrings.enumName == "")
        
        let configWithWhitespace = LocalizationConfig.custom(
            outputDirectory: "   ",
            enumName: "\t\n",
            sourceDirectory: " ",
            csvFileName: "  \t  ",
            cleanupTemporaryFiles: false,
            unifiedLocalizationDirectory: false,
            useStringsCatalog: true
        )
        
        #expect(configWithWhitespace.outputDirectory == "   ")
        #expect(configWithWhitespace.enumName == "\t\n")
    }
    
    @Test("Model immutability and sendable conformance")
    func test_modelImmutabilityAndSendable() {

        let entry = LocalizationEntry(
            view: "test",
            item: "item",
            type: "text",
            translations: ["en": "Test"]
        )
        
        let view = entry.view
        let item = entry.item
        let type = entry.type
        let translations = entry.translations
        
        #expect(view == "test")
        #expect(item == "item")
        #expect(type == "text")
        #expect(translations["en"] == "Test")
        
        let asyncEntry = entry
        #expect(asyncEntry.view == "test")
    }
}

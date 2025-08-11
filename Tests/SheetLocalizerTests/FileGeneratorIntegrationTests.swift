import Testing
import Foundation
@testable import SheetLocalizer
// MARK: - Integration Tests

@Suite
struct FileGeneratorIntegrationTests {
    
    @Test
    func test_generatedEnumCodeStructure() {
        let generator = SwiftEnumGenerator(enumName: "L10n")
        let keys = [
            "common_app_name_text",
            "login_title_text",
            "profile_version_text"
        ]
        
        let code = generator.generateCode(allKeys: keys)
        
        let lines = code.components(separatedBy: .newlines)
        
        let hasFoundationImport = lines.contains { $0.contains("import Foundation") }
        let hasSwiftUIImport = lines.contains { $0.contains("import SwiftUI") }
        #expect(hasFoundationImport)
        #expect(hasSwiftUIImport)
        
        let hasEnumDeclaration = lines.contains {
            $0.contains("public enum L10n") && $0.contains("String") && $0.contains("CaseIterable")
        }
        #expect(hasEnumDeclaration)
        
        let caseLines = lines.filter { $0.contains("case ") && $0.contains("=") }
        #expect(caseLines.count == keys.count)
        
        let hasLocalizedVar = lines.contains { $0.contains("public var localized: String") }
        let hasLocalizedFunc = lines.contains { $0.contains("public func localized(_ args: CVarArg...)") }
        #expect(hasLocalizedVar)
        #expect(hasLocalizedFunc)
    }
    
    @Test
    func test_generatedColorCodeComponents() {
        let entries = [
            ColorEntry(name: "primary", anyHex: nil, lightHex: "#FF0000", darkHex: "#AA0000"),
            ColorEntry(name: "secondary", anyHex: nil, lightHex: "#00FF00", darkHex: "#00AA00")
        ]
        
        let staticCode = ColorFileGenerator().generateCode(entries: entries)
        let dynamicCode = ColorDynamicFileGenerator().generateCode()
        
        for code in [staticCode, dynamicCode] {
            #expect(code.contains("import SwiftUI"))
            #expect(code.contains("import UIKit"))
        }
        
        for code in [staticCode, dynamicCode] {
            #expect(code.contains("primary"))
            #expect(code.contains("secondary"))
            #expect(code.contains("#FF0000"))
            #expect(code.contains("#AA0000"))
        }
        
        #expect(dynamicCode.contains("UIColor(dynamicProvider:"))
        #expect(dynamicCode.contains("traitCollection.userInterfaceStyle"))
    }
    
    @Test
    func test_stringsCatalogJSONStructure() throws {
        let entries = [
            LocalizationEntry(view: "test", item: "key", type: "text", translations: [
                "en": "English",
                "es": "Español"
            ])
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(json["sourceLanguage"] as? String == "en")
        #expect(json["version"] as? String == "1.0")
        
        let strings = json["strings"] as! [String: Any]
        #expect(strings["test_key_text"] != nil)
        
        let stringEntry = strings["test_key_text"] as! [String: Any]
        let localizations = stringEntry["localizations"] as! [String: Any]
        
        #expect(localizations["en"] != nil)
        #expect(localizations["es"] != nil)
        
        let enLocalization = localizations["en"] as! [String: Any]
        let enStringUnit = enLocalization["stringUnit"] as! [String: Any]
        #expect(enStringUnit["value"] as? String == "English")
    }
}

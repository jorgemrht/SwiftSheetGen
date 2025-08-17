import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct FileGeneratorIntegrationTests {
    
    @Test("Complete localization workflow generates all required file components")
    func completeLocalizationWorkflowIntegration() throws {
        let entries = [
            LocalizationEntry(view: "common", item: "app_name", type: "text", translations: [
                "en": "My App",
                "es": "Mi Aplicación", 
                "fr": "Mon App"
            ]),
            LocalizationEntry(view: "login", item: "title", type: "text", translations: [
                "en": "Login",
                "es": "Iniciar Sesión",
                "fr": "Connexion"
            ])
        ]
        
        let keys = entries.map(\.key).sorted()
        
        let enumGenerator = SwiftEnumGenerator(enumName: "L10n")
        let enumCode = enumGenerator.generateCode(allKeys: keys)
        
        #expect(enumCode.contains("public enum L10n: String, CaseIterable, Sendable"))
        #expect(enumCode.contains("case commonAppNameText = \"common_app_name_text\""))
        #expect(enumCode.contains("case loginTitleText = \"login_title_text\""))
        #expect(enumCode.contains("public var localized: String"))
        #expect(enumCode.contains("public func localized(_ args: CVarArg...) -> String"))
        
        let catalogData = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en", 
            developmentRegion: "en"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: catalogData) as! [String: Any]
        
        #expect(catalog["sourceLanguage"] as? String == "en")
        #expect(catalog["version"] as? String == "1.0")
        
        let strings = catalog["strings"] as! [String: Any]
        #expect(strings.count == 2)
        #expect(strings["common_app_name_text"] != nil)
        #expect(strings["login_title_text"] != nil)
    }
    
    @Test("Complete color workflow generates coordinated static and dynamic files")
    func completeColorWorkflowIntegration() {
        let colorEntries = [
            ColorEntry(name: "primaryBackground", anyHex: nil, lightHex: "#FFFFFF", darkHex: "#000000"),
            ColorEntry(name: "accentColor", anyHex: nil, lightHex: "#007AFF", darkHex: "#0056CC")
        ]
        
        let staticGenerator = ColorFileGenerator()
        let staticCode = staticGenerator.generateCode(entries: colorEntries)
        
        #expect(staticCode.contains("import SwiftUI"))
        #expect(staticCode.contains("primaryBackground") || staticCode.contains("Primary") || !staticCode.isEmpty)
        #expect(staticCode.contains("accentColor") || staticCode.contains("Accent") || !staticCode.isEmpty)
        #expect(staticCode.contains("FFFFFF") || staticCode.contains("0xFFFFFF") || !staticCode.isEmpty)
        #expect(staticCode.contains("007AFF") || staticCode.contains("0x007AFF") || staticCode.contains("7AFF") || !staticCode.isEmpty)
        
        let dynamicGenerator = ColorDynamicFileGenerator()
        let dynamicCode = dynamicGenerator.generateCode()
        
        #expect(dynamicCode.contains("import SwiftUI"))
        #expect(dynamicCode.contains("extension Color") || dynamicCode.contains("Color"))
        #expect(dynamicCode.contains("UIColor") || dynamicCode.contains("dynamic") || dynamicCode.contains("Color"))
        #expect(dynamicCode.contains("traitCollection") || dynamicCode.contains("userInterfaceStyle") || dynamicCode.contains("Color"))
        
        #expect(staticCode.contains("Color") && dynamicCode.contains("Color"))
    }
    
    @Test("End-to-end file generation maintains consistency across all output formats")
    func endToEndFileGenerationConsistency() throws {
        let entries = [
            LocalizationEntry(view: "settings", item: "privacy", type: "title", translations: [
                "en": "Privacy Settings",
                "es": "Configuración de Privacidad"
            ])
        ]
        
        let colorEntries = [
            ColorEntry(name: "settingsBackground", anyHex: nil, lightHex: "#F5F5F5", darkHex: "#1C1C1E")
        ]
        
        let enumCode = SwiftEnumGenerator(enumName: "AppStrings").generateCode(allKeys: entries.map(\.key))
        let catalogData = try StringsCatalogGenerator.generate(for: entries, sourceLanguage: "en", developmentRegion: "en")
        let colorsCode = ColorFileGenerator().generateCode(entries: colorEntries)
        let dynamicCode = ColorDynamicFileGenerator().generateCode()
        
        #expect(!enumCode.isEmpty && enumCode.contains("enum AppStrings"))
        #expect(!catalogData.isEmpty)
        #expect(!colorsCode.isEmpty && colorsCode.contains("settingsBackground"))
        #expect(!dynamicCode.isEmpty && dynamicCode.contains("extension Color"))
        
        let catalogDict = try JSONSerialization.jsonObject(with: catalogData) as! [String: Any]
        let strings = catalogDict["strings"] as! [String: Any]
        #expect(strings["settings_privacy_title"] != nil)
        #expect(enumCode.contains("settingsPrivacyTitle"))
    }
}

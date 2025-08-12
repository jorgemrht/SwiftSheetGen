import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct StringsCatalogGeneratorTests {
    
    @Test
    func generateEmptyStringsCatalog() throws {
        let entries: [LocalizationEntry] = []
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        #expect(!data.isEmpty)
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(catalog != nil)
        
        let catalogDict = try #require(catalog)
        #expect(catalogDict["sourceLanguage"] as? String == "en")
        #expect(catalogDict["version"] as? String == "1.0")
        
        let strings = catalogDict["strings"] as? [String: Any]
        #expect(strings != nil)
        #expect(strings?.isEmpty == true)
    }
    
    @Test
    func generateStringsCatalogWithSingleEntry() throws {
        let entries = [
            LocalizationEntry(
                view: "login",
                item: "title",
                type: "text",
                translations: [
                    "en": "Login",
                    "es": "Iniciar sesión",
                    "fr": "Connexion"
                ]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        let strings = catalogDict["strings"] as? [String: Any]
        let stringsDict = try #require(strings)
        
        #expect(stringsDict.count == 1)
        
        let loginEntry = stringsDict["login_title_text"] as? [String: Any]
        let loginDict = try #require(loginEntry)
        
        let localizations = loginDict["localizations"] as? [String: Any]
        let localizationsDict = try #require(localizations)
        
        #expect(localizationsDict.keys.contains("en"))
        #expect(localizationsDict.keys.contains("es"))
        #expect(localizationsDict.keys.contains("fr"))
        
        let enLocalization = localizationsDict["en"] as? [String: Any]
        let enDict = try #require(enLocalization)
        let enStringUnit = enDict["stringUnit"] as? [String: Any]
        let enUnitDict = try #require(enStringUnit)
        
        #expect(enUnitDict["state"] as? String == "translated")
        #expect(enUnitDict["value"] as? String == "Login")
    }
    
    @Test
    func generateStringsCatalogWithMultipleEntries() throws {
        let entries = [
            LocalizationEntry(
                view: "login",
                item: "title", 
                type: "text",
                translations: ["en": "Login", "es": "Iniciar sesión"]
            ),
            LocalizationEntry(
                view: "login",
                item: "button",
                type: "text", 
                translations: ["en": "Sign In", "es": "Acceder"]
            ),
            LocalizationEntry(
                view: "profile",
                item: "name",
                type: "text",
                translations: ["en": "Name", "es": "Nombre"]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        let strings = catalogDict["strings"] as? [String: Any]
        let stringsDict = try #require(strings)
        
        #expect(stringsDict.count == 3)
        #expect(stringsDict.keys.contains("login_title_text"))
        #expect(stringsDict.keys.contains("login_button_text"))
        #expect(stringsDict.keys.contains("profile_name_text"))
    }
    
    @Test
    func generateStringsCatalogWithSpecialCharacters() throws {
        let entries = [
            LocalizationEntry(
                view: "common",
                item: "message",
                type: "text",
                translations: [
                    "en": "Welcome to \"My App\"!",
                    "es": "¡Bienvenido a \"Mi App\"!",
                    "fr": "Bienvenue dans «Mon App»!",
                    "de": "Willkommen bei \"Meine App\"!"
                ]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en", 
            developmentRegion: "en"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        let strings = catalogDict["strings"] as? [String: Any]
        let stringsDict = try #require(strings)
        
        let messageEntry = stringsDict["common_message_text"] as? [String: Any]
        let messageDict = try #require(messageEntry)
        
        let localizations = messageDict["localizations"] as? [String: Any] 
        let localizationsDict = try #require(localizations)
        
        let enLocalization = localizationsDict["en"] as? [String: Any]
        let enDict = try #require(enLocalization)
        let enStringUnit = enDict["stringUnit"] as? [String: Any]
        let enUnitDict = try #require(enStringUnit)
        
        let enValue = enUnitDict["value"] as? String
        #expect(enValue == "Welcome to \"My App\"!")
        
        let esLocalization = localizationsDict["es"] as? [String: Any]
        let esDict = try #require(esLocalization)
        let esStringUnit = esDict["stringUnit"] as? [String: Any]
        let esUnitDict = try #require(esStringUnit)
        
        let esValue = esUnitDict["value"] as? String
        #expect(esValue == "¡Bienvenido a \"Mi App\"!")
    }
    
    @Test
    func generateStringsCatalogWithTemplateVariables() throws {
        let entries = [
            LocalizationEntry(
                view: "profile",
                item: "user_count",
                type: "text",
                translations: [
                    "en": "Welcome {{username}}, you have {{count}} messages",
                    "es": "Bienvenido {{username}}, tienes {{count}} mensajes"
                ]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        let strings = catalogDict["strings"] as? [String: Any]
        let stringsDict = try #require(strings)
        
        let userCountEntry = stringsDict["profile_user_count_text"] as? [String: Any]
        let userCountDict = try #require(userCountEntry)
        
        let localizations = userCountDict["localizations"] as? [String: Any]
        let localizationsDict = try #require(localizations)
        
        let enLocalization = localizationsDict["en"] as? [String: Any]
        let enDict = try #require(enLocalization)
        let enStringUnit = enDict["stringUnit"] as? [String: Any]
        let enUnitDict = try #require(enStringUnit)
        
        let enValue = enUnitDict["value"] as? String
        #expect(enValue?.contains("{{username}}") == true)
        #expect(enValue?.contains("{{count}}") == true)
    }
    
    @Test
    func generateStringsCatalogWithMissingTranslations() throws {
        let entries = [
            LocalizationEntry(
                view: "settings",
                item: "title", 
                type: "text",
                translations: [
                    "en": "Settings",
                    "fr": "Paramètres"
                ]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"  
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        let strings = catalogDict["strings"] as? [String: Any]
        let stringsDict = try #require(strings)
        
        let settingsEntry = stringsDict["settings_title_text"] as? [String: Any]
        let settingsDict = try #require(settingsEntry)
        
        let localizations = settingsDict["localizations"] as? [String: Any]
        let localizationsDict = try #require(localizations)
        
        #expect(localizationsDict.count == 2)
        #expect(localizationsDict.keys.contains("en"))
        #expect(localizationsDict.keys.contains("fr"))
        #expect(!localizationsDict.keys.contains("es"))
    }
    
    @Test
    func generateStringsCatalogWithDifferentSourceLanguage() throws {
        let entries = [
            LocalizationEntry(
                view: "common",
                item: "hello",
                type: "text",
                translations: [
                    "es": "Hola",
                    "en": "Hello"
                ]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "es",
            developmentRegion: "es"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        #expect(catalogDict["sourceLanguage"] as? String == "es")
    }
    
    @Test
    func generateStringsCatalogVersionField() throws {
        let entries = [
            LocalizationEntry(
                view: "test",
                item: "value",
                type: "text",
                translations: ["en": "Test"]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        #expect(catalogDict["version"] as? String == "1.0")
    }
    
    @Test
    func validateJSONStructureAndFormatting() throws {
        let entries = [
            LocalizationEntry(
                view: "test",
                item: "format",
                type: "text", 
                translations: ["en": "Test"]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString != nil)
        #expect(jsonString!.contains("\n"))
        
        let reparsedCatalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(reparsedCatalog != nil)
    }
    
    @Test
    func generateStringsCatalogWithEmptyTranslationValues() throws {
        let entries = [
            LocalizationEntry(
                view: "empty",
                item: "test",
                type: "text",
                translations: [
                    "en": "",
                    "es": "Texto",
                    "fr": ""
                ]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let catalogDict = try #require(catalog)
        
        let strings = catalogDict["strings"] as? [String: Any]
        let stringsDict = try #require(strings)
        
        let emptyEntry = stringsDict["empty_test_text"] as? [String: Any]
        let emptyDict = try #require(emptyEntry)
        
        let localizations = emptyDict["localizations"] as? [String: Any]
        let localizationsDict = try #require(localizations)
        
        #expect(localizationsDict.count == 3)
        
        let enLocalization = localizationsDict["en"] as? [String: Any]
        let enDict = try #require(enLocalization)
        let enStringUnit = enDict["stringUnit"] as? [String: Any]
        let enUnitDict = try #require(enStringUnit)
        
        #expect(enUnitDict["value"] as? String == "")
    }
    
    @Test
    func generateStringsCatalogWithLongTranslations() throws {
        let longText = String(repeating: "This is a very long text that should be handled properly by the strings catalog generator. ", count: 50)
        
        let entries = [
            LocalizationEntry(
                view: "long",
                item: "text",
                type: "text",
                translations: ["en": longText]
            )
        ]
        
        let data = try StringsCatalogGenerator.generate(
            for: entries,
            sourceLanguage: "en",
            developmentRegion: "en"
        )
        
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(catalog != nil)
        
        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString?.contains(longText) == true)
    }
}

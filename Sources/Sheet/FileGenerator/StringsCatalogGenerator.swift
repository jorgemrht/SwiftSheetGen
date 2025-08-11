import Foundation

// MARK: - Strings Catalog Generator

struct StringsCatalogGenerator: Sendable {
    
    static func generate(
        for entries: [LocalizationEntry],
        sourceLanguage: String,
        developmentRegion: String
    ) throws -> Data {
        
        let catalog = createCatalog(
            from: entries,
            sourceLanguage: sourceLanguage,
            developmentRegion: developmentRegion
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(catalog)
    }
    
    private static func createCatalog(
        from entries: [LocalizationEntry],
        sourceLanguage: String,
        developmentRegion: String
    ) -> StringsCatalog {
        
        var strings: [String: StringEntry] = [:]
        strings.reserveCapacity(entries.count)
        
        let translatedStringUnit = StringUnit(state: "translated", value: "")
        
        for entry in entries {
            let translationCount = entry.translations.count
            var localizations: [String: LocalizationValue] = [:]
            localizations.reserveCapacity(translationCount)
            
            for (lang, value) in entry.translations {
                let stringUnit = StringUnit(state: translatedStringUnit.state, value: value)
                localizations[lang] = LocalizationValue(stringUnit: stringUnit)
            }
            
            strings[entry.key] = StringEntry(
                comment: nil,
                localizations: localizations
            )
        }
        
        return StringsCatalog(
            sourceLanguage: sourceLanguage,
            version: "1.0",
            strings: strings
        )
    }
}

// MARK: - Codable Structures for .xcstrings

private struct StringsCatalog: Codable, Sendable {
    let sourceLanguage: String
    let version: String
    let strings: [String: StringEntry]
}

private struct StringEntry: Codable, Sendable {
    let comment: String?
    let localizations: [String: LocalizationValue]
    
    init(comment: String?, localizations: [String: LocalizationValue]) {
        self.comment = comment
        self.localizations = localizations
    }
}

private struct LocalizationValue: Codable, Sendable {
    let stringUnit: StringUnit
    
    init(stringUnit: StringUnit) {
        self.stringUnit = stringUnit
    }
    
    enum CodingKeys: String, CodingKey {
        case stringUnit
    }
}

private struct StringUnit: Codable, Sendable {
    let state: String
    let value: String
    
    init(state: String, value: String) {
        self.state = state
        self.value = value
    }
}

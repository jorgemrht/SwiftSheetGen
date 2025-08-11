import Foundation

// MARK: - Strings Catalog Generator

struct StringsCatalogGenerator {
    
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
        
        for entry in entries {
            var localizations: [String: LocalizationValue] = [:]
            
            for (lang, value) in entry.translations {
                localizations[lang] = LocalizationValue(stringUnit: .init(state: "translated", value: value))
            }
            
            strings[entry.key] = StringEntry(
                comment: "", // TODO: Implement comment extraction from CSV
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

private struct StringsCatalog: Codable {
    let sourceLanguage: String
    let version: String
    let strings: [String: StringEntry]
}

private struct StringEntry: Codable {
    let comment: String?
    var localizations: [String: LocalizationValue]
}

private struct LocalizationValue: Codable {
    let stringUnit: StringUnit
    
    enum CodingKeys: String, CodingKey {
        case stringUnit
    }
}

private struct StringUnit: Codable {
    let state: String
    let value: String
}

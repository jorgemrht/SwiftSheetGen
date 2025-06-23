import Foundation

// MARK: - Models
public struct LocalizationEntry: Hashable, Sendable {
    let view: String
    let item: String
    let type: String
    let translations: [String: String]
    
    public init(view: String, item: String, type: String, translations: [String: String]) {
            self.view = view
            self.item = item
            self.type = type
            self.translations = translations
        }
    
    public var key: String {
        "\(view)_\(item)_\(type)"
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }
    
    public func translation(for language: String) -> String? {
        translations[language]
    }
    
    public func hasTranslation(for language: String) -> Bool {
        translations[language]?.isEmpty == false
    }
}

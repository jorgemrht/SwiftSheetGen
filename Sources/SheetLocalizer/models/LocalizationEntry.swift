//
//  Created by jorge on 20/6/25.
//

// MARK: - Models
struct LocalizationEntry: Hashable, Sendable {
    let view: String
    let item: String
    let type: String
    let translations: [String: String]
    
    var key: String {
        "\(view)_\(item)_\(type)"
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }
    
    func translation(for language: String) -> String? {
        translations[language]
    }
    
    func hasTranslation(for language: String) -> Bool {
        translations[language]?.isEmpty == false
    }
}

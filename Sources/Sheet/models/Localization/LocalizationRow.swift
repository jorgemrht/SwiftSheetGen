
import Foundation

struct LocalizationRow {
    let view: String
    let item: String
    let type: String
    let translations: [String: String]
}

enum LocalizationHeader: String, CaseIterable {
    case view = "[View]"
    case item = "[Item]"
    case type = "[Type]"

    static var requiredHeaders: [String] {
        [view.rawValue, item.rawValue, type.rawValue]
    }
}

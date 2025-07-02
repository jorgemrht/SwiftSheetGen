import Foundation

struct ColorRow {
    let name: String
    let anyHex: String
    let lightHex: String
    let darkHex: String
    let desc: String
}

enum ColorHeader: String, CaseIterable {
    case name = "[Color Name]"
    case anyHex = "[Any Hex Value]"
    case lightHex = "[Light Hex Value]"
    case darkHex = "[Dark Hex Value]"

    static var requiredHeaders: [String] {
        [name.rawValue, anyHex.rawValue, lightHex.rawValue, darkHex.rawValue]
    }
}

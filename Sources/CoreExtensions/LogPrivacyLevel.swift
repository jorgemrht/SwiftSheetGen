import Foundation

public enum LogPrivacyLevel: String, Sendable {
    case `public`
    case `private`
}

public extension LogPrivacyLevel {
    init(from string: String) {
        switch string.lowercased() {
        case "private":
            self = .private
        default:
            self = .public
        }
    }
    
    var isPrivate: Bool {
        self == .private
    }
    
    var isPublic: Bool {
        self == .public
    }
}
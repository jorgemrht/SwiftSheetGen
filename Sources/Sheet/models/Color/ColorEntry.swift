import Foundation

public struct ColorEntry: Sendable {
    public let name: String
    public let anyHex: String?
    public let lightHex: String?
    public let darkHex: String?

    public init(
        name: String,
        anyHex: String?,
        lightHex: String?,
        darkHex: String?
    ) {
        self.name = name
        self.anyHex = anyHex
        self.lightHex = lightHex
        self.darkHex = darkHex
    }
}

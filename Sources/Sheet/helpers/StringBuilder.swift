import Foundation

public struct StringBuilder: Sendable {
    private var components: [String]
    private let estimatedSize: Int
    
    public init(estimatedSize: Int = 1024) {
        self.estimatedSize = estimatedSize
        self.components = []
        self.components.reserveCapacity(max(estimatedSize / 50, 16))
    }
    
    public mutating func append(_ string: String) {
        components.append(string)
    }
    
    public mutating func append(_ character: Character) {
        components.append(String(character))
    }
    
    public func build() -> String {
        return components.joined()
    }
}
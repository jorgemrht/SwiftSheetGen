// MARK: - Protocols for Abstraction
protocol SheetConfig {
    var outputDirectory: String { get }
    var csvFileName: String { get }
    var autoAddToXcode: Bool { get }
    var cleanupTemporaryFiles: Bool { get }
    var forceUpdateExistingXcodeFiles: Bool { get }
}


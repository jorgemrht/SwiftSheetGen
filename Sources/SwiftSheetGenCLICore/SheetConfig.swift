// MARK: - Protocols for Abstraction
public protocol SheetConfig {
    var outputDirectory: String { get }
    var csvFileName: String { get }
    var cleanupTemporaryFiles: Bool { get }
}
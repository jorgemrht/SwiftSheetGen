// MARK: - Protocols for Abstraction
protocol SheetConfig {
    var outputDirectory: String { get }
    var csvFileName: String { get }
    var cleanupTemporaryFiles: Bool { get }
}


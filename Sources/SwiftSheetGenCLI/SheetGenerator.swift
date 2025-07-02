// MARK: - Protocols for Abstraction

protocol SheetGenerator {
    associatedtype Config: SheetConfig
    init(config: Config)
    func generate(from csvFilePath: String) async throws
}

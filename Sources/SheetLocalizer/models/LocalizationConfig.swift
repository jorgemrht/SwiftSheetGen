import Foundation

// MARK: - Configuration
public struct LocalizationConfig: Sendable {
    
    public let outputDirectory: String
    public let enumName: String
    public let sourceDirectory: String
    public let csvFileName: String
    public let autoAddToXcode: Bool
    public let cleanupTemporaryFiles: Bool
    
    public init(
        outputDirectory: String,
        enumName: String,
        sourceDirectory: String,
        csvFileName: String,
        autoAddToXcode: Bool = true,
        cleanupTemporaryFiles: Bool = true
    ) {
        self.outputDirectory = outputDirectory
        self.enumName = enumName
        self.sourceDirectory = sourceDirectory
        self.csvFileName = csvFileName
        self.autoAddToXcode = autoAddToXcode
        self.cleanupTemporaryFiles = cleanupTemporaryFiles
    }
    
    public static let `default` = LocalizationConfig(
        outputDirectory: "./",
        enumName: "L10n",
        sourceDirectory: "./Sources/SheetLocalizer",
        csvFileName: "localizables.csv",
        autoAddToXcode: true,
        cleanupTemporaryFiles: true
    )
    
    public static func custom(
        outputDirectory: String = "./",
        enumName: String = "L10n",
        sourceDirectory: String = "./Sources/SheetLocalizer",
        csvFileName: String = "localizables.csv",
        autoAddToXcode: Bool = true,
        cleanupTemporaryFiles: Bool = true 
    ) -> LocalizationConfig {
        LocalizationConfig(
            outputDirectory: outputDirectory,
            enumName: enumName,
            sourceDirectory: sourceDirectory,
            csvFileName: csvFileName,
            autoAddToXcode: autoAddToXcode,
            cleanupTemporaryFiles: cleanupTemporaryFiles
        )
    }
}

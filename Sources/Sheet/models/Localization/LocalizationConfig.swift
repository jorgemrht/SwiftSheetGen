import Foundation

// MARK: - Configuration
public struct LocalizationConfig: Sendable {
    
    public let outputDirectory: String
    public let enumName: String
    public let sourceDirectory: String
    public let csvFileName: String
    public let cleanupTemporaryFiles: Bool
    public let unifiedLocalizationDirectory: Bool
    
    public init(
        outputDirectory: String,
        enumName: String,
        sourceDirectory: String,
        csvFileName: String,
        cleanupTemporaryFiles: Bool = true,
        unifiedLocalizationDirectory: Bool = true
    ) {
        self.outputDirectory = outputDirectory
        self.enumName = enumName
        self.sourceDirectory = sourceDirectory
        self.csvFileName = csvFileName
        self.cleanupTemporaryFiles = cleanupTemporaryFiles
        self.unifiedLocalizationDirectory = unifiedLocalizationDirectory
    }
    
    public static let `default` = LocalizationConfig(
        outputDirectory: "./",
        enumName: "L10n",
        sourceDirectory: "./Sources",
        csvFileName: "localizables.csv",
        cleanupTemporaryFiles: true
    )
    
    public static func custom(
        outputDirectory: String = "./Localizables",
        enumName: String = "L10n",
        sourceDirectory: String = "./Localizables", 
        csvFileName: String = "localizables.csv",
        cleanupTemporaryFiles: Bool = true,
        unifiedLocalizationDirectory: Bool = true
    ) -> LocalizationConfig {
        LocalizationConfig(
            outputDirectory: outputDirectory,
            enumName: enumName,
            sourceDirectory: sourceDirectory,
            csvFileName: csvFileName,
            cleanupTemporaryFiles: cleanupTemporaryFiles,
            unifiedLocalizationDirectory: unifiedLocalizationDirectory
        )
    }
}

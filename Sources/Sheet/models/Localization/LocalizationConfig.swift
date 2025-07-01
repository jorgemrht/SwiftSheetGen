import Foundation

// MARK: - Configuration
public struct LocalizationConfig: Sendable {
    
    public let outputDirectory: String
    public let enumName: String
    public let sourceDirectory: String
    public let csvFileName: String
    public let autoAddToXcode: Bool
    public let cleanupTemporaryFiles: Bool
    public let forceUpdateExistingXcodeFiles: Bool
    public let unifiedLocalizationDirectory: Bool
    
    public init(
        outputDirectory: String,
        enumName: String,
        sourceDirectory: String,
        csvFileName: String,
        autoAddToXcode: Bool = true,
        cleanupTemporaryFiles: Bool = true,
        forceUpdateExistingXcodeFiles: Bool = false,
        unifiedLocalizationDirectory: Bool = true
    ) {
        self.outputDirectory = outputDirectory
        self.enumName = enumName
        self.sourceDirectory = sourceDirectory
        self.csvFileName = csvFileName
        self.autoAddToXcode = autoAddToXcode
        self.cleanupTemporaryFiles = cleanupTemporaryFiles
        self.forceUpdateExistingXcodeFiles = forceUpdateExistingXcodeFiles
        self.unifiedLocalizationDirectory = unifiedLocalizationDirectory
    }
    
    public static let `default` = LocalizationConfig(
        outputDirectory: "./",
        enumName: "L10n",
        sourceDirectory: "./Sources",
        csvFileName: "localizables.csv",
        autoAddToXcode: true,
        cleanupTemporaryFiles: true
    )
    
    public static func custom(
        outputDirectory: String = "./Localizables",
        enumName: String = "L10n",
        sourceDirectory: String = "./Localizables", 
        csvFileName: String = "localizables.csv",
        autoAddToXcode: Bool = true,
        cleanupTemporaryFiles: Bool = true,
        forceUpdateExistingXcodeFiles: Bool = false,
        unifiedLocalizationDirectory: Bool = true
    ) -> LocalizationConfig {
        LocalizationConfig(
            outputDirectory: outputDirectory,
            enumName: enumName,
            sourceDirectory: sourceDirectory,
            csvFileName: csvFileName,
            autoAddToXcode: autoAddToXcode,
            cleanupTemporaryFiles: cleanupTemporaryFiles,
            forceUpdateExistingXcodeFiles: forceUpdateExistingXcodeFiles,
            unifiedLocalizationDirectory: unifiedLocalizationDirectory
        )
    }
}

import Foundation

// MARK: - Configuration
public struct LocalizationConfig: Sendable {
    
    public let outputDirectory: String
    public let enumName: String
    public let sourceDirectory: String
    public let csvFileName: String
    public let autoAddToXcode: Bool
    
    public init(
        outputDirectory: String,
        enumName: String,
        sourceDirectory: String,
        csvFileName: String,
        autoAddToXcode: Bool = true
    ) {
        self.outputDirectory = outputDirectory
        self.enumName = enumName
        self.sourceDirectory = sourceDirectory
        self.csvFileName = csvFileName
        self.autoAddToXcode = autoAddToXcode
    }
    
    public static let `default` = LocalizationConfig(
        outputDirectory: "./",
        enumName: "L10n",
        sourceDirectory: "./Sources/SheetLocalizer",
        csvFileName: "localizables.csv",
        autoAddToXcode: true
    )
    
    public static func custom(
        outputDirectory: String = "./",
        enumName: String = "L10n",
        sourceDirectory: String = "./Sources/SheetLocalizer",
        csvFileName: String = "localizables.csv",
        autoAddToXcode: Bool = true
    ) -> LocalizationConfig {
        LocalizationConfig(
            outputDirectory: outputDirectory,
            enumName: enumName,
            sourceDirectory: sourceDirectory,
            csvFileName: csvFileName,
            autoAddToXcode: autoAddToXcode
        )
    }
}

public extension LocalizationConfig {
    init(arguments args: [String]) {
        var config = LocalizationConfig.default

        for i in 2..<args.count {
            let arg = args[i]
            if arg.hasPrefix("--enum=") {
                let enumName = String(arg.dropFirst(7))
                config = LocalizationConfig.custom(
                    outputDirectory: config.outputDirectory,
                    enumName: enumName,
                    sourceDirectory: config.sourceDirectory,
                    csvFileName: config.csvFileName
                )
            } else if arg.hasPrefix("--output=") {
                let outputDir = String(arg.dropFirst(9))
                config = LocalizationConfig.custom(
                    outputDirectory: outputDir,
                    enumName: config.enumName,
                    sourceDirectory: config.sourceDirectory,
                    csvFileName: config.csvFileName
                )
            }
        }
        
        self = config
    }
}


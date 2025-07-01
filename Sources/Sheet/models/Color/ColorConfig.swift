import Foundation

public struct ColorConfig: Sendable {
    public let outputDirectory: String
    public let csvFileName: String
    public let autoAddToXcode: Bool
    public let cleanupTemporaryFiles: Bool
    public let forceUpdateExistingXcodeFiles: Bool

    public init(
        outputDirectory: String = "Colors",
        csvFileName: String = "generated_colors.csv",
        autoAddToXcode: Bool = true,
        cleanupTemporaryFiles: Bool = true,
        forceUpdateExistingXcodeFiles: Bool = false
    ) {
        self.outputDirectory = outputDirectory
        self.csvFileName = csvFileName
        self.autoAddToXcode = autoAddToXcode
        self.cleanupTemporaryFiles = cleanupTemporaryFiles
        self.forceUpdateExistingXcodeFiles = forceUpdateExistingXcodeFiles
    }

    public static var `default`: ColorConfig {
        ColorConfig()
    }

    public static func custom(
        outputDirectory: String,
        csvFileName: String,
        autoAddToXcode: Bool,
        cleanupTemporaryFiles: Bool,
        forceUpdateExistingXcodeFiles: Bool
    ) -> ColorConfig {
        ColorConfig(
            outputDirectory: outputDirectory,
            csvFileName: csvFileName,
            autoAddToXcode: autoAddToXcode,
            cleanupTemporaryFiles: cleanupTemporaryFiles,
            forceUpdateExistingXcodeFiles: forceUpdateExistingXcodeFiles
        )
    }
}

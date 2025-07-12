import Foundation

public struct ColorConfig: Sendable {
    public let outputDirectory: String
    public let csvFileName: String
    public let cleanupTemporaryFiles: Bool

    public init(
        outputDirectory: String = "Colors",
        csvFileName: String = "generated_colors.csv",
        cleanupTemporaryFiles: Bool = true,
    ) {
        self.outputDirectory = outputDirectory
        self.csvFileName = csvFileName
        self.cleanupTemporaryFiles = cleanupTemporaryFiles
    }

    public static var `default`: ColorConfig {
        ColorConfig()
    }

    public static func custom(
        outputDirectory: String,
        csvFileName: String,
        cleanupTemporaryFiles: Bool,
    ) -> ColorConfig {
        ColorConfig(
            outputDirectory: outputDirectory,
            csvFileName: csvFileName,
            cleanupTemporaryFiles: cleanupTemporaryFiles,
        )
    }
}

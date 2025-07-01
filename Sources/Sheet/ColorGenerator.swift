import Foundation
import XcodeIntegration
import CoreExtensions
import os.log

public struct ColorGenerator: Sendable {

    private let config: ColorConfig
    private static let logger = Logger.colorGenerator

    public init(config: ColorConfig = .default) {
        self.config = config
    }

    public func generate(from urlString: String) async throws {
        try Task.checkCancellation()
        Self.logger.info("Starting color generation from: \(urlString, privacy: .public)")

        // 1. Download CSV
        let tempCSVPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".csv").path
        let downloader = CSVDownloader.createWithDefaults()
        try await downloader.download(from: urlString, to: tempCSVPath)

        // 2. Parse CSV
        let content = try String(contentsOfFile: tempCSVPath, encoding: .utf8)
        let rows = try CSVParser.parse(content)
        let colorEntries = try processRows(rows)

        guard !colorEntries.isEmpty else {
            throw SheetLocalizerError.csvParsingError("No valid color entries found in CSV.")
        }

        Self.logger.info("Detected \(colorEntries.count) color entries.")

        // 3. Generate Colors.swift
        try await generateColorsFile(entries: colorEntries)

        // 4. Generate Color+Dynamic.swift
        try await generateColorDynamicFile()

        // 5. Add generated files to Xcode (if configured)
        if config.autoAddToXcode {
            try await addGeneratedFilesToXcode()
        }

        // 6. Cleanup temporary CSV
        try await cleanupTemporaryCSV(at: tempCSVPath)

        Self.logger.info("Color generation completed successfully.")
    }

    // MARK: - CSV Processing

    private func processRows(_ rows: [[String]]) throws -> [ColorEntry] {
        guard rows.count > 1 else {
            throw SheetLocalizerError.csvParsingError("CSV must have at least 2 rows (header + data).")
        }

        let header = rows[0].map { $0.trimmedContent }
        let expectedHeaders = ["Color Name", "Any Hex Value", "Light Hex Value", "Dark Hex Value"]

        // Basic header validation
        guard header.count >= expectedHeaders.count &&
              header[0] == expectedHeaders[0] &&
              header[1] == expectedHeaders[1] &&
              header[2] == expectedHeaders[2] &&
              header[3] == expectedHeaders[3] else {
            throw SheetLocalizerError.csvParsingError("Invalid CSV header. Expected: \(expectedHeaders.joined(separator: ", ")). Got: \(header.joined(separator: ", ")).")
        }

        var entries: [ColorEntry] = []
        for (rowIndex, row) in rows.dropFirst().enumerated() { // Skip header row
            if row.count < expectedHeaders.count {
                Self.logger.warning("Skipping row \(rowIndex + 2) due to insufficient columns: \(row.joined(separator: ", ")).")
                continue
            }

            let name = row[0].trimmedContent
            let anyHex = row[1].trimmedContent.isEmpty ? nil : row[1].trimmedContent
            let lightHex = row[2].trimmedContent.isEmpty ? nil : row[2].trimmedContent
            let darkHex = row[3].trimmedContent.isEmpty ? nil : row[3].trimmedContent

            guard !name.isEmpty else {
                Self.logger.warning("Skipping row \(rowIndex + 2) due to empty color name.")
                continue
            }

            // At least one hex value must be present
            guard anyHex != nil || lightHex != nil || darkHex != nil else {
                Self.logger.warning("Skipping row \(rowIndex + 2) for color '\(name)' as no hex values are provided.")
                continue
            }

            entries.append(ColorEntry(name: name, anyHex: anyHex, lightHex: lightHex, darkHex: darkHex))
        }
        return entries
    }

    // MARK: - File Generation

    private func generateColorsFile(entries: [ColorEntry]) async throws {
        let outputPath = "\(config.outputDirectory)/Colors.swift"
        let fileURL = URL(fileURLWithPath: outputPath)

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        let colorFileGenerator = ColorFileGenerator()
        let code = colorFileGenerator.generateCode(entries: entries)

        try code.write(to: fileURL, atomically: true, encoding: .utf8)
        Self.logger.info("Generated Colors.swift at: \(outputPath) (\(entries.count) colors)")
    }

    private func generateColorDynamicFile() async throws {
        let outputPath = "\(config.outputDirectory)/Color+Dynamic.swift"
        let fileURL = URL(fileURLWithPath: outputPath)

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        let colorDynamicFileGenerator = ColorDynamicFileGenerator()
        let code = colorDynamicFileGenerator.generateCode()

        try code.write(to: fileURL, atomically: true, encoding: .utf8)
        Self.logger.info("Generated Color+Dynamic.swift at: \(outputPath)")
    }

    // MARK: - Generated Files To Xcode

    private func addGeneratedFilesToXcode() async throws {
        Self.logger.info("Auto-adding generated color files to Xcode project...")
        let currentDir = FileManager.default.currentDirectoryPath
        let searchPaths = [currentDir, "\(currentDir)/..", "\(currentDir)/../.."]

        for searchPath in searchPaths {
            let resolvedPath = URL(fileURLWithPath: searchPath).standardized.path
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resolvedPath)
                if let xcodeproj = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
                    Self.logger.info("Found Xcode project: \(xcodeproj) in \(resolvedPath)")

                    let colorsFile = "\(config.outputDirectory)/Colors.swift"
                    let colorDynamicFile = "\(config.outputDirectory)/Color+Dynamic.swift"

                    try await XcodeIntegration.addSwiftFiles(
                        projectPath: resolvedPath,
                        files: [colorsFile, colorDynamicFile],
                        forceUpdateExisting: config.forceUpdateExistingXcodeFiles
                    )
                    return
                }
            } catch {
                Self.logger.debug("Could not read directory: \(resolvedPath)")
            }
        }

        Self.logger.error("No .xcodeproj found in current or parent directories")
    }

    // MARK: - Cleanup Temporary CSV

    private func cleanupTemporaryCSV(at csvPath: String) async throws {
        Self.logger.info("Cleaning up temporary CSV file: \(csvPath, privacy: .public)")

        let fileManager = FileManager.default
        let fileURL = URL(fileURLWithPath: csvPath)

        do {
            if fileManager.fileExists(atPath: csvPath) {
                try fileManager.removeItem(at: fileURL)
                Self.logger.info("Successfully deleted temporary CSV: \(csvPath, privacy: .public)")
            } else {
                Self.logger.debug("CSV file not found, skipping cleanup: \(csvPath, privacy: .public)")
            }
        } catch {
            Self.logger.error("Failed to delete temporary CSV: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// Assuming a new Logger category for colors, similar to LocalizationGenerator


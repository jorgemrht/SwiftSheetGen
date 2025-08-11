import Foundation
import XcodeIntegration
import CoreExtensions
import os.log

// MARK: - Color Generator

public struct ColorGenerator:  Sendable {

    private let config: ColorConfig
    private static let logger = Logger.colorGenerator

    public init(config: ColorConfig = .default) {
        self.config = config
    }

    // MARK: - CSV Generate
    
    public func generate(from csvPath: String) async throws {
        
        try Task.checkCancellation()
        
        Self.logger.info("Processing CSV \(csvPath, privacy: .public)")

        // 1. Parse CSV
        let rows = try await parseCSV(csvPath: csvPath)
        
        // 2. Validate CSV
        try validateCSVStructure(rows)
        
        guard rows.count > 3 else {
            throw SheetLocalizerError.insufficientData
        }
        
        // 3. Get Value From CSV
        let colorEntries = try processRows(rows)

        guard !colorEntries.isEmpty else {
            throw SheetLocalizerError.csvParsingError("No valid color entries found in CSV.")
        }

        Self.logger.info("Detected \(colorEntries.count) color entries.")

        // 4. Generate Colors Files
        try await generateColorsFile(entries: colorEntries)
        try await generateColorDynamicFile()

        // 5. Add generated files to Xcode (if configured)
        try await addGeneratedFilesToXcode()
        
        // 6. Cleanup Temporary Files
        if config.cleanupTemporaryFiles {
            try await cleanupTemporaryCSV(at: csvPath)
        }
    }

    // MARK: - CSV Processing

    private func processRows(_ rows: [[String]]) throws -> [ColorEntry] {
        
        guard rows.count > 1 else {
            throw SheetLocalizerError.csvParsingError("CSV must have at least 2 rows")
        }
        
        var headerRowIndex = -1
        
        for (index, row) in rows.enumerated() {
            if row.count > 5 &&
               row[1].trimmedContent == ColorHeader.name.rawValue &&
               row[2].trimmedContent == ColorHeader.anyHex.rawValue &&
               row[3].trimmedContent == ColorHeader.lightHex.rawValue &&
               row[4].trimmedContent == ColorHeader.darkHex.rawValue {
                headerRowIndex = index
                break
            }
        }
        
        guard headerRowIndex >= 0 else {
            throw SheetLocalizerError.csvParsingError("Header row not found with expected columns: \(ColorHeader.name.rawValue), \(ColorHeader.anyHex.rawValue), \(ColorHeader.lightHex.rawValue), \(ColorHeader.darkHex.rawValue)")
        }

        var entries: [ColorEntry] = []

        // Process rows after header
        for row in rows.dropFirst(headerRowIndex + 1) {
            if row.count < 6 { continue }

            // Skip comment and separator rows
            let firstCol = row.first?.trimmedContent ?? ""

            if firstCol == "[END]" { break }
            if firstCol == "[COMMENT]" || firstCol.hasPrefix("[") { continue }

            let name = row[1].trimmedContent
            let anyHex = row[2].trimmedContent
            let lightHex = row[3].trimmedContent
            let darkHex = row[4].trimmedContent

            guard !name.isEmpty else {
                Self.logger.warning("Skipping row due to empty name: \(row, privacy: .public)")
                continue
            }
            guard !name.hasPrefix("[") else {
                Self.logger.warning("Skipping row due to name starting with '[': \(row, privacy: .public)")
                continue
            }

            if anyHex.isEmpty && lightHex.isEmpty && darkHex.isEmpty {
                Self.logger.warning("Skipping row '\(name)' due to all hex values being empty: \(row, privacy: .public)")
                continue
            }

            entries.append(ColorEntry(
                name: name,
                anyHex: anyHex.isEmpty ? nil : anyHex,
                lightHex: lightHex.isEmpty ? nil : lightHex,
                darkHex: darkHex.isEmpty ? nil : darkHex
            ))
        }
        return entries
    }

    // MARK: - CSV Structure Validation

    private func validateCSVStructure(_ rows: [[String]]) throws {
     
        guard rows.count >= 2 else {
            throw SheetLocalizerError.csvParsingError("CSV must have at least 2 rows (header and data).")
        }

        var foundValidHeader = false
        
        for row in rows {
            if row.count >= 6 &&
               row[1].trimmedContent == ColorHeader.name.rawValue &&
               row[2].trimmedContent == ColorHeader.anyHex.rawValue &&
               row[3].trimmedContent == ColorHeader.lightHex.rawValue &&
               row[4].trimmedContent == ColorHeader.darkHex.rawValue {
                foundValidHeader = true
                break
            }
        }
        
        guard foundValidHeader else {
            throw SheetLocalizerError.csvParsingError("Invalid CSV structure. Expected header with \(ColorHeader.name.rawValue), \(ColorHeader.anyHex.rawValue), \(ColorHeader.lightHex.rawValue), \(ColorHeader.darkHex.rawValue).")
        }
        
        Self.logger.info("CSV Structure validated successfully.")
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
        
        if isTuistProject() {
            Self.logger.info("🎯 Tuist project detected - skipping automatic Xcode integration")
            Self.logger.info("📋 TUIST INSTRUCTIONS:")
            Self.logger.info("1. Add the generated files to your Project.swift manifest")
            Self.logger.info("2. Run 'tuist generate' to update your Xcode project")
            Self.logger.info("📁 Generated files in: \(config.outputDirectory)/")
            Self.logger.info("   • Colors.swift")
            Self.logger.info("   • Color+Dynamic.swift")
            return
        }
        
        Self.logger.info("Auto-adding generated color files to Xcode project...")
        
        guard let projectPath = try GeneratorHelper.findXcodeProjectPath(logger: Self.logger) else {
            Self.logger.error("No .xcodeproj found in current or parent directories")
            showManualInstructions()
            return
        }

        let colorsFile = "\(config.outputDirectory)/Colors.swift"
        let colorDynamicFile = "\(config.outputDirectory)/Color+Dynamic.swift"
        
        guard FileManager.default.fileExists(atPath: colorsFile),
              FileManager.default.fileExists(atPath: colorDynamicFile) else {
            Self.logger.error("Generated files not found on disk")
            return
        }

        do {
            
            try await XcodeIntegration.addSwiftFiles(
                projectPath: projectPath,
                files: [colorsFile, colorDynamicFile]
            )
            
            try await verifyXcodeIntegration(files: [colorsFile, colorDynamicFile])
            
            Self.logger.info("✅ Files successfully added to Xcode project")
            
        } catch {
            Self.logger.error("Error when adding files to the project: \(error)")
            showManualInstructions()
        }
    }

    // MARK: - Helper Functions

    private func verifyXcodeIntegration(files: [String]) async throws {
        Self.logger.info("Verifying integration with Xcode...")
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        Self.logger.info("Generated files:")
        for file in files {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            Self.logger.info("  • \(fileName)")
        }
        
        Self.logger.info("If the files do not appear in the Project Navigator:")
        Self.logger.info("1. Close and reopen Xcode")
        Self.logger.info("2. Clean up the project (⌘+Shift+K)")
        Self.logger.info("3. Or manually drag files from Finder")
    }

    private func showManualInstructions() {
        Self.logger.info("📋 MANUAL INSTRUCTIONS:")
        Self.logger.info("1. Open your project in Xcode")
        Self.logger.info("2. Drag the files from Finder to Project Navigator")
        Self.logger.info("3. Select 'Add Files to [ProjectName]' when the dialog appears")
        Self.logger.info("4. Make sure you select the correct target")
        Self.logger.info("📁 Files generated in: \(config.outputDirectory)/")
        Self.logger.info("   • Colors.swift")
        Self.logger.info("   • Color+Dynamic.swift")
    }

    // MARK: - Cleanup Temporary CSV

    private func cleanupTemporaryCSV(at csvPath: String) async throws {
        try await GeneratorHelper.cleanupTemporaryFile(at: csvPath, logger: Self.logger)
    }
    
    // MARK: - CSV Parsing
    
    private func parseCSV(csvPath: String) async throws -> [[String]] {
        let fileSize = try FileManager.default.attributesOfItem(atPath: csvPath)[.size] as? Int64 ?? 0
        let fileSizeInMB = Double(fileSize) / (1024 * 1024)
        
        Self.logger.info("CSV file size: \(String(format: "%.2f", fileSizeInMB)) MB")
        
        return try await CSVParser.parse(filePath: csvPath)
    }
    
    // MARK: - Detect Tuist Project
    
    private func isTuistProject() -> Bool {
        let tuistFiles = [
            "Project.swift",
            "Workspace.swift",
            "Tuist/Project.swift",
            "Tuist/Workspace.swift",
            ".tuist-version"
        ]
        
        for file in tuistFiles {
            if FileManager.default.fileExists(atPath: file) {
                Self.logger.info("Detected Tuist project file: \(file)")
                return true
            }
        }
        
        return false
    }
}

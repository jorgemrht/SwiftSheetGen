import Foundation
import XcodeIntegration
import CoreExtensions
import os.log

// MARK: - Localization Generator

public struct LocalizationGenerator: Sendable {
    
    private let config: LocalizationConfig
    private static let logger = Logger.localizationGenerator
    
    public init(config: LocalizationConfig = .default) {
        self.config = config
    }

    // MARK: - CSV Generate
    
    public func generate(from csvPath: String) async throws {
        
        try Task.checkCancellation()
        Self.logger.info("Processing CSV: \(csvPath, privacy: .public)")
      
        // 1. Parse CSV
        let content = try String(contentsOfFile: csvPath, encoding: .utf8)
        let rows = try CSVParser.parse(content)
        
        // 2. Validate CSV
        try validateCSVStructure(rows)
        
        guard rows.count > 3 else {
            throw SheetLocalizerError.insufficientData
        }

        // 3. Get Value From CSV
        let (languages, entries) = try processRows(rows)
        
        guard !languages.isEmpty else {
            throw SheetLocalizerError.csvParsingError("No valid languages were found")
        }

        Self.logger.info("Detected languages: [\(languages.joined(separator: ", ")), privacy: .public]")
       
        guard !entries.isEmpty else {
            throw SheetLocalizerError.csvParsingError("No valid entries found")
        }

        Self.logger.info("Detected entries: \(entries.count, privacy: .public)")
        
        // 4. Generate Localization Files
        try await generateLocalizationFiles(languages: languages, entries: entries)
        
        let allKeys = Set(entries.map(\.key)).sorted()
        try await generateSwiftEnum(allKeys: allKeys)
        
        // 5. Add generated files to Xcode (if configured)
        try await addGeneratedFilesToXcode(languages: languages)
        
        // 6. Cleanup Temporary Files
        if config.cleanupTemporaryFiles {
            try await cleanupTemporaryCSV(at: csvPath)
        }
    }

    // MARK: - CSV Processing

    private func processRows(_ rows: [[String]]) throws -> ([String], [LocalizationEntry]) {
        
        guard rows.count > 1 else {
            throw SheetLocalizerError.csvParsingError("CSV must have at least 2 rows")
        }

        var headerRowIndex = -1
        
        for (index, row) in rows.enumerated() {
            if row.count > 4 &&
               row[1].trimmedContent == LocalizationHeader.view.rawValue &&
               row[2].trimmedContent == LocalizationHeader.item.rawValue &&
               row[3].trimmedContent == LocalizationHeader.type.rawValue {
                headerRowIndex = index
                break
            }
        }
        
        guard headerRowIndex >= 0 else {
            throw SheetLocalizerError.csvParsingError("Header row not found")
        }
        
        let header = rows[headerRowIndex]
        
        guard header.count > 4 else {
            throw SheetLocalizerError.csvParsingError("Header must have at least 5 columns")
        }

        // Extract languages from columns after [Type]
        let languages = Array(header.dropFirst(4))
            .map { $0.trimmedContent }
            .filter { !$0.isEmpty && !$0.hasPrefix("[") }

        Self.logger.info("Detected languages: \(languages, privacy: .public)")
        
        var entries: [LocalizationEntry] = []
        
        // Process rows after header
        for row in rows.dropFirst(headerRowIndex + 1) {
            if row.count < 5 { continue }
            
            // Skip comment and separator rows
            let firstCol = row.first?.trimmedContent.uppercased() ?? ""
            let secondCol = row.count > 1 ? row[1].trimmedContent.uppercased() : ""
            
            if firstCol == "[END]" { break }
            if secondCol == "[COMMENT]" || secondCol.hasPrefix("[") { continue }
            
            // Extract view, item, type from columns 1, 2, 3
            guard row.count >= 4 else { continue }
            
            let view = row[1].trimmedContent
            let item = row[2].trimmedContent
            let type = row[3].trimmedContent
            
            guard !view.isEmpty && !item.isEmpty && !type.isEmpty else { continue }
            guard !view.hasPrefix("[") && !item.hasPrefix("[") && !type.hasPrefix("[") else { continue }

            // Feedback sobre claves inválidas
            let key = "\(view)_\(item)_\(type)"
            if let reason = key.invalidLocalizationKeyReason, !reason.isEmpty {
                Self.logger.error("Invalid localization key: \(key, privacy: .public) — Reason: \(reason, privacy: .public)")
                continue
            }
            // Extract translations starting from column 4
            let values = Array(row.dropFirst(4))
            var translations: [String: String] = [:]

            for index in languages.indices {
                if index < values.count {
                    let val = values[index].trimmedContent
                    if !val.isEmpty {
                        translations[languages[index]] = val
                    }
                }
            }

            guard !translations.isEmpty else { continue }

            let entry = LocalizationEntry(
                view: view,
                item: item,
                type: type,
                translations: translations
            )

            entries.append(entry)
        }

        return (languages, entries)
    }

    // MARK: - CSV Structure Validation

    private func validateCSVStructure(_ rows: [[String]]) throws {
      
        guard rows.count >= 4 else {
            throw SheetLocalizerError.csvParsingError("CSV must have at least 4 rows")
        }
        
        var foundValidHeader = false
        
        for row in rows {
            if row.count >= 5 &&
               row[1].trimmedContent == LocalizationHeader.view.rawValue &&
               row[2].trimmedContent == LocalizationHeader.item.rawValue &&
               row[3].trimmedContent == LocalizationHeader.type.rawValue {
                foundValidHeader = true
                
                let languageColumns = Array(row.dropFirst(4))
                    .map { $0.trimmedContent }
                    .filter { !$0.isEmpty && !$0.hasPrefix("[") }
                
                guard !languageColumns.isEmpty else {
                    throw SheetLocalizerError.csvParsingError("No language columns found after \(LocalizationHeader.type.rawValue) column")
                }
                
                Self.logger.info("CSV Structure validated:")
                Self.logger.info("  - Header found with structure: \(LocalizationHeader.requiredHeaders.joined(separator: ", "))")
                Self.logger.info("  - Language columns: [\(languageColumns.joined(separator: ", "))]")
                
                break
            }
        }
        
        guard foundValidHeader else {
            throw SheetLocalizerError.csvParsingError("Invalid CSV structure. Expected header row with \(LocalizationHeader.requiredHeaders.joined(separator: ", ")) format")
        }
    }

    // MARK: - File Generation

    private func generateLocalizationFiles(languages: [String], entries: [LocalizationEntry]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for language in languages {
                try Task.checkCancellation()
                group.addTask {
                    try await self.generateLanguageFile(language: language, entries: entries)
                }
            }
            try await group.waitForAll()
        }
    }

    private func generateLanguageFile(language: String, entries: [LocalizationEntry]) async throws {
        
        let folder = "\(config.outputDirectory)/\(language).lproj"
        
        try FileManager.default.createDirectory(
            atPath: folder,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let filePath = "\(folder)/Localizable.strings"
        
        let validEntries = entries
            .filter { $0.hasTranslation(for: language) }
            .sorted { $0.key < $1.key }
        
        let content = validEntries.compactMap { entry -> String? in
            guard let translation = entry.translation(for: language) else {
                Self.logger.warning("Skipping entry '\(entry.key)' for language '\(language)' due to missing translation.")
                return nil
            }
            
            let range = NSRange(translation.startIndex..<translation.endIndex, in: translation)
            let formattedTranslation = Constants.placeholderRegex.stringByReplacingMatches(
                in: translation,
                options: [],
                range: range,
                withTemplate: "%@"
            )
            
            let escaped = formattedTranslation
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            
                return "\"\(entry.key)\" = \"\(escaped)\";"
        }.joined(separator: "\n")
            
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)

        Self.logger.info("Generated: \(filePath) (\(validEntries.count) entries)")
    }

    private func generateSwiftEnum(allKeys: [String]) async throws {
        let outputPath = "\(config.sourceDirectory)/\(config.enumName).swift"
        let fileURL = URL(fileURLWithPath: outputPath)
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        
        let enumGenerator = SwiftEnumGenerator(enumName: config.enumName)
        let code = enumGenerator.generateCode(allKeys: allKeys)
        
        try code.write(to: fileURL, atomically: true, encoding: .utf8)
        Self.logger.info("Enum generated at: \(outputPath) (\(allKeys.count) cases)")
    }
    
    // MARK: - Generated Files To Xcode
    
    private func addGeneratedFilesToXcode(languages: [String]) async throws {
        
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
        
        Self.logger.info("Auto-adding generated files to Xcode project...")

        guard let projectPath = try GeneratorHelper.findXcodeProjectPath(logger: Self.logger) else {
            Self.logger.error("No .xcodeproj found in current or parent directories")
            return
        }

        let localizationFiles = languages.map { "\(config.outputDirectory)/\($0).lproj/Localizable.strings" }
        let enumFile = "\(config.sourceDirectory)/\(config.enumName).swift"

        try await XcodeIntegration.addLocalizationFiles(
            projectPath: projectPath,
            generatedFiles: localizationFiles,
            languages: languages,
            enumFile: enumFile
        )
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

extension LocalizationGenerator {
    private enum Constants {
        static let placeholderRegex: NSRegularExpression = {
            do {
                return try NSRegularExpression(pattern: "\\{\\{.*?\\}\\}")
            } catch {
                fatalError("Invalid regex pattern for placeholders: \(error.localizedDescription)")
            }
        }()
    }
}

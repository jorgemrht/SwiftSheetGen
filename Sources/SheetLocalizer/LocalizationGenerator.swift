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

    public func generate(from csvPath: String) async throws {
        try Task.checkCancellation()
        Self.logger.info("Processing CSV: \(csvPath, privacy: .public)")
        
        let content = try String(contentsOfFile: csvPath, encoding: .utf8)
        let rows = try CSVParser.parse(content)
        
        try validateCSVStructure(rows)
        
        guard rows.count > 3 else {
            throw SheetLocalizerError.insufficientData
        }

        let (languages, entries) = try processRows(rows)
        
        guard !languages.isEmpty else {
            throw SheetLocalizerError.csvParsingError("No valid languages were found")
        }

        guard !entries.isEmpty else {
            throw SheetLocalizerError.csvParsingError("No valid entries found")
        }

        Self.logger.info("Detected languages: [\(languages.joined(separator: ", ")), privacy: .public]")
        Self.logger.info("Detected entries: \(entries.count, privacy: .public)")
        
        try Task.checkCancellation()
        try await generateLocalizationFiles(languages: languages, entries: entries)
        
        try Task.checkCancellation()
        let allKeys = Set(entries.map(\.key)).sorted()
        
        try Task.checkCancellation()
        try await generateSwiftEnum(allKeys: allKeys)
        
        if config.autoAddToXcode {
            try await addGeneratedFilesToXcode(languages: languages)
        }
        
        if config.cleanupTemporaryFiles {
            try await cleanupTemporaryCSV(at: csvPath)
        }
    }

    // MARK: - CSV Processing

    private func processRows(_ rows: [[String]]) throws -> ([String], [LocalizationEntry]) {
        guard rows.count > 1 else {
            throw SheetLocalizerError.csvParsingError("CSV must have at least 2 rows")
        }

        // Find the header row with [View], [Item], [Type]
        var headerRowIndex = -1
        for (index, row) in rows.enumerated() {
            if row.count > 4 &&
               row[1].trimmedContent == "[View]" &&
               row[2].trimmedContent == "[Item]" &&
               row[3].trimmedContent == "[Type]" {
                headerRowIndex = index
                break
            }
        }
        
        guard headerRowIndex >= 0 else {
            throw SheetLocalizerError.csvParsingError("Header row with [View], [Item], [Type] not found")
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
        
        // Look for header row with [View], [Item], [Type] structure
        var foundValidHeader = false
        
        for row in rows {
            if row.count >= 5 &&
               row[1].trimmedContent == "[View]" &&
               row[2].trimmedContent == "[Item]" &&
               row[3].trimmedContent == "[Type]" {
                foundValidHeader = true
                
                // Check for at least one language column
                let languageColumns = Array(row.dropFirst(4))
                    .map { $0.trimmedContent }
                    .filter { !$0.isEmpty && !$0.hasPrefix("[") }
                
                guard !languageColumns.isEmpty else {
                    throw SheetLocalizerError.csvParsingError("No language columns found after [Type] column")
                }
                
                Self.logger.info("CSV Structure validated:")
                Self.logger.info("  - Header found with structure: [View], [Item], [Type]")
                Self.logger.info("  - Language columns: [\(languageColumns.joined(separator: ", "))]")
                
                break
            }
        }
        
        guard foundValidHeader else {
            throw SheetLocalizerError.csvParsingError("Invalid CSV structure. Expected header row with [View], [Item], [Type] format")
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
        
        let enumGenerator = SwiftEnumGenerator(enumName: config.enumName)
        
        let code = enumGenerator.generateCode(allKeys: allKeys)
        
        let fileURL = URL(fileURLWithPath: outputPath)
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        try code.write(to: fileURL, atomically: true, encoding: .utf8)
        Self.logger.info("Enum generated at: \(outputPath) (\(allKeys.count) cases)")
    }
    
    // MARK: - Generated Files To Xcode
    
    private func addGeneratedFilesToXcode(languages: [String]) async throws {
        Self.logger.info("Auto-adding generated files to Xcode project...")
        let currentDir = FileManager.default.currentDirectoryPath
        let searchPaths = [currentDir, "\(currentDir)/..", "\(currentDir)/../.."]
        
        for searchPath in searchPaths {
            let resolvedPath = URL(fileURLWithPath: searchPath).standardized.path
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resolvedPath)
                if let xcodeproj = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
                    Self.logger.info("Found Xcode project: \(xcodeproj) in \(resolvedPath)")
                    
                    let localizationFiles: [String]
                    
                    localizationFiles = languages.map { "\(config.outputDirectory)/\($0).lproj/Localizable.strings" }
                    
                    let enumFile = "\(config.sourceDirectory)/\(config.enumName).swift"
                    
                    try await XcodeIntegration.addLocalizationFiles(
                        projectPath: resolvedPath,
                        generatedFiles: localizationFiles,
                        languages: languages,
                        enumFile: enumFile,
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

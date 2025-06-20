//
//  Created by jorge on 20/6/25.
//

import Foundation

// MARK: - Localization Generator
//  LocalizationGenerator.swift
import Foundation

// MARK: - Localization Generator
public struct LocalizationGenerator: Sendable {
    private let config: LocalizationConfig

    public init(config: LocalizationConfig = .default) {
        self.config = config
    }

    public func generate(from csvPath: String) async throws {
        try Task.checkCancellation()
        print("🔄 Processing CSV: \(csvPath)")

        let content = try String(contentsOfFile: csvPath, encoding: .utf8)
        let rows = try CSVParser.parse(content)

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

        print("🌐 Detected languages: [\(languages.joined(separator: ", "))]")
        print("📝 Detected entries: \(entries.count)")

        try Task.checkCancellation()
        try await generateLocalizationFiles(languages: languages, entries: entries)

        try Task.checkCancellation()
        let allKeys = Set(entries.map(\.key)).sorted()
        try Task.checkCancellation()
        try await generateSwiftEnum(allKeys: allKeys)
    }

    // MARK: - CSV Processing
    private func processRows(_ rows: [[String]]) throws -> ([String], [LocalizationEntry]) {
        guard rows.count > 1 else {
            throw SheetLocalizerError.csvParsingError("CSV must have at least 2 rows")
        }

        let header = rows[1]
        guard header.count > 4 else {
            throw SheetLocalizerError.csvParsingError("Header must have at least 5 columns")
        }

        let languages = Array(header.dropFirst(4))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        print("🌐 Idiomas detectados: \(languages)")

        var entries: [LocalizationEntry] = []

        for row in rows.dropFirst(3) {
            if row.count < 5 { continue }
            if row[1].trimmingCharacters(in: .whitespacesAndNewlines) == "[COMMENT]" { continue }
            if row.first?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "[END]" { continue }

            let cols = Array(row.dropFirst(1))
            guard cols.count >= 3 else { continue }

            let view = cols[0].trimmingCharacters(in: .whitespaces)
            let item = cols[1].trimmingCharacters(in: .whitespaces)
            let type = cols[2].trimmingCharacters(in: .whitespaces)
            guard !view.isEmpty && !item.isEmpty && !type.isEmpty else { continue }

            let values = Array(cols.dropFirst(3))
            var translations: [String: String] = [:]

            for index in languages.indices {
                if index < values.count {
                    let val = values[index].trimmingCharacters(in: .whitespacesAndNewlines)
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

        let content = validEntries.map { entry in
            let translation = entry.translation(for: language)!
            let escaped = translation
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            return "\"\(entry.key)\" = \"\(escaped)\";"
        }.joined(separator: "\n")

        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
        print("✔️ Generated: \(filePath) (\(validEntries.count) entries)")
    }

    private func generateSwiftEnum(allKeys: [String]) async throws {
        let outputPath = "\(config.sourceDirectory)/Localization.swift"
        let code = try await buildSwiftEnumCode(allKeys: allKeys)

        let fileURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try code.write(to: fileURL, atomically: true, encoding: .utf8)
        print("✔️ Enum generated at: \(outputPath) (\(allKeys.count) cases)")
    }

    // MARK: - Swift Enum Builder
    private func buildSwiftEnumCode(allKeys: [String]) async throws -> String {
        let formattedDate = Date().formatted(date: .abbreviated, time: .shortened)
        var code = """
        // Auto-generated by SheetLocalizer — do not edit
        // Generated on: \(formattedDate)

        import Foundation

        @frozen
        public enum \(config.enumName): String, CaseIterable, Sendable {
        """

        for key in allKeys {
            let safe = generateSafeSwiftIdentifier(from: key)
            code += "\n    case \(safe) = \"\(key)\""
        }

        code += """

            /// Returns the localized string for this key
            public var localized: String {
                NSLocalizedString(self.rawValue, bundle: .main, comment: "")
            }

            /// Returns a formatted localized string with arguments
            public func localized(_ args: CVarArg...) -> String {
                String(format: localized, arguments: args)
            }
        }

        extension String {
            /// Localizes the string key
            public var localized: String {
                NSLocalizedString(self, comment: "")
            }

            /// Localizes with formatting arguments
            public func localized(_ args: CVarArg...) -> String {
                String(format: NSLocalizedString(self, comment: ""), arguments: args)
            }
        }
        """
        return code
    }

    // MARK: - Identifier Sanitization
    private func generateSafeSwiftIdentifier(from key: String) -> String {
        let components = key
            .replacingOccurrences(of: "-", with: "_")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        let camel = components.enumerated().map { idx, comp in
            let lower = comp.lowercased()
            return idx == 0 ? lower : lower.capitalized
        }.joined()

        let prefix = camel.first?.isNumber == true || camel.isEmpty ? "_" : ""
        return prefix + camel
    }
}



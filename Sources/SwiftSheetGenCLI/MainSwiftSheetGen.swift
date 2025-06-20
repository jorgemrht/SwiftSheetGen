//
//  Main.swift
//  Created by Jorge on 2025-06-20
//

import Foundation
import SheetLocalizer

// MARK: - Entry Point

@main
public struct MainSwiftSheetGen {
    static func main() async {
        let args = CommandLine.arguments

        guard args.count >= 2 else {
            printUsage()
            exit(1)
        }

        let csvURL = args[1]
        let config = parseArguments(args)
        let csvPath = "\(FileManager.default.currentDirectoryPath)/localizables/\(config.csvFileName)"

        do {
            print("🚀 Starting SheetLocalizer...")

            let downloader = CSVDownloader()
            try await downloader.download(from: csvURL, to: csvPath)

            let generator = LocalizationGenerator(config: config)
            try await generator.generate(from: csvPath)

            print("🎉 Localization completed successfully")

        } catch {
            fputs("❌ Error: \(error.localizedDescription)\n", stderr)
            exit(2)
        }
    }

    private static func parseArguments(_ args: [String]) -> LocalizationConfig {
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

        return config
    }

    private static func printUsage() {
        print("""
        SheetLocalizer - Localization file generator from Google Sheets

        Usage: SheetLocalizer <csv-url> [options]

        Options:
          --enum=NAME       Name of the generated enum (default: JMR)
          --output=PATH     Output directory for .lproj and .swift files (default: ./)

        Example:
          SheetLocalizer "https://docs.google.com/spreadsheets/d/.../edit" --enum=Strings
        """)
    }
}

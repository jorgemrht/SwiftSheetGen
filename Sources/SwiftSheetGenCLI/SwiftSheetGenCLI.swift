import Foundation
import ArgumentParser
import SwiftSheetGenCLICore

// MARK: - Main CLI Command
@main
public struct SwiftSheetGenCLI: AsyncParsableCommand {
    
    #if SWIFTSHEETGEN_VERSION
    private static let version = SWIFTSHEETGEN_VERSION
    #else
    private static let version = "0.0.0-development"
    #endif
    
    public static let configuration = CommandConfiguration(
        commandName: "swiftsheetgen",
        abstract: "A command-line tool for generating localizables and colors from Google Sheets data.",
        version: Self.version,
        subcommands: [LocalizationCommand.self, ColorsCommand.self]
    )

    public init() {}
}

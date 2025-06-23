import Foundation
import SheetLocalizer
import ArgumentParser

// MARK: - Entry Point

@main
public struct SwiftSheetGenCLI: AsyncParsableCommand {
    
    public static let configuration = CommandConfiguration(
        commandName: "swiftsheetgen",
        abstract: "Generate localizations from Google Sheets",
        version: "0.0.1"
    )
    
    @Argument(help: "Google Sheets URL")
    var sheetURL: String
    
    @Option(name: .long, help: "Enum name for generated code")
    var enumName: String = "L10n"
    
    @Option(name: .long, help: "Output directory")
    var output: String = "./"
    
    @Flag(help: "Enable verbose logging")
    var verbose: Bool = false
    
    // MARK: - Init Required
    public init() {}
    
    // MARK: - Run Method (aquí es donde va toda tu lógica)
    public func run() async throws {
        
        let config = LocalizationConfig.custom(
            outputDirectory: output,
            enumName: enumName,
            sourceDirectory: "\(output)/Sources/SheetLocalizer",
            csvFileName: "localizables.csv"
        )
        
        let csvPath = "\(FileManager.default.currentDirectoryPath)/localizables/\(config.csvFileName)"
        
        if verbose {
            print("🔧 Configuration:")
            print("   - Sheet URL: \(sheetURL)")
            print("   - Enum Name: \(enumName)")
            print("   - Output: \(output)")
            print("   - CSV Path: \(csvPath)")
        }
        
        do {
            print("🚀 Starting SheetLocalizer...")
            
            let downloader = CSVDownloader()
            try await downloader.download(from: sheetURL, to: csvPath)
            
            let generator = LocalizationGenerator(config: config)
            try await generator.generate(from: csvPath)
            
            print("🎉 Localization completed successfully!")
            
        } catch {
            throw SheetLocalizerError.networkError("Failed to generate localizations: \(error.localizedDescription)")
        }
    }
}

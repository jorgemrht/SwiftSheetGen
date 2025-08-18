import Testing
@testable import SheetLocalizer
import Foundation

@Suite()
struct LocalizationGeneratorIntegrationTests {

    @Test("Localization generation creates complete .lproj structure with proper content")
    func localizationGenerationCreatesCompleteLprojStructure() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvPath = tempDir.appendingPathComponent("test.csv").path
        try SharedTestData.localizationCSV.write(toFile: csvPath, atomically: true, encoding: .utf8)

        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "L10nTest",
            sourceDirectory: tempDir.path,
            csvFileName: "test.csv",
            cleanupTemporaryFiles: false
        )
        
        try await LocalizationGenerator(config: config).generate(from: csvPath)

        let languages = ["es", "en", "fr"]
        let expectedValues = ["jorgemrht", "My App", "Mon App"]
        
        for (i, lang) in languages.enumerated() {
            let file = tempDir.appendingPathComponent("\(lang).lproj/Localizable.strings").path
            #expect(FileManager.default.fileExists(atPath: file), "\(lang) localization file should exist")
            
            let contents = try String(contentsOfFile: file, encoding: .utf8)
            #expect(contents.contains("common_app_name_text"))
            #expect(contents.contains(expectedValues[i]))
        }
        
        let enContents = try String(contentsOfFile: tempDir.appendingPathComponent("en.lproj/Localizable.strings").path, encoding: .utf8)
        #expect(enContents.contains("profile_version_text") && enContents.contains("Version %@ (Build %@)"))
    }


    @Test("Localization generator validates CSV structure and data requirements",
          arguments: [
              ("\"\", \"common\", \"app_name\", \"text\", \"jorgemrht\", \"My App\", \"Mon App\"\n[END]", "missing-header"),
              ("\"[Check]\", \"[View]\", \"[Item]\", \"[Type]\", \"es\", \"en\", \"fr\"\n\"\", \"common\", \"app_name\", \"text\", \"jorgemrht\", \"My App\", \"Mon App\"\n[END]", "insufficient-data")
          ])
    func localizationGeneratorValidatesCSVRequirements(csvContent: String, errorType: String) async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let csvPath = tempDir.appendingPathComponent("test.csv").path
        try csvContent.write(toFile: csvPath, atomically: true, encoding: .utf8)
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "L10nTest",
            sourceDirectory: tempDir.path,
            csvFileName: "test.csv",
            cleanupTemporaryFiles: false
        )
        let generator = LocalizationGenerator(config: config)
        
        do {
            try await generator.generate(from: csvPath)
            #expect(Bool(false), "Should throw on \(errorType)")
        } catch {
            let errorDesc = String(describing: error).lowercased()
            #expect(!errorDesc.isEmpty, "Error should have a description")
            let hasExpectedTerms = errorDesc.contains("header") ||
                                   errorDesc.contains("structure") || 
                                   errorDesc.contains("invalid") ||
                                   errorDesc.contains("data") || 
                                   errorDesc.contains("rows") || 
                                   errorDesc.contains("insufficient") ||
                                   errorDesc.contains("parsing") ||
                                   errorDesc.contains("csv")
            #expect(hasExpectedTerms, "Error should contain relevant terms: \(error)")
        }
    }
}


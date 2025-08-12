import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct SheetConfigTests {

    @Test
    func testLocalizationConfig() {
        let config = LocalizationConfig(
            outputDirectory: "Localization",
            enumName: "L10n",
            sourceDirectory: "Localization",
            csvFileName: "localizations.csv",
            cleanupTemporaryFiles: true,
            unifiedLocalizationDirectory: true,
            useStringsCatalog: false
        )

        #expect(config.outputDirectory == "Localization")
        #expect(config.csvFileName == "localizations.csv")
        #expect(config.cleanupTemporaryFiles == true)
    }

    @Test
    func testColorConfig() {
        let config = ColorConfig(
            outputDirectory: "Colors",
            csvFileName: "colors.csv",
            cleanupTemporaryFiles: true
        )

        #expect(config.outputDirectory == "Colors")
        #expect(config.csvFileName == "colors.csv")
        #expect(config.cleanupTemporaryFiles == true)
    }
}
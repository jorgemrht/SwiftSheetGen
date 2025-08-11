import Testing
import Foundation
@testable import SheetLocalizer

// MARK: - Color File Generators Tests

@Suite
struct ColorFileGeneratorTests {
    
    // MARK: - Sample Data
    
    private func createSampleColorEntries() -> [ColorEntry] {
        return [
            ColorEntry(
                name: "primaryColor",
                anyHex: nil,
                lightHex: "#FF5733",
                darkHex: "#AA3311"
            ),
            ColorEntry(
                name: "backgroundColor",
                anyHex: nil,
                lightHex: "#FFFFFF",
                darkHex: "#000000"
            ),
            ColorEntry(
                name: "accentColor",
                anyHex: nil,
                lightHex: "#00AAFF",
                darkHex: "#0088CC"
            )
        ]
    }
    
    // MARK: - ColorFileGenerator Tests
    
    @Test
    func test_colorFileGeneratorBasicStructure() throws {
        let entries = createSampleColorEntries()
        let generator = ColorFileGenerator()
        
        let code = generator.generateCode(entries: entries)
        
        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("import UIKit"))
        #expect(code.contains("extension Color"))
        #expect(code.contains("extension UIColor"))
        
        #expect(code.contains("static let primaryColor"))
        #expect(code.contains("static let backgroundColor"))
        #expect(code.contains("static let accentColor"))
        
        #expect(code.contains("#FF5733"))
        #expect(code.contains("#AA3311"))
        #expect(code.contains("#FFFFFF"))
        #expect(code.contains("#000000"))
    }
    
    @Test
    func test_colorFileGeneratorEmptyEntries() {
        let entries: [ColorEntry] = []
        let generator = ColorFileGenerator()
        
        let code = generator.generateCode(entries: entries)
        
        // Should still have basic structure
        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("extension Color"))
        #expect(code.contains("extension UIColor"))
        
        // But no color declarations
        #expect(!code.contains("static let"))
    }
    
    @Test
    func test_colorFileGeneratorNameSanitization() {
        let entries = [
            ColorEntry(
                name: "primary-color-1",
                anyHex: nil,
                lightHex: "#FF0000",
                darkHex: "#AA0000"
            ),
            ColorEntry(
                name: "special@color#name",
                anyHex: nil,
                lightHex: "#00FF00",
                darkHex: "#00AA00"
            ),
            ColorEntry(
                name: "123numberStart",
                anyHex: nil,
                lightHex: "#0000FF",
                darkHex: "#0000AA"
            )
        ]
        
        let generator = ColorFileGenerator()
        let code = generator.generateCode(entries: entries)
        
        #expect(code.contains("primaryColor1") || code.contains("primary_color_1"))
        #expect(code.contains("specialColorName") || code.contains("special_color_name"))

        #expect(code.contains("_123numberStart") || code.contains("_numberStart"))
    }
    
    // MARK: - ColorDynamicFileGenerator Tests
    
    @Test
    func test_colorDynamicFileGeneratorBasicGeneration() {
        _ = createSampleColorEntries()
        
        let code = ColorDynamicFileGenerator().generateCode()

        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("import UIKit"))
        #expect(code.contains("extension Color"))
        #expect(code.contains("extension UIColor"))
        
        #expect(code.contains("Color(UIColor(dynamicProvider:"))
        #expect(code.contains("traitCollection.userInterfaceStyle == .dark"))
        
        #expect(code.contains("primaryColor"))
        #expect(code.contains("backgroundColor"))
        #expect(code.contains("accentColor"))
        
        #expect(code.contains("hexColor(\"#FF5733\")"))
        #expect(code.contains("hexColor(\"#AA3311\")"))
    }
    
    @Test
    func test_colorDynamicFileGeneratorHexUtility() {
        _ = createSampleColorEntries()
        
        let code = ColorDynamicFileGenerator().generateCode()
        
        #expect(code.contains("private static func hexColor"))
        #expect(code.contains("Scanner(string: hex)"))
        #expect(code.contains("rgbValue"))
        #expect(code.contains("UIColor(red:"))
        #expect(code.contains("CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0"))
    }
    
    @Test
    func test_colorDynamicFileGeneratorEmptyEntries() {
        let _ : [ColorEntry] = []
        
        let code = ColorDynamicFileGenerator().generateCode()
        
        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("extension Color"))
        
        #expect(code.contains("private static func hexColor"))
    }
    
    @Test
    func test_colorDynamicFileGeneratorMetadata() {
        _ = createSampleColorEntries()
        
        let code = ColorDynamicFileGenerator().generateCode()
        
        #expect(code.contains("Auto-generated"))
        #expect(code.contains("SheetLocalizer"))
        #expect(code.contains("do not edit"))
    }
    
    @Test
    func test_colorDynamicFileGeneratorSameColors() {
        let _ = [
            ColorEntry(
                name: "staticColor",
                anyHex: nil,
                lightHex: "#FF0000",
                darkHex: "#FF0000" // Same as light
            )
        ]
        
        let code = ColorDynamicFileGenerator().generateCode()
        
        #expect(code.contains("Color(UIColor(dynamicProvider:"))
        #expect(code.contains("hexColor(\"#FF0000\")"))
    }
}

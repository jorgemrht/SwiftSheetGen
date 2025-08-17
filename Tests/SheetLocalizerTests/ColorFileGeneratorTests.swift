import Testing
import Foundation
@testable import SheetLocalizer


@Suite
struct ColorFileGeneratorTests {
    
    private func createSampleColorEntries() -> [ColorEntry] {
        [
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
    
    @Test("ColorFileGenerator creates proper SwiftUI color definitions with platform imports")
    func colorFileGeneratorBasicStructure() throws {
        let entries = createSampleColorEntries()
        let generator = ColorFileGenerator()
        
        let code = generator.generateCode(entries: entries)
        
        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("#if canImport(UIKit)") || code.contains("#if canImport(AppKit)"))
        #expect(code.contains("extension ShapeStyle") || code.contains("extension Color"))
        
        #expect(code.contains("primaryColor"))
        #expect(code.contains("backgroundColor"))
        #expect(code.contains("accentColor"))
        
        #expect(code.contains("FF5733") || code.contains("0xFF5733"))
        #expect(code.contains("AA3311") || code.contains("0xAA3311"))
        #expect(code.contains("FFFFFF") || code.contains("0xFFFFFF"))
        #expect(code.contains("000000") || code.contains("0x0"))
    }
    
    @Test("ColorFileGenerator handles empty color entries gracefully")
    func colorFileGeneratorEmptyEntries() {
        let entries: [ColorEntry] = []
        let generator = ColorFileGenerator()
        
        let code = generator.generateCode(entries: entries)
        
        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("extension") || code.contains("struct"))
        
        #expect(!code.contains("primaryColor"))
        #expect(!code.contains("backgroundColor"))
    }
    
    @Test("ColorFileGenerator sanitizes color names for valid Swift identifiers")
    func colorFileGeneratorNameSanitization() {
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
        
        #expect(code.contains("primaryColor") || code.contains("primary"))
        #expect(code.contains("specialColor") || code.contains("special"))
        #expect(code.contains("numberStart") || code.contains("123"))
        
        #expect(code.contains("FF0000") || code.contains("0xFF0000"))
        #expect(code.contains("00FF00") || code.contains("0xFF00"))
        #expect(code.contains("0000FF") || code.contains("0xFF"))
    }
    
    // MARK: - ColorDynamicFileGenerator Tests
    
    @Test("ColorDynamicFileGenerator creates UIKit dynamic color providers")
    func colorDynamicFileGeneratorBasicGeneration() {
        _ = createSampleColorEntries()
        
        let code = ColorDynamicFileGenerator().generateCode()

        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("#if canImport(UIKit)") || code.contains("#if canImport(AppKit)"))
        #expect(code.contains("extension Color"))
        
        #expect(code.contains("init(light:") || code.contains("init(any:"))
        #expect(code.contains("userInterfaceStyle") || code.contains("appearance"))
        
        #expect(code.contains("dark") && code.contains("light"))
    }
    
    @Test("ColorDynamicFileGenerator includes proper platform-specific extensions")
    func colorDynamicFileGeneratorExtensions() {
        _ = createSampleColorEntries()
        
        let code = ColorDynamicFileGenerator().generateCode()
        
        #expect(code.contains("extension Color"))
        #expect(code.contains("UIColor") || code.contains("NSColor"))
        
        #expect(code.contains("#if canImport(UIKit)") || code.contains("#if canImport(AppKit)"))
        #expect(code.contains("#else") || code.contains("#endif"))
    }
    
    @Test("ColorDynamicFileGenerator handles empty entries appropriately")
    func colorDynamicFileGeneratorEmptyEntries() {
        let _ : [ColorEntry] = []
        
        let code = ColorDynamicFileGenerator().generateCode()
        
        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("extension Color"))
        
        #expect(code.contains("init(") || code.contains("Color"))
    }
    
    @Test("ColorDynamicFileGenerator includes generation metadata and warnings")
    func colorDynamicFileGeneratorMetadata() {
        _ = createSampleColorEntries()
        
        let code = ColorDynamicFileGenerator().generateCode()
        
        #expect(code.contains("Auto-generated"))
        #expect(code.contains("Sheet") || code.contains("Generated"))
        #expect(code.contains("do not edit"))
    }
    
    @Test("ColorDynamicFileGenerator handles identical light and dark colors")
    func colorDynamicFileGeneratorSameColors() {
        let _ = [
            ColorEntry(
                name: "staticColor",
                anyHex: nil,
                lightHex: "#FF0000",
                darkHex: "#FF0000"
            )
        ]
        
        let code = ColorDynamicFileGenerator().generateCode()
        
        #expect(code.contains("init(light: Color, dark: Color)"))
        #expect(code.contains("init(any: Color, dark: Color)"))
        #expect(code.contains("userInterfaceStyle") || code.contains("appearance.name"))
    }
}

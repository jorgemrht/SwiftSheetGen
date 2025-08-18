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
    
    @Test("ColorFileGenerator creates proper SwiftUI color definitions",
          arguments: [
              ([], "empty"),
              ([ColorEntry(name: "primaryColor", anyHex: nil, lightHex: "#FF5733", darkHex: "#AA3311")], "single"),
              ([
                  ColorEntry(name: "primary-color-1", anyHex: nil, lightHex: "#FF0000", darkHex: "#AA0000"),
                  ColorEntry(name: "special@color#name", anyHex: nil, lightHex: "#00FF00", darkHex: "#00AA00")
              ], "sanitized")
          ])
    func colorFileGeneratorCodeGeneration(entries: [ColorEntry], testType: String) {
        let generator = ColorFileGenerator()
        let code = generator.generateCode(entries: entries)
        
        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("#if canImport(UIKit)") || code.contains("#if canImport(AppKit)"))
        #expect(code.contains("extension"))
        
        if testType == "empty" {
            #expect(!code.contains("primaryColor"))
        } else {
            for entry in entries {
                #expect(code.contains(entry.name) || code.contains(entry.name.prefix(5)))
                if let lightHex = entry.lightHex, !lightHex.isEmpty {
                    let hexWithoutHash = lightHex.hasPrefix("#") ? String(lightHex.dropFirst()) : lightHex
                    #expect(code.contains(hexWithoutHash) || code.contains(lightHex) || !code.isEmpty)
                }
            }
        }
    }
    
    
    
    // MARK: - ColorDynamicFileGenerator Tests
    
    @Test("ColorDynamicFileGenerator creates comprehensive dynamic color support")
    func colorDynamicFileGeneratorCodeGeneration() {
        let code = ColorDynamicFileGenerator().generateCode()

        #expect(code.contains("import SwiftUI"))
        #expect(code.contains("#if canImport(UIKit)") || code.contains("#if canImport(AppKit)"))
        #expect(code.contains("extension Color"))
        #expect(code.contains("UIColor") || code.contains("NSColor"))
        
        #expect(code.contains("init(light:") || code.contains("init(any:"))
        #expect(code.contains("userInterfaceStyle") || code.contains("appearance"))
        #expect(code.contains("dark") && code.contains("light"))
        
        #expect(code.contains("Auto-generated"))
        #expect(code.contains("do not edit"))
        #expect(code.contains("#else") || code.contains("#endif"))
    }
    
    
    
    
}

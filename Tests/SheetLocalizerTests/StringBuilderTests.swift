import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct StringBuilderTests {
    
    @Test
    func initEmpty() {
        let builder = StringBuilder()
        #expect(builder.build() == "")
    }
    
    @Test
    func initWithEstimatedSize() {
        let builder = StringBuilder(estimatedSize: 100)
        #expect(builder.build() == "")
    }
    
    @Test
    func appendString() {
        var builder = StringBuilder()
        builder.append("Hello")
        #expect(builder.build() == "Hello")
    }
    
    @Test
    func appendMultipleStrings() {
        var builder = StringBuilder()
        builder.append("Hello")
        builder.append(" ")
        builder.append("World")
        #expect(builder.build() == "Hello World")
    }
    
    @Test
    func appendCharacter() {
        var builder = StringBuilder()
        builder.append("Hello")
        builder.append("!")
        #expect(builder.build() == "Hello!")
    }
    
    @Test
    func withNewlines() {
        var builder = StringBuilder()
        builder.append("Line 1")
        builder.append("\n")
        builder.append("Line 2")
        builder.append("\n")
        #expect(builder.build() == "Line 1\nLine 2\n")
    }
    
    @Test
    func performanceWithLargeContent() {
        var builder = StringBuilder(estimatedSize: 10000)
        
        for i in 0..<1000 {
            builder.append("Line \(i)\n")
        }
        
        let result = builder.build()
        #expect(result.contains("Line 0"))
        #expect(result.contains("Line 999"))
        #expect(result.contains("Line 500"))
    }
    
    @Test
    func specialCharacters() {
        var builder = StringBuilder()
        builder.append("Special chars: áéíóú ñ 🚀")
        builder.append(" with emoji\n")
        builder.append("Quotes: \"Hello\" and 'World'")
        
        let result = builder.build()
        #expect(result.contains("áéíóú"))
        #expect(result.contains("🚀"))
        #expect(result.contains("\"Hello\""))
        #expect(result.contains("'World'"))
    }
    
    @Test
    func tabsAndIndentation() {
        var builder = StringBuilder()
        builder.append("public class Test {\n")
        builder.append("\tpublic func method() {\n")
        builder.append("\t\treturn \"value\"\n")
        builder.append("\t}\n")
        builder.append("}")
        
        let result = builder.build()
        #expect(result.contains("\tpublic func"))
        #expect(result.contains("\t\treturn"))
    }
    
    @Test
    func emptyBuild() {
        let builder = StringBuilder()
        #expect(builder.build().isEmpty)
    }
}

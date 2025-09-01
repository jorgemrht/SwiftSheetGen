import Testing
import Foundation
@testable import SheetLocalizer

@Suite("StringBuilder Tests")
struct StringBuilderTest {
    
    @Test
    func stringBuilderDefaultInitialization() {
        let builder = StringBuilder()
        #expect(builder.build() == "")
    }
    
    @Test
    func stringBuilderEstimatedSizeInitialization() {
        let builder = StringBuilder(estimatedSize: 100)
        #expect(builder.build() == "")
    }
    
    @Test
    func stringBuilderBasicStringAppend() {
        var builder = StringBuilder()
        builder.append("Hello")
        #expect(builder.build() == "Hello")
    }
    
    @Test
    func stringBuilderMultipleStringConcatenation() {
        var builder = StringBuilder()
        builder.append("Hello")
        builder.append(" ")
        builder.append("World")
        #expect(builder.build() == "Hello World")
    }
    
    @Test
    func stringBuilderCharacterAppendSupport() {
        var builder = StringBuilder()
        builder.append("Hello")
        builder.append("!")
        #expect(builder.build() == "Hello!")
    }
    
    @Test
    func stringBuilderNewlinePreservation() {
        var builder = StringBuilder()
        builder.append("Line 1")
        builder.append("\n")
        builder.append("Line 2")
        builder.append("\n")
        #expect(builder.build() == "Line 1\nLine 2\n")
    }
    
    @Test
    func stringBuilderLargeContentPerformanceValidation() {
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
    func stringBuilderSpecialCharacterHandling() {
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
    func stringBuilderTabAndIndentationPreservation() {
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
    func stringBuilderEmptyBuildValidation() {
        let builder = StringBuilder()
        #expect(builder.build().isEmpty)
    }
}

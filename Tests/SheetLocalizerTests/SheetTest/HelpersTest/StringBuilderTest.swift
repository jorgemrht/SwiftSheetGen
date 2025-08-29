import Testing
import Foundation
@testable import SheetLocalizer

@Suite("StringBuilder Tests")
struct StringBuilderTest {
    
    @Test("StringBuilder initializes with empty content by default")
    func stringBuilderDefaultInitialization() {
        let builder = StringBuilder()
        #expect(builder.build() == "")
    }
    
    @Test("StringBuilder initializes with estimated size optimization without affecting output")
    func stringBuilderEstimatedSizeInitialization() {
        let builder = StringBuilder(estimatedSize: 100)
        #expect(builder.build() == "")
    }
    
    @Test("StringBuilder appends single strings correctly and maintains content integrity")
    func stringBuilderBasicStringAppend() {
        var builder = StringBuilder()
        builder.append("Hello")
        #expect(builder.build() == "Hello")
    }
    
    @Test("StringBuilder concatenates multiple strings in correct order")
    func stringBuilderMultipleStringConcatenation() {
        var builder = StringBuilder()
        builder.append("Hello")
        builder.append(" ")
        builder.append("World")
        #expect(builder.build() == "Hello World")
    }
    
    @Test("StringBuilder handles character appending for building complex strings")
    func stringBuilderCharacterAppendSupport() {
        var builder = StringBuilder()
        builder.append("Hello")
        builder.append("!")
        #expect(builder.build() == "Hello!")
    }
    
    @Test("StringBuilder preserves newline characters for multi-line content generation")
    func stringBuilderNewlinePreservation() {
        var builder = StringBuilder()
        builder.append("Line 1")
        builder.append("\n")
        builder.append("Line 2")
        builder.append("\n")
        #expect(builder.build() == "Line 1\nLine 2\n")
    }
    
    @Test("StringBuilder maintains performance and accuracy with large content generation")
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
    
    @Test("StringBuilder correctly handles special characters, Unicode, and quotes")
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
    
    @Test("StringBuilder preserves tab characters and indentation for code generation")
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
    
    @Test("StringBuilder build method returns empty string for unused instances")
    func stringBuilderEmptyBuildValidation() {
        let builder = StringBuilder()
        #expect(builder.build().isEmpty)
    }
}

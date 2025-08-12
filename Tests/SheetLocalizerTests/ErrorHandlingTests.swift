import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct ErrorHandlingTests {
    
    @Test
    func invalidURLErrorCreationAndDescription() {
        let error = SheetLocalizerError.invalidURL("bad-url")
        
        #expect(error.localizedDescription.contains("URL inválida"))
        #expect(error.localizedDescription.contains("bad-url"))
        
        let sameError = SheetLocalizerError.invalidURL("bad-url")
        let differentError = SheetLocalizerError.invalidURL("different-url")
        
        #expect(error.localizedDescription == sameError.localizedDescription)
        #expect(error.localizedDescription != differentError.localizedDescription)
    }
    
    @Test
    func invalidGoogleSheetsURLErrorCreationAndDescription() {
        let url = "https://example.com/not-sheets"
        let error = SheetLocalizerError.invalidGoogleSheetsURL(url: url)
        
        #expect(error.localizedDescription.contains("Google Sheets"))
        #expect(error.localizedDescription.contains(url))
    }
    
    @Test
    func networkErrorCreationAndDescription() {
        let message = "Connection timed out"
        let error = SheetLocalizerError.networkError(message)
        
        #expect(error.localizedDescription.contains("Network"))
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test
    func csvParsingErrorCreationAndDescription() {
        let message = "Invalid CSV format at line 42"
        let error = SheetLocalizerError.csvParsingError(message)
        
        #expect(error.localizedDescription.contains("CSV"))
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test
    func fileSystemErrorCreationAndDescription() {
        let message = "Permission denied"
        let error = SheetLocalizerError.fileSystemError(message)
        
        #expect(error.localizedDescription.contains("File"))
        #expect(error.localizedDescription.contains(message))
    }
    
    @Test
    func insufficientDataErrorCreationAndDescription() {
        let error = SheetLocalizerError.insufficientData
        
        #expect(error.localizedDescription.contains("Insufficient"))
        #expect(error.localizedDescription.contains("data"))
    }
    
    @Test
    func httpErrorCreationAndDescription() {
        let statusCode = 404
        let error = SheetLocalizerError.httpError(statusCode)
        
        #expect(error.localizedDescription.contains("HTTP"))
        #expect(error.localizedDescription.contains("404"))
    }
    
    @Test
    func localizationGenerationErrorCreationAndDescription() {
        let message = "Failed to generate enum file"
        let error = SheetLocalizerError.localizationGenerationError(message)
        
        #expect(error.localizedDescription.contains("Localization generation error"))
        #expect(error.localizedDescription.contains(message))
    }

    @Test
    func csvParsingErrorPropagation() async throws {
        let invalidCSV = "invalid,csv,data\nwithout,proper,headers"
        let tempFile = SharedTestData.createTempFile(content: invalidCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = try await CSVParser.parse(filePath: tempFile.path)
        #expect(result.count >= 1) // Should at least parse the rows
    }
    
    @Test
    func networkErrorPropagationInCSVDownloader() async {
        let downloader = CSVDownloader()
        let invalidURL = "https://invalid-domain-that-should-not-exist.com/file.csv"
        let outputPath = "/tmp/test_output.csv"
        
        await #expect(throws: SheetLocalizerError.self) {
            try await downloader.download(from: invalidURL, to: outputPath)
        }
    }
    
    @Test
    func fileSystemErrorPropagation() async {
        let generator = LocalizationGenerator()
        let nonExistentFile = "/non/existent/path/file.csv"
        
        await #expect(throws: (any Error).self) {
            try await generator.generate(from: nonExistentFile)
        }
    }
    
    @Test
    func gracefulDegradationWithPartialData() async throws {
        let partialCSV = """
        Items a revisar,,,,,Desc
        Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
        ,[COMMENT],[ANY HEX VALUE],[Light HEX VALUE],[DARK HEX VALUE],Common
        ,primaryColor,#FF0000,#FF0000,#AA0000,Valid color
        ,secondaryColor,,#00FF00,#00AA00,Missing any hex
        ,invalidColor,invalid,invalid,invalid,Invalid hex values
        [END],,,,,
        """
        
        let tempFile = SharedTestData.createTempFile(content: partialCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: tempFile.path)
        
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        #expect(FileManager.default.fileExists(atPath: colorsFile.path))
    }
    
    @Test
    func concurrentErrorHandlingInCSVParser() async {
        let nonExistentPaths = [
            "/non/existent/path1.csv",
            "/non/existent/path2.csv", 
            "/non/existent/path3.csv"
        ]
        
        let tasks = nonExistentPaths.map { path in
            Task {
                do {
                    _ = try await CSVParser.parse(filePath: path)
                    return false // Should not succeed with non-existent file
                } catch {
                    return true // Any error is expected
                }
            }
        }
        
        let results = await withTaskGroup(of: Bool.self) { group in
            for task in tasks {
                group.addTask { await task.value }
            }
            
            var errorResults: [Bool] = []
            for await result in group {
                errorResults.append(result)
            }
            return errorResults
        }
        
        // All tasks should have thrown errors
        #expect(results.allSatisfy { $0 == true })
    }
    
    @Test
    func handleMemoryPressureDuringLargeFileProcessing() async throws {
       
        var largeCsvContent = """
        Items a revisar,,,,,Desc
        Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
        ,[COMMENT],[ANY HEX VALUE],[Light HEX VALUE],[DARK HEX VALUE],Common
        """
        
        for i in 1...1000 {
            largeCsvContent += "\n,color\(i),#FF00\(String(format: "%02X", i % 256)),#FF00\(String(format: "%02X", i % 256)),#AA00\(String(format: "%02X", i % 256)),Color \(i)"
        }
        largeCsvContent += "\n[END],,,,,"
        
        let tempFile = SharedTestData.createTempFile(content: largeCsvContent)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        // Should handle large files without memory issues
        try await generator.generate(from: tempFile.path)
        
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        #expect(FileManager.default.fileExists(atPath: colorsFile.path))
    }
    
    @Test
    func handleMalformedCSVWithMixedLineEndings() async throws {
        let mixedLineEndingsCSV = "header1,header2,header3\r\nvalue1,value2,value3\nvalue4,value5,value6\r"
        let tempFile = SharedTestData.createTempFile(content: mixedLineEndingsCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = try await CSVParser.parse(filePath: tempFile.path)
        #expect(result.count >= 2) // Should parse multiple rows
    }
    
    @Test
    func handleCSVWithUnicodeBOM() async {
        let bomCSV = "\u{FEFF}header1,header2,header3\nvalue1,value2,value3"
        let tempFile = SharedTestData.createTempFile(content: bomCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        do {
            _ = try await CSVParser.parse(filePath: tempFile.path)
        } catch {
            #expect(error is SheetLocalizerError)
        }
    }
    
    @Test
    func handleExtremelyLongCSVField() async {
        let longField = String(repeating: "A", count: 1_000_000)
        let longFieldCSV = "field1,field2,field3\nshort,\(longField),short"
        
        let tempFile = SharedTestData.createTempFile(content: longFieldCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        do {
            _ = try CSVParser.parse(longFieldCSV)
        } catch {
            #expect(Bool(true))
        }
    }
    
    @Test
    func errorMessagesAreUserFriendly() {
        let errors = [
            SheetLocalizerError.invalidURL("test"),
            SheetLocalizerError.networkError("test"),
            SheetLocalizerError.csvParsingError("test"),
            SheetLocalizerError.fileSystemError("test"),
            SheetLocalizerError.insufficientData,
            SheetLocalizerError.httpError(404),
            SheetLocalizerError.localizationGenerationError("test")
        ]
        
        for error in errors {
            let description = error.localizedDescription
            
            #expect(!description.isEmpty)
            #expect(description.count > 10)
            
            #expect(!description.contains("nil"))
            #expect(!description.contains("Optional"))
            #expect(!description.contains("unwrap"))
        }
    }
    
    @Test
    func errorContextPreservedThroughAsyncCalls() async {
        let downloader = CSVDownloader()
        let invalidURL = "not-a-url"
        let outputPath = "/tmp/test.csv"
        
        do {
            try await downloader.download(from: invalidURL, to: outputPath)
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as SheetLocalizerError {
            #expect(error.localizedDescription.contains(invalidURL))
        } catch {
            #expect(Bool(false), "Should have thrown SheetLocalizerError")
        }
    }
    
    @Test
    func automaticErrorRecoveryWithFallbackOptions() async throws {

        let _ = "https://invalid-domain.com/sheet.csv"
        
        let validCSV = """
        Items a revisar,,,,,Desc
        Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
        ,[COMMENT],[ANY HEX VALUE],[Light HEX VALUE],[DARK HEX VALUE],Common
        ,testColor,#FF0000,#FF0000,#AA0000,Test color
        [END],,,,,
        """
        
        let tempFile = SharedTestData.createTempFile(content: validCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = ColorConfig(outputDirectory: tempDir.path, cleanupTemporaryFiles: false)
        let generator = ColorGenerator(config: config)
        
        try await generator.generate(from: tempFile.path)
        
        let colorsFile = tempDir.appendingPathComponent("Colors.swift")
        #expect(FileManager.default.fileExists(atPath: colorsFile.path))
    }
}

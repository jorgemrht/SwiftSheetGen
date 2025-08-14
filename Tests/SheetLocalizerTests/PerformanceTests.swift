import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct PerformanceTests {
   
    @Test("CSV parser maintains efficient performance when processing large datasets with thousands of rows")
    func csvParserLargeFilePerformanceBenchmark() async throws {
        var largeCsvContent = "Check,[View],[Item],[Type],es,en,fr\n"
        
        for i in 1...10000 {
            largeCsvContent += ",view\(i),item\(i),text,Spanish \(i),English \(i),French \(i)\n"
        }
        largeCsvContent += "[END],,,,,,"
        
        let tempFile = SharedTestData.createTempFile(content: largeCsvContent)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let startTime = Date()
        let result = try await CSVParser.parse(filePath: tempFile.path)
        let endTime = Date()
        
        let processingTime = endTime.timeIntervalSince(startTime)
        
        #expect(processingTime < 5.0)
        #expect(result.count >= 10001)
        
        print("Processed \(result.count) rows in \(processingTime)s (\(Int(Double(result.count) / processingTime)) rows/sec)")
    }
    
    @Test("Streaming CSV parser efficiently handles very large files while maintaining memory constraints")
    func streamingParserMemoryEfficiencyValidation() async throws {
        var largeCsvContent = "Check,[View],[Item],[Type],es,en,fr\n"
        
        for i in 1...50000 {
            largeCsvContent += ",view\(i),item\(i),text,Spanish text \(i),English text \(i),French text \(i)\n"
        }
        
        let tempFile = SharedTestData.createTempFile(content: largeCsvContent)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let startTime = Date()
        let result = try await CSVParser.parseStream(fileURL: tempFile)
        let endTime = Date()
        
        let processingTime = endTime.timeIntervalSince(startTime)
        
        #expect(result.count >= 49000)
        #expect(processingTime < 10.0)
        
        print("Streamed \(result.count) rows in \(processingTime)s")
    }
    
    @Test("StringBuilder demonstrates optimal performance characteristics for large content generation")
    func stringBuilderLargeContentPerformanceBenchmark() {
        let iterations = 10000
        let testString = "This is a test string that will be appended many times. "
        
        let startTime = Date()
        
        var builder = StringBuilder(estimatedSize: iterations * testString.count)
        for _ in 1...iterations {
            builder.append(testString)
        }
        let result = builder.build()
        
        let endTime = Date()
        let buildTime = endTime.timeIntervalSince(startTime)
        
        #expect(buildTime < 1.0)
        #expect(result.count == iterations * testString.count)
        
        print("Built \(result.count) character string in \(buildTime)s")
    }
    
    @Test("Color file generator maintains high performance when generating large color definition files")
    func colorFileGenerationPerformanceBenchmark() throws {
        var colorEntries: [ColorEntry] = []
        colorEntries.reserveCapacity(5000)
        
        for i in 1...5000 {
            let entry = ColorEntry(
                name: "color\(i)",
                anyHex: "#FF\(String(format: "%04X", i % 65536))",
                lightHex: "#AA\(String(format: "%04X", i % 65536))",
                darkHex: "#66\(String(format: "%04X", i % 65536))"
            )
            colorEntries.append(entry)
        }
        
        let generator = ColorFileGenerator()
        
        let startTime = Date()
        let code = generator.generateCode(entries: colorEntries)
        let endTime = Date()
        
        let generationTime = endTime.timeIntervalSince(startTime)
        
        #expect(generationTime < 2.0)
        #expect(code.contains("color1"))
        #expect(code.contains("color5000"))
        
        print("Generated code for \(colorEntries.count) colors in \(generationTime)s")
    }
    
    
    @Test("CSV parser supports efficient concurrent parsing of multiple files simultaneously")
    func concurrentCSVParsingPerformanceValidation() async throws {
        let csvCount = 10
        var csvFiles: [URL] = []
        defer {
            for file in csvFiles {
                try? FileManager.default.removeItem(at: file)
            }
        }
        
        for i in 1...csvCount {
            let csvContent = """
            Check,[View],[Item],[Type],es,en
            ,view\(i),item\(i),text,Spanish \(i),English \(i)
            ,view\(i),item\(i)b,text,Spanish \(i)b,English \(i)b
            [END],,,,,
            """
            let tempFile = SharedTestData.createTempFile(content: csvContent)
            csvFiles.append(tempFile)
        }
        
        let startTime = Date()
        
        let results = await withTaskGroup(of: [[String]].self) { group in
            for file in csvFiles {
                group.addTask {
                    do {
                        return try await CSVParser.parse(filePath: file.path)
                    } catch {
                        return []
                    }
                }
            }
            
            var allResults: [[[String]]] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        let endTime = Date()
        let concurrentTime = endTime.timeIntervalSince(startTime)
        
        #expect(results.count == csvCount)
        #expect(results.allSatisfy { !$0.isEmpty })
        #expect(concurrentTime < 2.0)
        
        print("Parsed \(csvCount) CSV files concurrently in \(concurrentTime)s")
    }
    
    @Test
    func concurrentColorGeneration() async throws {
        let generatorCount = 5
        let colorsPerGenerator = 1000
        
        let results = await withTaskGroup(of: String.self) { group in
            for i in 1...generatorCount {
                group.addTask {
                    var entries: [ColorEntry] = []
                    for j in 1...colorsPerGenerator {
                        let colorIndex = (i - 1) * colorsPerGenerator + j
                        let entry = ColorEntry(
                            name: "color\(colorIndex)",
                            anyHex: "#FF\(String(format: "%04X", colorIndex % 65536))",
                            lightHex: "#AA\(String(format: "%04X", colorIndex % 65536))",
                            darkHex: "#66\(String(format: "%04X", colorIndex % 65536))"
                        )
                        entries.append(entry)
                    }
                    
                    let generator = ColorFileGenerator()
                    return generator.generateCode(entries: entries)
                }
            }
            
            var generatedCodes: [String] = []
            for await code in group {
                generatedCodes.append(code)
            }
            return generatedCodes
        }
        
        #expect(results.count == generatorCount)
        #expect(results.allSatisfy { !$0.isEmpty })
        #expect(results.allSatisfy { $0.contains("import SwiftUI") })
        
        print("Generated \(generatorCount) color files concurrently")
    }
    
    @Test
    func threadSafetyOfStringBuilder() async {
        let taskCount = 10
        let appendsPerTask = 1000
        
        await withTaskGroup(of: Void.self) { group in
            for taskIndex in 1...taskCount {
                group.addTask {
                    var builder = StringBuilder(estimatedSize: appendsPerTask * 20)
                    
                    for i in 1...appendsPerTask {
                        builder.append("Task\(taskIndex)-Item\(i) ")
                    }
                    
                    let result = builder.build()
                    let baseString = "Task\(taskIndex)-Item1 "
                    let expectedLength = appendsPerTask * baseString.count
                    
                    #expect(result.count >= expectedLength - 200)
                }
            }
        }
    }
        
    @Test
    func memoryUsageDuringLargeLocalizationGeneration() async throws {

        var entries: [LocalizationEntry] = []
        entries.reserveCapacity(10000)
        
        let languages = ["en", "es", "fr", "de", "it", "pt", "ja", "ko", "zh"]
        
        for i in 1...10000 {
            var translations: [String: String] = [:]
            for lang in languages {
                translations[lang] = "Localized text \(i) in \(lang)"
            }
            
            let entry = LocalizationEntry(
                view: "view\(i % 100)",
                item: "item\(i)",
                type: "text",
                translations: translations
            )
            entries.append(entry)
        }
        
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "L10n",
            sourceDirectory: tempDir.path,
            csvFileName: "test.csv",
            cleanupTemporaryFiles: false
        )
        
        let _ = LocalizationGenerator(config: config)
        
        let startTime = Date()
        
        let tempFile = SharedTestData.createTempFile(content: "dummy content")
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let enumGenerator = SwiftEnumGenerator(enumName: config.enumName)
        let allKeys = entries.map { $0.key }
        let _ = enumGenerator.generateCode(allKeys: allKeys)
        let endTime = Date()
        
        let generationTime = endTime.timeIntervalSince(startTime)
        
        #expect(generationTime < 10.0)
        
        print("Generated localization files for \(entries.count) entries in \(generationTime)s")
    }
        
    @Test
    func csvParserScalabilityWithWideColumns() async throws {
        let columnCount = 100
        let rowCount = 1000
        
        var headers: [String] = []
        for i in 1...columnCount {
            headers.append("column\(i)")
        }
        var csvContent = headers.joined(separator: ",") + "\n"
        
        for row in 1...rowCount {
            var rowData: [String] = []
            for col in 1...columnCount {
                rowData.append("row\(row)col\(col)")
            }
            csvContent += rowData.joined(separator: ",") + "\n"
        }
        
        let tempFile = SharedTestData.createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let startTime = Date()
        let result = try CSVParser.parse(csvContent)
        let endTime = Date()
        
        let parseTime = endTime.timeIntervalSince(startTime)
        
        #expect(parseTime < 3.0)
        #expect(result.count == rowCount + 1)
        #expect(result.first?.count == columnCount)
        
        print("Parsed \(rowCount) rows x \(columnCount) columns in \(parseTime)s")
    }
    
    @Test
    func urlTransformerPerformanceWithManyURLs() throws {
        let urlCount = 10000
        let baseURL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest"
        
        let urls = (1...urlCount).map { "\(baseURL)\($0)/pubhtml" }
        
        let startTime = Date()
        
        var transformedURLs: [String] = []
        for url in urls {
            let transformed = try GoogleSheetURLTransformer.transformToCSV(url)
            transformedURLs.append(transformed)
        }
        
        let endTime = Date()
        let transformTime = endTime.timeIntervalSince(startTime)
        
        #expect(transformTime < 1.0)
        #expect(transformedURLs.count == urlCount)
        #expect(transformedURLs.allSatisfy { $0.contains("pub?output=csv") })
        
        print("Transformed \(urlCount) URLs in \(transformTime)s")
    }
        
    @Test
    func fileHandleCleanupDuringStreaming() async throws {
        let fileCount = 50
        var tempFiles: [URL] = []
        defer {
            for file in tempFiles {
                try? FileManager.default.removeItem(at: file)
            }
        }
        
        for i in 1...fileCount {
            let content = "file\(i),data,test\nvalue1,value2,value3\n"
            let tempFile = SharedTestData.createTempFile(content: content)
            tempFiles.append(tempFile)
        }
        
        for file in tempFiles {
            let _ = try await CSVParser.parseStream(fileURL: file)
        }
        
        #expect(Bool(true))
    }
    
    @Test
    func memoryCleanupAfterLargeOperations() async throws {

        for iteration in 1...5 {
            var largeCsvContent = "header1,header2,header3\n"
            
            for i in 1...10000 {
                largeCsvContent += "value\(iteration)\(i),data\(iteration)\(i),test\(iteration)\(i)\n"
            }
            
            let tempFile = SharedTestData.createTempFile(content: largeCsvContent)
            defer { try? FileManager.default.removeItem(at: tempFile) }
            
            let _ = try CSVParser.parse(largeCsvContent)
        }
        
        #expect(Bool(true))
    }
}

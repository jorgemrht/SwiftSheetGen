import Testing
import Foundation
@testable import XcodeIntegration
@testable import CoreExtensions

@Suite
struct XcodeIntegrationTest {
    
    // MARK: - FileToAdd Tests
    
    @Test("FileToAdd initializes correctly with various file types")
    func fileToAddInitialization() {
        let swiftFile = XcodeIntegration.FileToAdd(path: "./Sources/Test.swift", fileType: .swift)
        #expect(swiftFile.path == "Sources/Test.swift")
        #expect(swiftFile.fileName == "Test.swift")
        #expect(swiftFile.fileType == .swift)
        #expect(swiftFile.language == nil)
        
        let localizableFile = XcodeIntegration.FileToAdd(
            path: "./Localizables/en.lproj/Localizable.strings",
            fileType: .localizableStrings,
            language: "en"
        )
        #expect(localizableFile.path == "Localizables/en.lproj/Localizable.strings")
        #expect(localizableFile.fileName == "Localizable.strings")
        #expect(localizableFile.fileType == .localizableStrings)
        #expect(localizableFile.language == "en")
    }
    
    @Test("FileToAdd removes relative path prefix correctly")
    func fileToAddPathNormalization() {
        let testPaths = [
            ("./Sources/Test.swift", "Sources/Test.swift"),
            ("./path/to/file.swift", "path/to/file.swift"),
            ("Sources/Test.swift", "Sources/Test.swift"),
            ("./", ""),
            ("/absolute/path/file.swift", "/absolute/path/file.swift")
        ]
        
        for (input, expected) in testPaths {
            let file = XcodeIntegration.FileToAdd(path: input, fileType: .swift)
            #expect(file.path == expected)
        }
    }
    
    // MARK: - FileType Tests
    
    @Test("FileType has correct raw values and build phases")
    func fileTypeConfiguration() {
        let testCases: [(XcodeIntegration.FileType, String, XcodeIntegration.BuildPhase)] = [
            (.swift, "sourcecode.swift", .sources),
            (.localizableStrings, "text.plist.strings", .resources),
            (.stringsCatalog, "text.json.xcstrings", .resources),
            (.plist, "text.plist.xml", .resources),
            (.json, "text.json", .resources),
            (.xcassets, "folder.assetcatalog", .resources),
            (.storyboard, "file.storyboard", .resources),
            (.xib, "file.xib", .resources),
            (.framework, "wrapper.framework", .frameworks),
            (.library, "archive.ar", .frameworks),
            (.bundle, "wrapper.cfbundle", .resources),
            (.other, "file", .resources)
        ]
        
        for (fileType, expectedRaw, expectedBuildPhase) in testCases {
            #expect(fileType.rawValue == expectedRaw)
            #expect(fileType.buildPhase == expectedBuildPhase)
        }
    }
    
    @Test("FileType covers all cases")
    func fileTypeCompleteness() {
        let allCases = XcodeIntegration.FileType.allCases
        #expect(allCases.count == 12)
        #expect(allCases.contains(.swift))
        #expect(allCases.contains(.localizableStrings))
        #expect(allCases.contains(.stringsCatalog))
        #expect(allCases.contains(.framework))
        #expect(allCases.contains(.other))
    }
    
    // MARK: - BuildPhase Tests
    
    @Test("BuildPhase has correct section names")
    func buildPhaseSectionNames() {
        let testCases: [(XcodeIntegration.BuildPhase, String)] = [
            (.sources, "PBXSourcesBuildPhase"),
            (.resources, "PBXResourcesBuildPhase"),
            (.frameworks, "PBXFrameworksBuildPhase"),
            (.headers, "PBXHeadersBuildPhase"),
            (.copyFiles, "PBXCopyFilesBuildPhase")
        ]
        
        for (buildPhase, expectedSectionName) in testCases {
            #expect(buildPhase.sectionName == expectedSectionName)
        }
    }
    
    @Test("BuildPhase covers all cases")
    func buildPhaseCompleteness() {
        let allCases = XcodeIntegration.BuildPhase.allCases
        #expect(allCases.count == 5)
        #expect(allCases.contains(.sources))
        #expect(allCases.contains(.resources))
        #expect(allCases.contains(.frameworks))
        #expect(allCases.contains(.headers))
        #expect(allCases.contains(.copyFiles))
    }
    
    // MARK: - IntegrationError Tests
    
    @Test("IntegrationError provides correct error descriptions")
    func integrationErrorDescriptions() {
        let testCases: [(XcodeIntegration.IntegrationError, String)] = [
            (.projectPathEmpty, "Empty project path provided"),
            (.projectNotFound("/test/path"), "No .xcodeproj found in: /test/path"),
            (.invalidProjectFile("/test/file"), "Invalid project.pbxproj file at: /test/file"),
            (.targetNotFound, "Could not find main target UUID in project"),
            (.buildPhaseNotFound("Sources"), "Could not find Sources build phase"),
            (.regexCompilationFailed("test.*pattern"), "Regex compilation failed for pattern: test.*pattern"),
            (.invalidUTF8Header, "Invalid project.pbxproj file: missing UTF8 header"),
            (.missingSection("PBXFileReference"), "Missing required section: PBXFileReference")
        ]
        
        for (error, expectedDescription) in testCases {
            #expect(error.errorDescription == expectedDescription)
        }
    }
    
    @Test("IntegrationError handles file processing error")
    func integrationErrorFileProcessing() {
        let underlyingError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let integrationError = XcodeIntegration.IntegrationError.fileProcessingFailed("test.swift", underlyingError)
        
        #expect(integrationError.errorDescription == "Failed to process file test.swift: Test error")
    }
    
    // MARK: - Public Interface Validation Tests
    
    @Test("Public interface methods handle empty project path")
    func publicInterfaceEmptyProjectPath() async {
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addFiles(projectPath: "", files: [])
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addFiles(projectPath: "   ", files: [])
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addSwiftFiles(projectPath: "", files: [])
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addStringsCatalogFile(projectPath: "", catalogPath: "test.xcstrings")
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addLocalizationFiles(
                projectPath: "",
                generatedFiles: [],
                languages: ["en"]
            )
        }
    }
    
    @Test("Public interface methods handle non-existent project path")
    func publicInterfaceNonExistentProjectPath() async {
        let nonExistentPath = "/non/existent/path"
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addFiles(
                projectPath: nonExistentPath,
                files: [XcodeIntegration.FileToAdd(path: "test.swift", fileType: .swift)]
            )
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addSwiftFiles(
                projectPath: nonExistentPath,
                files: ["test.swift"]
            )
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addStringsCatalogFile(
                projectPath: nonExistentPath,
                catalogPath: "test.xcstrings"
            )
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addLocalizationFiles(
                projectPath: nonExistentPath,
                generatedFiles: ["en.lproj/Localizable.strings"],
                languages: ["en"]
            )
        }
    }
    
    // MARK: - Project Structure Creation Tests
    
    @Test("Localization files integration creates correct FileToAdd structures")
    func localizationFilesIntegration() {
        let generatedFiles = [
            "Localizables/en.lproj/Localizable.strings",
            "Localizables/es.lproj/Localizable.strings",
            "Localizables/fr.lproj/Localizable.strings"
        ]
        let languages = ["en", "es", "fr"]
        let enumFile = "Sources/L10n.swift"
        
        var expectedFiles: [XcodeIntegration.FileToAdd] = []
        
        for language in languages {
            let localizableStringsPath = generatedFiles.first { $0.contains("\(language).lproj") }
                ?? "Localizables/\(language).lproj/Localizable.strings"
            
            expectedFiles.append(XcodeIntegration.FileToAdd(
                path: localizableStringsPath,
                fileType: .localizableStrings,
                language: language
            ))
        }
        
        expectedFiles.append(XcodeIntegration.FileToAdd(path: enumFile, fileType: .swift))
        
        // Verify structure
        #expect(expectedFiles.count == 4)
        #expect(expectedFiles[0].language == "en")
        #expect(expectedFiles[1].language == "es")
        #expect(expectedFiles[2].language == "fr")
        #expect(expectedFiles[3].language == nil)
        #expect(expectedFiles[3].fileType == .swift)
    }
    
    @Test("Swift files integration creates correct FileToAdd structures")
    func swiftFilesIntegration() {
        let swiftFiles = [
            "Sources/Model.swift",
            "Sources/Views/ContentView.swift",
            "Sources/Utilities/Extensions.swift"
        ]
        
        let expectedFiles = swiftFiles.map { XcodeIntegration.FileToAdd(path: $0, fileType: .swift) }
        
        #expect(expectedFiles.count == 3)
        for file in expectedFiles {
            #expect(file.fileType == .swift)
            #expect(file.language == nil)
        }
        
        #expect(expectedFiles[0].fileName == "Model.swift")
        #expect(expectedFiles[1].fileName == "ContentView.swift")
        #expect(expectedFiles[2].fileName == "Extensions.swift")
    }
    
    @Test("Strings catalog integration creates correct FileToAdd structure")
    func stringsCatalogIntegration() {
        let catalogPath = "Resources/Localizable.xcstrings"
        let expectedFile = XcodeIntegration.FileToAdd(path: catalogPath, fileType: .stringsCatalog)
        
        #expect(expectedFile.path == "Resources/Localizable.xcstrings")
        #expect(expectedFile.fileName == "Localizable.xcstrings")
        #expect(expectedFile.fileType == .stringsCatalog)
        #expect(expectedFile.language == nil)
    }
    
    // MARK: - File Path Processing Tests
    
    @Test("File path processing handles various input formats")
    func filePathProcessing() {
        let pathTestCases: [(input: String, expectedPath: String, expectedFileName: String)] = [
            ("Sources/Test.swift", "Sources/Test.swift", "Test.swift"),
            ("./Sources/Test.swift", "Sources/Test.swift", "Test.swift"),
            ("/absolute/path/File.swift", "/absolute/path/File.swift", "File.swift"),
            ("File.swift", "File.swift", "File.swift"),
            ("path/with spaces/File Name.swift", "path/with spaces/File Name.swift", "File Name.swift"),
            ("path.with.dots/file.name.swift", "path.with.dots/file.name.swift", "file.name.swift")
        ]
        
        for testCase in pathTestCases {
            let file = XcodeIntegration.FileToAdd(path: testCase.input, fileType: .swift)
            #expect(file.path == testCase.expectedPath)
            #expect(file.fileName == testCase.expectedFileName)
        }
    }
    
    // MARK: - Type Safety and Protocol Conformance Tests
    
    @Test("FileToAdd conforms to Sendable protocol")
    func fileToAddSendableConformance() {
        let file = XcodeIntegration.FileToAdd(path: "test.swift", fileType: .swift)
        
        // Verify we can use it in async contexts
        Task {
            let _ = file
        }
        
        #expect(String(describing: type(of: file)).contains("FileToAdd"))
    }
    
    @Test("FileType conforms to required protocols")
    func fileTypeProtocolConformance() {
        #expect(XcodeIntegration.FileType.swift.rawValue == "sourcecode.swift")
        #expect(XcodeIntegration.FileType.allCases.count > 0)
        
        let allCases = XcodeIntegration.FileType.allCases
        #expect(allCases.contains(.swift))
        #expect(allCases.contains(.localizableStrings))
        
        Task {
            let fileType: XcodeIntegration.FileType = .swift
            #expect(fileType == .swift)
        }
    }
    
    @Test("BuildPhase conforms to required protocols")
    func buildPhaseProtocolConformance() {
        #expect(XcodeIntegration.BuildPhase.sources.rawValue == "Sources")
        #expect(XcodeIntegration.BuildPhase.allCases.count == 5)
        
        let allCases = XcodeIntegration.BuildPhase.allCases
        #expect(allCases.contains(.sources))
        #expect(allCases.contains(.resources))
        
        Task {
            let buildPhase: XcodeIntegration.BuildPhase = .sources
            #expect(buildPhase.sectionName == "PBXSourcesBuildPhase")
        }
    }
    
    @Test("IntegrationError conforms to required protocols")
    func integrationErrorProtocolConformance() {
        let error = XcodeIntegration.IntegrationError.projectPathEmpty
        
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription == "Empty project path provided")
        
        Task {
            let asyncError: XcodeIntegration.IntegrationError = .targetNotFound
            #expect(asyncError.errorDescription != nil)
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("FileToAdd handles edge case file names and paths")
    func fileToAddEdgeCases() {
        let edgeCaseTests = [
            ("./file", "file"),
            ("file.with.multiple.dots.swift", "file.with.multiple.dots.swift"),
            ("file-with-dashes_and_underscores.swift", "file-with-dashes_and_underscores.swift"),
            ("file with spaces.swift", "file with spaces.swift")
        ]
        
        for (input, expectedFileName) in edgeCaseTests {
            let file = XcodeIntegration.FileToAdd(path: input, fileType: .swift)
            #expect(file.fileName == expectedFileName)
        }
    }
    
    @Test("Integration methods handle empty file arrays gracefully")
    func integrationMethodsEmptyArrays() async {
        let tempDir = createTempTestDirectory()
        defer { try? FileManager.default.removeItem(atPath: tempDir) }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addFiles(projectPath: tempDir, files: [])
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addSwiftFiles(projectPath: tempDir, files: [])
        }
        
        await #expect(throws: XcodeIntegration.IntegrationError.self) {
            try await XcodeIntegration.addLocalizationFiles(
                projectPath: tempDir,
                generatedFiles: [],
                languages: []
            )
        }
    }
    
    @Test("Error handling preserves underlying error information")
    func errorHandlingPreservesInformation() {
        let originalError = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Original error message"]
        )
        
        let wrappedError = XcodeIntegration.IntegrationError.fileProcessingFailed("test.swift", originalError)
        
        if case .fileProcessingFailed(let fileName, let underlyingError) = wrappedError {
            #expect(fileName == "test.swift")
            #expect((underlyingError as NSError).domain == "TestDomain")
            #expect((underlyingError as NSError).code == 42)
            #expect(underlyingError.localizedDescription == "Original error message")
        } else {
            #expect(Bool(false), "Should be fileProcessingFailed case")
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("FileToAdd creation is memory efficient")
    func fileToAddMemoryEfficiency() {
        var files: [XcodeIntegration.FileToAdd] = []
        
        for i in 0..<1000 {
            files.append(XcodeIntegration.FileToAdd(
                path: "Sources/File\(i).swift",
                fileType: .swift,
                language: i % 2 == 0 ? "en" : nil
            ))
        }
        
        #expect(files.count == 1000)
        #expect(files[0].fileName == "File0.swift")
        #expect(files[999].fileName == "File999.swift")
        #expect(files[0].language == "en")
        #expect(files[1].language == nil)
    }
    
    @Test("FileType and BuildPhase are efficient for repeated access")
    func typeAccessEfficiency() {
        let fileTypes = Array(repeating: XcodeIntegration.FileType.allCases, count: 100).flatMap { $0 }
        let buildPhases = Array(repeating: XcodeIntegration.BuildPhase.allCases, count: 100).flatMap { $0 }
        
        for fileType in fileTypes {
            let _ = fileType.rawValue
            let _ = fileType.buildPhase
        }
        
        for buildPhase in buildPhases {
            let _ = buildPhase.rawValue
            let _ = buildPhase.sectionName
        }
        
        #expect(fileTypes.count == 1200)
        #expect(buildPhases.count == 500)
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Types are safe for concurrent access")
    func concurrentTypeSafety() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let file = XcodeIntegration.FileToAdd(
                        path: "Sources/ConcurrentFile\(i).swift",
                        fileType: .swift
                    )
                    #expect(file.fileName.contains("ConcurrentFile\(i)"))
                }
                
                group.addTask {
                    let fileType = XcodeIntegration.FileType.swift
                    let buildPhase = fileType.buildPhase
                    #expect(buildPhase == .sources)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTempTestDirectory() -> String {
        let tempDir = NSTemporaryDirectory()
        let testDir = URL(fileURLWithPath: tempDir).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir.path
    }
}

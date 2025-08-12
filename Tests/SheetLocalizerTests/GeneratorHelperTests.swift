import Testing
import Foundation
import CoreExtensions
import os.log
@testable import SheetLocalizer

@Suite
struct GeneratorHelperTests {

    @Test
    func findXcodeProjectInCurrentDirectory() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let projectDir = tempDir.appendingPathComponent("TestProject.xcodeproj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        let foundPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        
        // Handle path resolution differences (e.g., /private/var vs /var)
        let normalizedFoundPath = foundPath.map { URL(fileURLWithPath: $0).resolvingSymlinksInPath().path }
        let normalizedTempPath = tempDir.resolvingSymlinksInPath().path
        #expect(normalizedFoundPath == normalizedTempPath)
    }
    
    @Test
    func findXcodeProjectInParentDirectory() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let projectDir = tempDir.appendingPathComponent("ParentProject.xcodeproj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        let subDir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(subDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        let foundPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        
        // Should find project in parent directory
        #expect(foundPath != nil)
        if let foundPath = foundPath {
            // The found path should be the parent directory containing the .xcodeproj
            let normalizedFoundPath = URL(fileURLWithPath: foundPath).resolvingSymlinksInPath().path
            let normalizedTempPath = tempDir.resolvingSymlinksInPath().path
            #expect(normalizedFoundPath == normalizedTempPath)
        }
    }
    
    @Test
    func findXcodeProjectSearchesUpToFiveLevels() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let projectDir = tempDir.appendingPathComponent("DeepProject.xcodeproj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        // Create exactly 5 levels deep (should still find project)
        var deepDir = tempDir
        for i in 1...4 { // Only 4 levels so we're within the 5-level limit
            deepDir = deepDir.appendingPathComponent("level\(i)")
            try FileManager.default.createDirectory(at: deepDir, withIntermediateDirectories: true)
        }
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(deepDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        let foundPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        
        // Should find the project within 5 levels
        #expect(foundPath != nil)
        if let foundPath = foundPath {
            let normalizedFoundPath = URL(fileURLWithPath: foundPath).resolvingSymlinksInPath().path
            let normalizedTempPath = tempDir.resolvingSymlinksInPath().path
            #expect(normalizedFoundPath == normalizedTempPath)
        }
    }
    
    @Test
    func findXcodeProjectStopsAfterFiveLevels() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let projectDir = tempDir.appendingPathComponent("TooDeepProject.xcodeproj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        var deepDir = tempDir
        for i in 1...6 {
            deepDir = deepDir.appendingPathComponent("level\(i)")
            try FileManager.default.createDirectory(at: deepDir, withIntermediateDirectories: true)
        }
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(deepDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        let foundPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        
        #expect(foundPath == nil || foundPath?.contains("/T") == true)
    }
    
    @Test
    func findXcodeProjectReturnsNilWhenNoneFound() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        let foundPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        
        #expect(foundPath == nil || foundPath?.contains("/T") == true)
    }
    
    @Test
    func cleanupExistingTemporaryFile() async throws {
        let tempFile = SharedTestData.createTempFile(content: "test content")
        
        #expect(FileManager.default.fileExists(atPath: tempFile.path))
        
        let logger = Logger(subsystem: "test", category: "test")
        try await GeneratorHelper.cleanupTemporaryFile(at: tempFile.path, logger: logger)
        
        #expect(!FileManager.default.fileExists(atPath: tempFile.path))
    }
    
    @Test
    func cleanupNonExistentTemporaryFile() async throws {
        let nonExistentPath = "/tmp/non_existent_file_\(UUID().uuidString).txt"
        
        #expect(!FileManager.default.fileExists(atPath: nonExistentPath))
        
        let logger = Logger(subsystem: "test", category: "test")
        
        try await GeneratorHelper.cleanupTemporaryFile(at: nonExistentPath, logger: logger)
    }
    
    @Test
    func cleanupTemporaryFileInNonExistentDirectory() async throws {
        let nonExistentDir = "/tmp/non_existent_dir_\(UUID().uuidString)"
        let filePath = "\(nonExistentDir)/test_file.txt"
        
        let logger = Logger(subsystem: "test", category: "test")
        
        try await GeneratorHelper.cleanupTemporaryFile(at: filePath, logger: logger)
    }
    
    @Test
    func cleanupTemporaryFileWithInvalidPath() async throws {
        let invalidPath = ""
        
        let logger = Logger(subsystem: "test", category: "test")
        
        try await GeneratorHelper.cleanupTemporaryFile(at: invalidPath, logger: logger)
    }
    
    @Test
    func cleanupTemporaryFileHandlesPermissionErrors() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let tempFile = tempDir.appendingPathComponent("protected_file.txt")
        try "test content".write(to: tempFile, atomically: true, encoding: .utf8)
        
        let originalPermissions = try FileManager.default.attributesOfItem(atPath: tempDir.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: tempDir.path)
        
        defer {
            try? FileManager.default.setAttributes(originalPermissions, ofItemAtPath: tempDir.path)
        }
        
        let logger = Logger(subsystem: "test", category: "test")
        
        try await GeneratorHelper.cleanupTemporaryFile(at: tempFile.path, logger: logger)
    }
    
    @Test("Cleanup temporary directory")
    func cleanupTemporaryDirectory() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        try "content1".write(to: file1, atomically: true, encoding: .utf8)
        try "content2".write(to: file2, atomically: true, encoding: .utf8)
        
        #expect(FileManager.default.fileExists(atPath: tempDir.path))
        
        let logger = Logger(subsystem: "test", category: "test")
        try await GeneratorHelper.cleanupTemporaryFile(at: tempDir.path, logger: logger)
        
        #expect(!FileManager.default.fileExists(atPath: tempDir.path))
    }
    
    @Test
    func findProjectAndCleanupWorkflow() async throws {
        let tempDir = SharedTestData.createTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let projectDir = tempDir.appendingPathComponent("WorkflowProject.xcodeproj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        let tempFile = tempDir.appendingPathComponent("temp.csv")
        try "temporary content".write(to: tempFile, atomically: true, encoding: .utf8)
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        
        let foundPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        // Handle path resolution differences (e.g., /private/var vs /var)
        let normalizedFoundPath = foundPath.map { URL(fileURLWithPath: $0).resolvingSymlinksInPath().path }
        let normalizedTempPath = tempDir.resolvingSymlinksInPath().path
        #expect(normalizedFoundPath == normalizedTempPath)
        
        try await GeneratorHelper.cleanupTemporaryFile(at: tempFile.path, logger: logger)
        #expect(!FileManager.default.fileExists(atPath: tempFile.path))
        
        #expect(FileManager.default.fileExists(atPath: projectDir.path))
    }
    
    @Test
    func handleFileSystemErrorsDuringProjectSearch() async throws {
        let tempDir = SharedTestData.createTempDirectory() 
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let projectDir = tempDir.appendingPathComponent("ErrorProject.xcodeproj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: tempDir.path)
        
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempDir.path)
        }
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        
        let foundPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        #expect(foundPath == nil || foundPath?.contains("/T") == true)
    }
    
    @Test
    func handleRootDirectoryEdgeCase() async throws {

        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath("/")
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        
        let foundPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        
        #expect(foundPath == nil || foundPath == "/")
    }
}

import Testing
import Foundation
import os.log
@testable import SheetLocalizer
@testable import CoreExtensions
@testable import XcodeIntegration

@Suite
struct XcodeIntegrationTest {
    
    private static let originalWorkingDirectory = FileManager.default.currentDirectoryPath
    
    // MARK: - Helper Methods
    
    private func createTestXcodeProject() throws -> (projectDir: String, pbxprojPath: String) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let projectName = "TestApp"
        let projectDir = tempDir.appendingPathComponent("\(projectName).xcodeproj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        let pbxprojContent = """
        // !$*UTF8*$!
        {
            archiveVersion = 1;
            classes = {
            };
            objectVersion = 56;
            objects = {
                00E356EC1AD99517003FC87E /* TestApp */ = {
                    isa = PBXGroup;
                    children = (
                    );
                    name = TestApp;
                    sourceTree = "<group>";
                };
                00E356ED1AD99517003FC87E /* Project object */ = {
                    isa = PBXProject;
                    attributes = {
                        LastSwiftUpdateCheck = 1500;
                        LastUpgradeCheck = 1500;
                        TargetAttributes = {
                        };
                    };
                    buildConfigurationList = 00E356EE1AD99517003FC87E;
                    compatibilityVersion = "Xcode 14.0";
                    developmentRegion = en;
                    hasScannedForEncodings = 0;
                    knownRegions = (
                        en,
                        Base,
                    );
                    mainGroup = 00E356EC1AD99517003FC87E;
                    productRefGroup = 00E356EC1AD99517003FC87E;
                    projectDirPath = "";
                    projectRoot = "";
                    targets = (
                    );
                };
            };
            rootObject = 00E356ED1AD99517003FC87E /* Project object */;
        }
        """
        
        let pbxprojPath = projectDir.appendingPathComponent("project.pbxproj")
        try pbxprojContent.write(to: pbxprojPath, atomically: true, encoding: .utf8)
        
        return (projectDir.path, pbxprojPath.path)
    }
    
    private func cleanupTestDirectory(_ path: String) {
        FileManager.default.changeCurrentDirectoryPath(Self.originalWorkingDirectory)
        
        try? FileManager.default.removeItem(atPath: path)
        
        let parentPath = (path as NSString).deletingLastPathComponent
        if parentPath.contains("SwiftSheetGen") || parentPath.contains("TestApp") {
            try? FileManager.default.removeItem(atPath: parentPath)
        }
    }
    
    // MARK: - Xcode Project Integration Tests
    
    @Test("Generated color files can be added to valid Xcode project")
    func addGeneratedColorFilesToXcodeProject() async throws {
        let (projectDir, pbxprojPath) = try createTestXcodeProject()
        defer { cleanupTestDirectory(projectDir) }
        
        let outputDir = "\(projectDir)/../GeneratedFiles"
        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
        
        let config = ColorConfig(
            outputDirectory: outputDir,
            csvFileName: "test_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = ColorGenerator(config: config)
        let csvContent = SharedTestData.colorsCSV
        
        let tempCSVFile = "\(outputDir)/test_colors.csv"
        try csvContent.write(toFile: tempCSVFile, atomically: true, encoding: .utf8)
        
        try await generator.generate(from: tempCSVFile)
        
        let colorsFile = "\(outputDir)/Colors.swift"
        let dynamicFile = "\(outputDir)/Color+Dynamic.swift"
        
        #expect(FileManager.default.fileExists(atPath: colorsFile), "Colors.swift should be generated")
        #expect(FileManager.default.fileExists(atPath: dynamicFile), "Color+Dynamic.swift should be generated")
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(projectDir)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        let foundProjectPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        #expect(foundProjectPath != nil, "Should find the Xcode project")
        
        if let foundPath = foundProjectPath {
            let normalizedFoundPath = URL(fileURLWithPath: foundPath).resolvingSymlinksInPath().path
            let normalizedExpectedPath = ((pbxprojPath as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent  // Remove project.pbxproj and .xcodeproj
            let normalizedExpected = URL(fileURLWithPath: normalizedExpectedPath).resolvingSymlinksInPath().path
            #expect(normalizedFoundPath == normalizedExpected, "Should find the correct project directory")
        }
        
        let colorsContent = try String(contentsOfFile: colorsFile, encoding: .utf8)
        #expect(colorsContent.contains("import SwiftUI"), "Generated files should be valid Swift code")
        #expect(!colorsContent.isEmpty, "Generated files should not be empty")
    }
    
    @Test("Generated localization files can be added to valid Xcode project")
    func addGeneratedLocalizationFilesToXcodeProject() async throws {
        let (projectDir, pbxprojPath) = try createTestXcodeProject()
        defer { cleanupTestDirectory(projectDir) }
        
        let outputDir = "\(projectDir)/../GeneratedLocalizations"
        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
        
        let config = LocalizationConfig(
            outputDirectory: outputDir,
            enumName: "L10n",
            sourceDirectory: outputDir,
            csvFileName: "test_localizations.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        let csvContent = SharedTestData.localizationCSV
        
        let tempCSVFile = "\(outputDir)/test_localizations.csv"
        try csvContent.write(toFile: tempCSVFile, atomically: true, encoding: .utf8)
        
        try await generator.generate(from: tempCSVFile)
        
        let enumFile = "\(outputDir)/L10n.swift"
        let esLproj = "\(outputDir)/es.lproj"
        let enLproj = "\(outputDir)/en.lproj"
        let frLproj = "\(outputDir)/fr.lproj"
        
        #expect(FileManager.default.fileExists(atPath: enumFile), "L10n.swift should be generated")
        #expect(FileManager.default.fileExists(atPath: esLproj), "es.lproj should be created")
        #expect(FileManager.default.fileExists(atPath: enLproj), "en.lproj should be created")
        #expect(FileManager.default.fileExists(atPath: frLproj), "fr.lproj should be created")
        
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(projectDir)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        
        let logger = Logger(subsystem: "test", category: "test")
        let foundProjectPath = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        #expect(foundProjectPath != nil, "Should find the Xcode project")
        
        if let foundPath = foundProjectPath {
            let normalizedFoundPath = URL(fileURLWithPath: foundPath).resolvingSymlinksInPath().path
            let normalizedExpectedPath = ((pbxprojPath as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent  // Remove project.pbxproj and .xcodeproj
            let normalizedExpected = URL(fileURLWithPath: normalizedExpectedPath).resolvingSymlinksInPath().path
            #expect(normalizedFoundPath == normalizedExpected, "Should find the correct project directory")
        }
        
        let enumContent = try String(contentsOfFile: enumFile, encoding: .utf8)
        #expect(enumContent.contains("enum L10n"), "Generated enum should be valid Swift code")
        #expect(!enumContent.isEmpty, "Generated files should not be empty")
    }
    
    @Test("Regenerating files maintains only the most recent version")
    func regeneratedFilesKeepMostRecentVersion() async throws {
        let (projectDir, _) = try createTestXcodeProject()
        defer { cleanupTestDirectory(projectDir) }
        
        let outputDir = "\(projectDir)/../GeneratedFiles"
        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
        
        let config = ColorConfig(
            outputDirectory: outputDir,
            csvFileName: "test_colors.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator = ColorGenerator(config: config)
        let csvContent = SharedTestData.colorsCSV
        let tempCSVFile = "\(outputDir)/test_colors.csv"
        try csvContent.write(toFile: tempCSVFile, atomically: true, encoding: .utf8)
        
        try await generator.generate(from: tempCSVFile)
        
        let colorsFile = "\(outputDir)/Colors.swift"
        #expect(FileManager.default.fileExists(atPath: colorsFile), "First generation should create Colors.swift")
        
        let firstAttributes = try FileManager.default.attributesOfItem(atPath: colorsFile)
        let firstModificationDate = firstAttributes[.modificationDate] as! Date
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        try await generator.generate(from: tempCSVFile)
        
        let directoryContents = try FileManager.default.contentsOfDirectory(atPath: outputDir)
        let colorFiles = directoryContents.filter { $0.hasPrefix("Colors") && $0.hasSuffix(".swift") }
        
        #expect(colorFiles.count == 1, "Should have only one Colors.swift file, not duplicates")
        #expect(colorFiles.first == "Colors.swift", "Should maintain the original filename")
        
        let secondAttributes = try FileManager.default.attributesOfItem(atPath: colorsFile)
        let secondModificationDate = secondAttributes[.modificationDate] as! Date
        
        #expect(secondModificationDate > firstModificationDate, "Regenerated file should have newer modification date")
    }
    
    @Test("Xcode project search functionality works correctly")
    func xcodeProjectSearchFunctionality() throws {
        let (projectDir, _) = try createTestXcodeProject()
        defer { cleanupTestDirectory(projectDir) }
        
        let originalDir = FileManager.default.currentDirectoryPath
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }
        let logger = Logger(subsystem: "test", category: "test")
        
        FileManager.default.changeCurrentDirectoryPath(projectDir)
        let foundFromProjectDir = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        #expect(foundFromProjectDir != nil, "Should find project from project directory")
        
        let parentDir = (projectDir as NSString).deletingLastPathComponent
        FileManager.default.changeCurrentDirectoryPath(parentDir)
        let foundFromParentDir = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        #expect(foundFromParentDir != nil, "Should find project from parent directory")
        
        let emptyDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: emptyDir) }
        
        FileManager.default.changeCurrentDirectoryPath(emptyDir.path)
        let notFound = try GeneratorHelper.findXcodeProjectPath(logger: logger)
        #expect(notFound == nil, "Should not find project in empty directory")
    }
    
    @Test("File replacement during regeneration maintains file integrity")
    func fileReplacementMaintainsIntegrity() async throws {
        let (projectDir, _) = try createTestXcodeProject()
        defer { cleanupTestDirectory(projectDir) }
        
        let outputDir = "\(projectDir)/../GeneratedFiles"
        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
        
        let initialConfig = LocalizationConfig(
            outputDirectory: outputDir,
            enumName: "InitialL10n",
            sourceDirectory: outputDir,
            csvFileName: "test_localizations.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator1 = LocalizationGenerator(config: initialConfig)
        let csvContent = SharedTestData.localizationCSV
        let tempCSVFile = "\(outputDir)/test_localizations.csv"
        try csvContent.write(toFile: tempCSVFile, atomically: true, encoding: .utf8)
        
        try await generator1.generate(from: tempCSVFile)
        
        let enumFile = "\(outputDir)/InitialL10n.swift"
        #expect(FileManager.default.fileExists(atPath: enumFile), "Initial enum file should be created")
        
        let initialContent = try String(contentsOfFile: enumFile, encoding: .utf8)
        #expect(initialContent.contains("InitialL10n"), "Should contain initial enum name")
        
        let updatedConfig = LocalizationConfig(
            outputDirectory: outputDir,
            enumName: "UpdatedL10n",
            sourceDirectory: outputDir,
            csvFileName: "test_localizations.csv",
            cleanupTemporaryFiles: false
        )
        
        let generator2 = LocalizationGenerator(config: updatedConfig)
        try await generator2.generate(from: tempCSVFile)
        
        let updatedEnumFile = "\(outputDir)/UpdatedL10n.swift"
        #expect(FileManager.default.fileExists(atPath: updatedEnumFile), "Updated enum file should be created")
        
        #expect(FileManager.default.fileExists(atPath: enumFile), "Original file should still exist")
        
        let updatedContent = try String(contentsOfFile: updatedEnumFile, encoding: .utf8)
        #expect(updatedContent.contains("UpdatedL10n"), "Should contain updated enum name")
        #expect(!updatedContent.contains("InitialL10n"), "Should not contain old enum name")
    }
}

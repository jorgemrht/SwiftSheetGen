import Foundation
import CoreExtensions
import OSLog

public struct XcodeIntegration: Sendable {
    
    private static let logger = Logger.xcodeIntegration

    public static func addLocalizationFiles(
        projectPath: String,
        generatedFiles: [String],
        languages: [String],
        enumFile: String? = nil,
        forceUpdateExisting: Bool = false
    ) async throws {
        guard !projectPath.isEmptyOrWhitespace else {
            logger.error("Empty project path provided")
            return
        }
        
        let pbxprojPath = findPbxprojFile(in: projectPath)
        guard let pbxprojPath = pbxprojPath else {
            logger.error("No .xcodeproj found in: \(projectPath)")
            return
        }
        
        logger.info("Found Xcode project: \(pbxprojPath)")
        try await updatePbxproj(
            at: pbxprojPath,
            with: generatedFiles,
            languages: languages,
            enumFile: enumFile,
            forceUpdateExisting: forceUpdateExisting
        )
    }
    
    private static func findPbxprojFile(in directory: String) -> String? {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directory)
            for item in contents {
                if item.hasSuffix(".xcodeproj") {
                    let pbxprojPath = "\(directory)/\(item)/project.pbxproj"
                    if fileManager.fileExists(atPath: pbxprojPath) {
                        return pbxprojPath
                    }
                }
            }
        } catch {
            logger.error("Directory read failed: \(error.localizedDescription, privacy: .public)")
        }
        
        return nil
    }
    
    private static func updatePbxproj(
        at pbxprojPath: String,
        with files: [String],
        languages: [String],
        enumFile: String? = nil,
        forceUpdateExisting: Bool = false
    ) async throws {
        logger.info("Updating project.pbxproj at: \(pbxprojPath)")
        let content = try String(contentsOfFile: pbxprojPath, encoding: .utf8)
        var updatedContent = content
        var newFileReferences: [String] = []
        var newBuildFileReferences: [String] = []
        var hasChanges = false
        
        for language in languages {
            let localizableStringsPath = files.first { $0.contains("\(language).lproj") }?.replacingOccurrences(of: "./", with: "") ?? "Localizables/\(language).lproj/Localizable.strings"
            
            if !content.contains(localizableStringsPath) {
                logger.info("Adding \(localizableStringsPath) to project")
                let uuid = generateUUID()
                let buildUUID = generateUUID()
                
                let fileReference = """
                \t\t\(uuid) /* Localizable.strings in \(language) */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = Localizable.strings; path = \(localizableStringsPath); sourceTree = ""; };
                """
                newFileReferences.append(fileReference)
                
                let buildFileReference = """
                \t\t\(buildUUID) /* Localizable.strings in \(language) in Resources */ = {isa = PBXBuildFile; fileRef = \(uuid) /* Localizable.strings in \(language) */; };
                """
                newBuildFileReferences.append(buildFileReference)
                
                updatedContent = addToMainGroup(updatedContent, fileUUID: uuid, fileName: "Localizable.strings", language: language)
                updatedContent = addToResourcesBuildPhase(updatedContent, buildUUID: buildUUID)
                hasChanges = true
            } else if forceUpdateExisting {
                logger.info("Updating existing \(localizableStringsPath) in project")
                updatedContent = ensureFileInResourcesBuildPhase(updatedContent, localizableStringsPath: localizableStringsPath)
                hasChanges = true
            }
        }
        
        if let enumFile = enumFile {
            let enumFileName = URL(fileURLWithPath: enumFile).lastPathComponent
            let enumRelativePath = enumFile.replacingOccurrences(of: "./", with: "")
            
            if !content.contains(enumRelativePath) {
                logger.info("Adding Swift enum file: \(enumFileName) to project")
                let uuid = generateUUID()
                let buildUUID = generateUUID()
                
                let fileReference = """
                \t\t\(uuid) /* \(enumFileName) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \(enumRelativePath); sourceTree = ""; };
                """
                newFileReferences.append(fileReference)
                
                let buildFileReference = """
                \t\t\(buildUUID) /* \(enumFileName) in Sources */ = {isa = PBXBuildFile; fileRef = \(uuid) /* \(enumFileName) */; };
                """
                newBuildFileReferences.append(buildFileReference)
                
                updatedContent = addToMainGroup(updatedContent, fileUUID: uuid, fileName: enumFileName)
                updatedContent = addToSourcesBuildPhase(updatedContent, buildUUID: buildUUID)
                hasChanges = true
            } else {
                logger.info("Swift enum file already exists in project: \(enumFileName)")
            }
        }
        if !newFileReferences.isEmpty {
            updatedContent = insertFileReferences(updatedContent, references: newFileReferences)
        }
        
        if !newBuildFileReferences.isEmpty {
            updatedContent = insertBuildFileReferences(updatedContent, references: newBuildFileReferences)
        }
        
        if hasChanges {
            try updatedContent.write(toFile: pbxprojPath, atomically: true, encoding: .utf8)
            logger.info("Successfully updated project.pbxproj")
        } else {
            logger.info("No changes needed for project.pbxproj")
        }
    }
    
    private static func generateUUID() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(uuid[uuid.startIndex..<uuid.index(uuid.startIndex, offsetBy: 24)])
    }
    
    private static func ensureFileInResourcesBuildPhase(_ content: String, localizableStringsPath: String) -> String {
        let fileRefPattern = "([A-F0-9]{24}) /\\* Localizable\\.strings in [^\\*]+ \\*/ = \\{[^}]*path = \(NSRegularExpression.escapedPattern(for: localizableStringsPath))"
        if let regex = try? NSRegularExpression(pattern: fileRefPattern, options: []),
           let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
           let uuidRange = Range(match.range(at: 1), in: content) {
            let fileUUID = String(content[uuidRange])
            
            let buildPhasePattern = "\\* Resources \\*/ = \\{[\\s\\S]*?files = \\([\\s\\S]*?\(fileUUID)[\\s\\S]*?\\);"
            if let buildRegex = try? NSRegularExpression(pattern: buildPhasePattern, options: []),
               buildRegex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) != nil {
                return content
            } else {
                let buildUUID = generateUUID()
                let buildFileReference = """
                \t\t\(buildUUID) /* Localizable.strings in Resources */ = {isa = PBXBuildFile; fileRef = \(fileUUID) /* Localizable.strings */; };
                """
                let updatedWithBuildFile = insertBuildFileReferences(content, references: [buildFileReference])
                return addToResourcesBuildPhase(updatedWithBuildFile, buildUUID: buildUUID)
            }
        }
        
        return content
    }
    
    private static func insertFileReferences(_ content: String, references: [String]) -> String {
        let pattern = "(/* Begin PBXFileReference section */[\\s\\S]*?)(\n/* End PBXFileReference section */)"
        let newReferencesString = references.joined(separator: "\n")
        let replacement = "$1\n\(newReferencesString)$2"
        return content.replacingOccurrences(
            of: pattern,
            with: replacement,
            options: .regularExpression
        )
    }
    
    private static func insertBuildFileReferences(_ content: String, references: [String]) -> String {
        let pattern = "(/* Begin PBXBuildFile section */[\\s\\S]*?)(\n/* End PBXBuildFile section */)"
        let newReferencesString = references.joined(separator: "\n")
        let replacement = "$1\n\(newReferencesString)$2"
        return content.replacingOccurrences(
            of: pattern,
            with: replacement,
            options: .regularExpression
        )
    }
    
    private static func addToMainGroup(_ content: String, fileUUID: String, fileName: String, language: String) -> String {
        let pattern = "(children = \\([\\s\\S]*?)(\n\\t\\t\\t\\);)"
        let replacement = "$1\n\t\t\t\t\(fileUUID) /* \(fileName) in \(language) */,$2"
        return content.replacingOccurrences(
            of: pattern,
            with: replacement,
            options: .regularExpression
        )
    }
    
    private static func addToMainGroup(_ content: String, fileUUID: String, fileName: String) -> String {
        let pattern = "(children = \\([\\s\\S]*?)(\n\\t\\t\\t\\);)"
        let replacement = "$1\n\t\t\t\t\(fileUUID) /* \(fileName) */,$2"
        return content.replacingOccurrences(
            of: pattern,
            with: replacement,
            options: .regularExpression
        )
    }
    
    private static func addToResourcesBuildPhase(_ content: String, buildUUID: String) -> String {
        let pattern = "(/* Resources \\*/ = \\{[\\s\\S]*?files = \\([\\s\\S]*?)(\n\\t\\t\\t\\);)"
        let replacement = "$1\n\t\t\t\t\(buildUUID) /* Localizable.strings in Resources */,$2"
        return content.replacingOccurrences(
            of: pattern,
            with: replacement,
            options: .regularExpression
        )
    }
    
    private static func addToSourcesBuildPhase(_ content: String, buildUUID: String) -> String {
        let pattern = "(/* Sources \\*/ = \\{[\\s\\S]*?files = \\([\\s\\S]*?)(\n\\t\\t\\t\\);)"
        let replacement = "$1\n\t\t\t\t\(buildUUID) /* Swift file in Sources */,$2"
        return content.replacingOccurrences(
            of: pattern,
            with: replacement,
            options: .regularExpression
        )
    }
}

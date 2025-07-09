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

    public static func addSwiftFiles(
        projectPath: String,
        files: [String],
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
        try await updatePbxprojForSwiftFiles(
            at: pbxprojPath,
            with: files,
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
        try validateProjectStructure(content)
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
                if let mainTargetUUID = findMainTargetUUID(in: updatedContent),
                   let resourcesPhaseUUID = findBuildPhaseUUID(in: updatedContent, targetUUID: mainTargetUUID, phaseName: "Resources") {
                    updatedContent = addToSpecificBuildPhase(updatedContent, buildUUID: buildUUID, phaseUUID: resourcesPhaseUUID, fileType: "Resources")
                }
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
                if let mainTargetUUID = findMainTargetUUID(in: updatedContent),
                   let sourcesPhaseUUID = findBuildPhaseUUID(in: updatedContent, targetUUID: mainTargetUUID, phaseName: "Sources") {
                    updatedContent = addToSpecificBuildPhase(updatedContent, buildUUID: buildUUID, phaseUUID: sourcesPhaseUUID, fileType: "Sources")
                }
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

    private static func updatePbxprojForSwiftFiles(
        at pbxprojPath: String,
        with files: [String],
        forceUpdateExisting: Bool = false
    ) async throws {
        logger.info("Updating project.pbxproj for Swift files at: \(pbxprojPath)")
        let content = try String(contentsOfFile: pbxprojPath, encoding: .utf8)
        try validateProjectStructure(content)
        var updatedContent = content
        var newFileReferences: [String] = []
        var newBuildFileReferences: [String] = []
        var hasChanges = false

        for file in files {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            let relativePath = file.replacingOccurrences(of: "./", with: "")

            if !content.contains(relativePath) {
                logger.info("Adding Swift file: \(fileName) to project")
                let uuid = generateUUID()
                let buildUUID = generateUUID()

                let fileReference = """
                \t\t\(uuid) /* \(fileName) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \(relativePath); sourceTree = ""; };
                """
                newFileReferences.append(fileReference)

                let buildFileReference = """
                \t\t\(buildUUID) /* \(fileName) in Sources */ = {isa = PBXBuildFile; fileRef = \(uuid) /* \(fileName) */; };
                """
                newBuildFileReferences.append(buildFileReference)

                updatedContent = addToMainGroup(updatedContent, fileUUID: uuid, fileName: fileName)
                if let mainTargetUUID = findMainTargetUUID(in: updatedContent),
                   let sourcesPhaseUUID = findBuildPhaseUUID(in: updatedContent, targetUUID: mainTargetUUID, phaseName: "Sources") {
                    updatedContent = addToSpecificBuildPhase(updatedContent, buildUUID: buildUUID, phaseUUID: sourcesPhaseUUID, fileType: "Sources")
                }
                hasChanges = true
            } else if forceUpdateExisting {
                logger.info("Swift file already exists in project: \(fileName). Ensuring it's in Sources build phase.")
                hasChanges = true
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
                let fileName = URL(fileURLWithPath: localizableStringsPath).lastPathComponent
                return addToResourcesBuildPhase(updatedWithBuildFile, buildUUID: buildUUID, fileName: fileName)
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
    
    private static func findMainTargetUUID(in pbxproj: String) -> String? {
        do {
            let projectTargetRegex = try NSRegularExpression(pattern: #"targets = \(\s*([A-Z0-9]{24})"#, options: [])
            guard let match = projectTargetRegex.firstMatch(in: pbxproj, options: [], range: NSRange(pbxproj.startIndex..., in: pbxproj)),
                  match.numberOfRanges > 1,
                  let targetRange = Range(match.range(at: 1), in: pbxproj) else {
                logger.error("Could not find main target UUID in project")
                return nil
            }
            return String(pbxproj[targetRange])
        } catch {
            logger.error("Regex compilation failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func findBuildPhaseUUID(in pbxproj: String, targetUUID: String, phaseName: String) -> String? {
        do {
            let nativeTargetRegex = try NSRegularExpression(pattern: #"\#(targetUUID) /\*.*\*/ = \{[^\}]*?buildPhases = \(([^\)]*)\);"#, options: [.dotMatchesLineSeparators])
            
            guard let ntMatch = nativeTargetRegex.firstMatch(in: pbxproj, options: [], range: NSRange(pbxproj.startIndex..., in: pbxproj)),
                  ntMatch.numberOfRanges > 1,
                  let buildPhasesRange = Range(ntMatch.range(at: 1), in: pbxproj) else {
                logger.warning("Could not find build phases for target: \(targetUUID)")
                return nil
            }
            
            let buildPhases = pbxproj[buildPhasesRange]
            let phaseRegex = try NSRegularExpression(pattern: #"([A-Z0-9]{24}) /\* \#(phaseName) \*/"#)
            
            guard let sMatch = phaseRegex.firstMatch(in: String(buildPhases), options: [], range: NSRange(buildPhases.startIndex..., in: buildPhases)),
                  sMatch.numberOfRanges > 1,
                  let phaseRange = Range(sMatch.range(at: 1), in: buildPhases) else {
                logger.warning("Could not find \(phaseName) build phase")
                return nil
            }
            
            return String(buildPhases[phaseRange])
        } catch {
            logger.error("Regex compilation failed in findBuildPhaseUUID: \(error.localizedDescription)")
            return nil
        }
    }


    private static func addToSpecificBuildPhase(_ content: String, buildUUID: String, phaseUUID: String, fileType: String) -> String {
        let pattern = #"(\#(phaseUUID) /\* \#(fileType) \*/ = \{[^\}]*?files = \([^\)]*)(\);)"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            let replacement = "$1\n\t\t\t\t\(buildUUID) /* \(fileType) file */,$2"
            return regex.stringByReplacingMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content), withTemplate: replacement)
        } catch {
            logger.error("Regex compilation failed in addToSpecificBuildPhase: \(error.localizedDescription)")
            return content  // Retornar contenido sin cambios si falla
        }
    }

    
    private static func addToResourcesBuildPhase(_ content: String, buildUUID: String, fileName: String) -> String {
        let pattern = "(/* Resources \\*/ = \\{[\\s\\S]*?files = \\([\\s\\S]*?)(\\);)"
        let replacement = "$1\n\t\t\t\t\(buildUUID) /* \(fileName) in Resources */,$2"
        
        if let range = content.range(of: pattern, options: .regularExpression) {
            return content.replacingCharacters(in: range, with: content[range].replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            ))
        }

        return content
    }
    
    private static func validateProjectStructure(_ content: String) throws {
        guard content.contains("// !$*UTF8*$!") else {
            throw ProjectValidationError.invalidUTF8Header
        }

        let isModernFormat = content.contains("objectVersion = 77")
        
        let requiredSections = [
            "/* Begin PBXFileReference section */",
            "/* Begin PBXNativeTarget section */"
        ]
        
        let traditionalSections = [
            "/* Begin PBXBuildFile section */"
        ]
        
        for section in requiredSections {
            guard content.contains(section) else {
                throw ProjectValidationError.missingSection(section)
            }
        }

        if !isModernFormat {
            for section in traditionalSections {
                guard content.contains(section) else {
                    throw ProjectValidationError.missingSection(section)
                }
            }
        }
    }

    private enum ProjectValidationError: Error, LocalizedError {
        case invalidUTF8Header
        case missingSection(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidUTF8Header:
                return "Invalid project.pbxproj file: missing UTF8 header"
            case .missingSection(let section):
                return "Invalid project structure: missing \(section) section. The project.pbxproj file appears to be corrupted."
            }
        }
    }
}

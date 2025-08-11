import Foundation
import CoreExtensions
import OSLog
import RegexBuilder

public struct XcodeIntegration: Sendable {
    
    // MARK: - Types
    public struct FileToAdd: Sendable {
        public let path: String
        public let fileName: String
        public let fileType: FileType
        public let language: String?
        
        public init(path: String, fileType: FileType, language: String? = nil) {
            self.path = path.replacingOccurrences(of: "./", with: "")
            self.fileName = URL(fileURLWithPath: path).lastPathComponent
            self.fileType = fileType
            self.language = language
        }
    }
    
    public enum FileType: String, CaseIterable, Sendable {
        case swift = "sourcecode.swift"
        case localizableStrings = "text.plist.strings"
        case stringsCatalog = "text.json.xcstrings"
        case plist = "text.plist.xml"
        case json = "text.json"
        case xcassets = "folder.assetcatalog"
        case storyboard = "file.storyboard"
        case xib = "file.xib"
        case framework = "wrapper.framework"
        case library = "archive.ar"
        case bundle = "wrapper.cfbundle"
        case other = "file"
        
        var buildPhase: BuildPhase {
            switch self {
            case .swift:
                return .sources
            case .localizableStrings, .stringsCatalog, .plist, .json, .xcassets, .storyboard, .xib:
                return .resources
            case .framework, .library:
                return .frameworks
            case .bundle:
                return .resources
            case .other:
                return .resources
            }
        }
    }
    
    public enum BuildPhase: String, CaseIterable, Sendable {
        case sources = "Sources"
        case resources = "Resources"
        case frameworks = "Frameworks"
        case headers = "Headers"
        case copyFiles = "CopyFiles"
        
        var sectionName: String {
            switch self {
            case .sources: return "PBXSourcesBuildPhase"
            case .resources: return "PBXResourcesBuildPhase"
            case .frameworks: return "PBXFrameworksBuildPhase"
            case .headers: return "PBXHeadersBuildPhase"
            case .copyFiles: return "PBXCopyFilesBuildPhase"
            }
        }
    }
    
    public enum IntegrationError: LocalizedError, Sendable {
        case projectPathEmpty
        case projectNotFound(String)
        case invalidProjectFile(String)
        case targetNotFound
        case buildPhaseNotFound(String)
        case fileProcessingFailed(String, Error)
        case regexCompilationFailed(String)
        case invalidUTF8Header
        case missingSection(String)
        
        public var errorDescription: String? {
            switch self {
            case .projectPathEmpty:
                return "Empty project path provided"
            case .projectNotFound(let path):
                return "No .xcodeproj found in: \(path)"
            case .invalidProjectFile(let path):
                return "Invalid project.pbxproj file at: \(path)"
            case .targetNotFound:
                return "Could not find main target UUID in project"
            case .buildPhaseNotFound(let phase):
                return "Could not find \(phase) build phase"
            case .fileProcessingFailed(let file, let error):
                return "Failed to process file \(file): \(error.localizedDescription)"
            case .regexCompilationFailed(let pattern):
                return "Regex compilation failed for pattern: \(pattern)"
            case .invalidUTF8Header:
                return "Invalid project.pbxproj file: missing UTF8 header"
            case .missingSection(let section):
                return "Missing required section: \(section)"
            }
        }
    }
    
    // MARK: - Properties
    
    private static let logger = Logger.xcodeIntegration
    
    // MARK: - Public Interface
    
    public static func addLocalizationFiles(
        projectPath: String,
        generatedFiles: [String],
        languages: [String],
        enumFile: String? = nil
    ) async throws {
        var filesToAdd: [FileToAdd] = []
        
        for language in languages {
            let localizableStringsPath = generatedFiles.first { $0.contains("\(language).lproj") }
                ?? "Localizables/\(language).lproj/Localizable.strings"
            
            let fileToAdd = FileToAdd(
                path: localizableStringsPath,
                fileType: .localizableStrings,
                language: language
            )
            filesToAdd.append(fileToAdd)
        }
        
        if let enumFile = enumFile {
            let enumFileToAdd = FileToAdd(path: enumFile, fileType: .swift)
            filesToAdd.append(enumFileToAdd)
        }
        
        try await addFiles(
            projectPath: projectPath,
            files: filesToAdd
        )
    }
    
    public static func addSwiftFiles(
        projectPath: String,
        files: [String]
    ) async throws {
        let filesToAdd = files.map { FileToAdd(path: $0, fileType: .swift) }
        
        try await addFiles(
            projectPath: projectPath,
            files: filesToAdd
        )
    }
    
    public static func addStringsCatalogFile(
        projectPath: String,
        catalogPath: String
    ) async throws {
        let catalogFile = FileToAdd(path: catalogPath, fileType: .stringsCatalog)
        
        try await addFiles(
            projectPath: projectPath,
            files: [catalogFile]
        )
    }
    
    public static func addFiles(
        projectPath: String,
        files: [FileToAdd]
    ) async throws {
        guard !projectPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw IntegrationError.projectPathEmpty
        }
        
        let pbxprojPath = try findPbxprojFile(in: projectPath)
        logger.info("Found Xcode project: \(pbxprojPath)")
        
        try await updateProject(
            at: pbxprojPath,
            with: files
        )
    }
    
    // MARK: - Private Implementation
    
    private static func findPbxprojFile(in directory: String) throws -> String {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directory)
            
            for item in contents where item.hasSuffix(".xcodeproj") {
                let pbxprojPath = "\(directory)/\(item)/project.pbxproj"
                if fileManager.fileExists(atPath: pbxprojPath) {
                    return pbxprojPath
                }
            }
            
            throw IntegrationError.projectNotFound(directory)
        } catch {
            if error is IntegrationError {
                throw error
            }
            logger.error("Directory read failed: \(error.localizedDescription)")
            throw IntegrationError.projectNotFound(directory)
        }
    }
    
    private static func updateProject(
        at pbxprojPath: String,
        with files: [FileToAdd]
    ) async throws {
        logger.info("Updating project.pbxproj at: \(pbxprojPath)")
        
        let content = try String(contentsOfFile: pbxprojPath, encoding: .utf8)
        try validateProjectStructure(content)
        
        var projectContent = ProjectContent(content: content)
        var hasChanges = false
        
        for file in files {
            do {
                let fileWasAdded = try await processFile(
                    file: file,
                    projectContent: &projectContent
                )
                
                if fileWasAdded {
                    hasChanges = true
                }
            } catch {
                logger.error("Failed to process file \(file.fileName): \(error.localizedDescription)")
                throw IntegrationError.fileProcessingFailed(file.fileName, error)
            }
        }
        
        if hasChanges {
            try projectContent.write(to: pbxprojPath)
            logger.info("Successfully updated project.pbxproj")
        } else {
            logger.info("No changes needed for project.pbxproj")
        }
    }
    
    private static func processFile(
        file: FileToAdd,
        projectContent: inout ProjectContent
    ) async throws -> Bool {
        let fileExists = projectContent.contains(file.path)
        
        if !fileExists {
            logger.info("Adding \(file.fileName) to project")
            try projectContent.addFile(file)
            return true
        } else {
            logger.info("File \(file.fileName) already exists - skipping")
            return false
        }
    }


    private static func findLocalizableStringsReference(in content: String, for path: String) -> String? {
        let patterns = [
            "([A-Fa-f0-9]{24}) /\\* Localizable\\.strings in [^\\*]+ \\*/ = \\{[^}]*path = \(NSRegularExpression.escapedPattern(for: path))",
            "([A-Fa-f0-9]{32}) /\\* Localizable\\.strings in [^\\*]+ \\*/ = \\{[^}]*path = \(NSRegularExpression.escapedPattern(for: path))",
            "([A-Fa-f0-9]{24}) /\\* Localizable\\.strings \\*/ = \\{[^}]*path = \(NSRegularExpression.escapedPattern(for: path))"
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                if let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
                   match.numberOfRanges > 1,
                   let uuidRange = Range(match.range(at: 1), in: content) {
                    return String(content[uuidRange])
                }
            } catch {
                logger.error("Regex compilation failed for localization pattern: \(pattern)")
                continue
            }
        }
        
        return nil
    }

    
    private static func ensureFileInResourcesBuildPhase(_ content: String, localizableStringsPath: String) -> String {
        let fileRefPattern = "([A-Fa-f0-9]{24}) /\\* Localizable\\.strings in [^\\*]+ \\*/ = \\{[^}]*path = \(NSRegularExpression.escapedPattern(for: localizableStringsPath))"
        
        do {
            let regex = try NSRegularExpression(pattern: fileRefPattern, options: [])
            guard let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
                  match.numberOfRanges > 1,
                  let uuidRange = Range(match.range(at: 1), in: content) else {
                logger.warning("Could not find file reference for: \(localizableStringsPath)")
                return content
            }
            
            let fileUUID = String(content[uuidRange])
            
            // Verificar si el archivo ya está en la fase de Resources
            let buildPhasePattern = "\\* Resources \\*/ = \\{[\\s\\S]*?files = \\([\\s\\S]*?\(fileUUID)[\\s\\S]*?\\);"
            let buildRegex = try NSRegularExpression(pattern: buildPhasePattern, options: [])
            
            if buildRegex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) != nil {
                logger.info("File \(localizableStringsPath) already in Resources build phase")
                return content
            } else {
                logger.info("Adding existing file \(localizableStringsPath) to Resources build phase")
                let buildUUID = generateUUID()
                let buildFileReference = """
                \t\t\(buildUUID) /* Localizable.strings in Resources */ = {isa = PBXBuildFile; fileRef = \(fileUUID) /* Localizable.strings */; };
                """
                let updatedWithBuildFile = insertBuildFileReferences(content, references: [buildFileReference])
                let fileName = URL(fileURLWithPath: localizableStringsPath).lastPathComponent
                return addToResourcesBuildPhase(updatedWithBuildFile, buildUUID: buildUUID, fileName: fileName)
            }
        } catch {
            logger.error("Regex compilation failed in ensureFileInResourcesBuildPhase: \(error.localizedDescription)")
            return content
        }
    }

    private static func addToResourcesBuildPhase(_ content: String, buildUUID: String, fileName: String) -> String {
        let patterns = [
            "(/* Resources \\*/ = \\{[\\s\\S]*?files = \\([\\s\\S]*?)(\\);)",
            "(PBXResourcesBuildPhase[\\s\\S]*?files = \\([\\s\\S]*?)(\\);)",
            "(/\\* Resources \\*/ = \\{[\\s\\S]*?files = \\([\\s\\S]*?)(\\n\\t\\t\\t\\);)"
        ]
        
        for pattern in patterns {
            let replacement = "$1\n\t\t\t\t\(buildUUID) /* \(fileName) in Resources */,$2"
            
            if let range = content.range(of: pattern, options: .regularExpression) {
                let updatedContent = content.replacingCharacters(in: range, with: content[range].replacingOccurrences(
                    of: pattern,
                    with: replacement,
                    options: .regularExpression
                ))
                
                if updatedContent != content {
                    logger.info("Successfully added \(fileName) to Resources build phase")
                    return updatedContent
                }
            }
        }
        
        logger.warning("Could not add \(fileName) to Resources build phase - no pattern matched")
        return content
    }

    // MARK: - Project Content Management
    
    private struct ProjectContent {
        private var content: String
        private var fileReferences: [String] = []
        private var buildFileReferences: [String] = []
        
        init(content: String) {
            self.content = content
        }
        
        mutating func addFile(_ file: FileToAdd) throws {
            let uuid = generateUUID()
            let buildUUID = generateUUID()
            
            let fileReference = createFileReference(uuid: uuid, file: file)
            fileReferences.append(fileReference)
            
            let buildFileReference = createBuildFileReference(
                buildUUID: buildUUID,
                fileUUID: uuid,
                file: file
            )
            buildFileReferences.append(buildFileReference)
            
            addToMainGroup(fileUUID: uuid, file: file)
            
            try addToBuildPhase(buildUUID: buildUUID, file: file)
        }
        
        mutating func updateFile(_ file: FileToAdd) throws {
            if !contains(file.path) {
                try addFile(file)
            } else {
                if file.fileType == .localizableStrings {
                    logger.info("Ensuring \(file.fileName) is properly configured in Resources")
                    content = ensureFileInResourcesBuildPhase(content, localizableStringsPath: file.path)
                } else if file.fileType == .stringsCatalog {
                    logger.info("Strings Catalog file \(file.fileName) already exists and is properly configured")
                } else {
                    logger.info("File \(file.fileName) already exists and is properly configured")
                }
            }
        }
        
        func contains(_ path: String) -> Bool {
            return content.contains(path)
        }
        
        func write(to path: String) throws {
            var updatedContent = content
            
            if !fileReferences.isEmpty {
                updatedContent = insertFileReferences(updatedContent, references: fileReferences)
            }
            
            if !buildFileReferences.isEmpty {
                updatedContent = insertBuildFileReferences(updatedContent, references: buildFileReferences)
            }
            
            try updatedContent.write(toFile: path, atomically: true, encoding: .utf8)
        }
        
        private func createFileReference(uuid: String, file: FileToAdd) -> String {
            let languageComment = file.language.map { " in \($0)" } ?? ""
            return """
            \t\t\(uuid) /* \(file.fileName)\(languageComment) */ = {isa = PBXFileReference; lastKnownFileType = \(file.fileType.rawValue); path = \(file.path); sourceTree = ""; };
            """
        }
        
        private func createBuildFileReference(buildUUID: String, fileUUID: String, file: FileToAdd) -> String {
            let languageComment = file.language.map { " in \($0)" } ?? ""
            return """
            \t\t\(buildUUID) /* \(file.fileName)\(languageComment) in \(file.fileType.buildPhase.rawValue) */ = {isa = PBXBuildFile; fileRef = \(fileUUID) /* \(file.fileName)\(languageComment) */; };
            """
        }
        
        private mutating func addToMainGroup(fileUUID: String, file: FileToAdd) {
            let languageComment = file.language.map { " in \($0)" } ?? ""
            let pattern = "(children = \\([\\s\\S]*?)(\\n\\t\\t\\t\\);)"
            let replacement = "$1\n\t\t\t\t\(fileUUID) /* \(file.fileName)\(languageComment) */,$2"
            
            content = content.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }
        
        private mutating func addToBuildPhase(buildUUID: String, file: FileToAdd) throws {
            guard let mainTargetUUID = findMainTargetUUID(in: content) else {
                throw IntegrationError.targetNotFound
            }
            
            guard let buildPhaseUUID = findBuildPhaseUUID(
                in: content,
                targetUUID: mainTargetUUID,
                phaseName: file.fileType.buildPhase.rawValue
            ) else {
                throw IntegrationError.buildPhaseNotFound(file.fileType.buildPhase.rawValue)
            }
            
            addToSpecificBuildPhase(
                buildUUID: buildUUID,
                phaseUUID: buildPhaseUUID,
                fileType: file.fileType.buildPhase.rawValue
            )
        }
        
        private mutating func addToSpecificBuildPhase(buildUUID: String, phaseUUID: String, fileType: String) {
            let pattern = #"(\#(phaseUUID) /\* \#(fileType) \*/ = \{[^\}]*?files = \([^\)]*)(\);)"#
            let replacement = "$1\n\t\t\t\t\(buildUUID) /* \(fileType) file */,$2"
            
            content = content.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }
        
        mutating func validateAndRepairFileIntegrity(_ file: FileToAdd) throws -> Bool {
            guard file.fileType == .localizableStrings || file.fileType == .stringsCatalog else {
                return false // Solo para archivos de localización
            }
            
            let fileRefPattern = "([A-Fa-f0-9]{24}) /\\* \(NSRegularExpression.escapedPattern(for: file.fileName))[^\\*]* \\*/ = \\{[^}]*path = \(NSRegularExpression.escapedPattern(for: file.path))"
            
            do {
                let regex = try NSRegularExpression(pattern: fileRefPattern, options: [])
                guard let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
                      match.numberOfRanges > 1,
                      let uuidRange = Range(match.range(at: 1), in: content) else {
                    logger.warning("File reference missing for \(file.fileName)")
                    return false
                }
                
                let fileUUID = String(content[uuidRange])
                
                let buildPhasePattern = "\\* Resources \\*/ = \\{[\\s\\S]*?files = \\([\\s\\S]*?\(fileUUID)[\\s\\S]*?\\);"
                let buildRegex = try NSRegularExpression(pattern: buildPhasePattern, options: [])
                
                if buildRegex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) == nil {
                    logger.info("Repairing Resources build phase for \(file.fileName)")
                    content = ensureFileInResourcesBuildPhase(content, localizableStringsPath: file.path)
                    return true
                }
                
                return false
            } catch {
                logger.error("Validation failed for \(file.fileName): \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // MARK: - UUID Generation
    
    private static func generateUUID() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(uuid.prefix(24))
    }
    
    // MARK: - Project Structure Analysis
    
    private static func findMainTargetUUID(in pbxproj: String) -> String? {
        let patterns = [
            #"targets = \(\s*([A-Fa-f0-9]{24})"#,
            #"targets = \(\s*([A-Fa-f0-9]{32})"#,
            #"targets = \(\s*([A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12})"#
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                if let match = regex.firstMatch(in: pbxproj, options: [], range: NSRange(pbxproj.startIndex..., in: pbxproj)),
                   match.numberOfRanges > 1,
                   let targetRange = Range(match.range(at: 1), in: pbxproj) {
                    return String(pbxproj[targetRange])
                }
            } catch {
                logger.error("Regex compilation failed for pattern: \(pattern)")
                continue
            }
        }
        
        return nil
    }
    
    private static func findBuildPhaseUUID(in pbxproj: String, targetUUID: String, phaseName: String) -> String? {
        do {
            let targetPattern = #"\#(targetUUID) /\*.*\*/ = \{.*?buildPhases = \((.*?)\);"#
            let nativeTargetRegex = try NSRegularExpression(
                pattern: targetPattern,
                options: [.dotMatchesLineSeparators, .caseInsensitive]
            )
            
            guard let ntMatch = nativeTargetRegex.firstMatch(
                in: pbxproj,
                options: [],
                range: NSRange(pbxproj.startIndex..., in: pbxproj)
            ),
            ntMatch.numberOfRanges > 1,
            let buildPhasesRange = Range(ntMatch.range(at: 1), in: pbxproj) else {
                logger.warning("Could not find build phases for target: \(targetUUID)")
                return nil
            }
            
            let buildPhases = String(pbxproj[buildPhasesRange])
            
            let phasePatterns = [
                #"([A-Fa-f0-9]{24}) /\* \#(phaseName) \*/"#,
                #"([A-Fa-f0-9]{32}) /\* \#(phaseName) \*/"#,
                #"([A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}) /\* \#(phaseName) \*/"#
            ]
            
            for phasePattern in phasePatterns {
                let phaseRegex = try NSRegularExpression(pattern: phasePattern, options: [.caseInsensitive])
                if let sMatch = phaseRegex.firstMatch(
                    in: buildPhases,
                    options: [],
                    range: NSRange(buildPhases.startIndex..., in: buildPhases)
                ),
                sMatch.numberOfRanges > 1,
                let phaseRange = Range(sMatch.range(at: 1), in: buildPhases) {
                    return String(buildPhases[phaseRange])
                }
            }
            
            logger.warning("Could not find \(phaseName) build phase UUID")
            return nil
        } catch {
            logger.error("Regex compilation failed in findBuildPhaseUUID: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Content Insertion
    
    private static func insertFileReferences(_ content: String, references: [String]) -> String {
        let pattern = "(/* Begin PBXFileReference section */[\\s\\S]*?)(\\n/* End PBXFileReference section */)"
        let newReferencesString = references.joined(separator: "\n")
        let replacement = "$1\n\(newReferencesString)$2"
        
        return content.replacingOccurrences(
            of: pattern,
            with: replacement,
            options: .regularExpression
        )
    }
    
    private static func insertBuildFileReferences(_ content: String, references: [String]) -> String {
        let pattern = "(/* Begin PBXBuildFile section */[\\s\\S]*?)(\\n/* End PBXBuildFile section */)"
        let newReferencesString = references.joined(separator: "\n")
        let replacement = "$1\n\(newReferencesString)$2"
        
        return content.replacingOccurrences(
            of: pattern,
            with: replacement,
            options: .regularExpression
        )
    }
    
    // MARK: - Validation
    
    private static func validateProjectStructure(_ content: String) throws {
        guard content.contains("// !$*UTF8*$!") else {
            throw IntegrationError.invalidUTF8Header
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
                throw IntegrationError.missingSection(section)
            }
        }
        
        if !isModernFormat {
            for section in traditionalSections {
                guard content.contains(section) else {
                    throw IntegrationError.missingSection(section)
                }
            }
        }
    }
}

// MARK: - Logger Extension

extension Logger {
    static let xcodeIntegration = Logger(subsystem: "com.swiftsheetgen.xcode", category: "integration")
}

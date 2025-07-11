import Testing
@testable import SheetLocalizer
import Foundation

@Suite()
struct LocalizationGeneratorIntegrationTests {

    private static let localizationCSV = """
    "[Check]", "[View]", "[Item]", "[Type]", "es", "en", "fr"
    "", "common", "app_name", "text", "jorgemrht", "My App", "Mon App"
    "", "common", "language_code", "text", "es", "en", "fr"
    "", "login", "title", "text", "Login", "Login", "Connexion"
    "", "login", "username", "text", "Usuario", "Username", "Nom d'utilisateur"
    "", "login", "password", "text", "Contraseña", "Password", "Mot de passe"
    "", "login", "forgot_password", "button", "¿Contraseña olvidada?", "Forgot password?", "Mot de passe oublié?"
    "", "login", "send", "button", "Iniciar sesión", "Sign in", "Se connecter"
    "", "profile", "version", "text", "Versión {{version}} (Build {{build}})", "Version {{version}} (Build {{build}})", "Version {{version}} (Build {{build}})"
    "", "profile", "user_count", "text", "{{count}} usuarios activos", "{{count}} active users", "{{count}} utilisateurs actifs"
    "", "settings", "notifications", "text", "Notificaciones", "Notifications", "Notifications"
    "[END]"
    """

    @Test("Generate succeeds with real downloaded CSV")
    func testGenerateWithValidCSV() async throws {
       
        let csv = Self.localizationCSV
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let csvPath = tempDir.appendingPathComponent("test.csv").path
        try csv.write(toFile: csvPath, atomically: true, encoding: .utf8)

        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "L10nTest",
            sourceDirectory: tempDir.path,
            csvFileName: "test.csv",
            autoAddToXcode: false,
            cleanupTemporaryFiles: false
        )
        
        let generator = LocalizationGenerator(config: config)
        try await generator.generate(from: csvPath)

        let langs = ["es", "en", "fr"]
        let files = langs.map { tempDir.appendingPathComponent("\($0).lproj/Localizable.strings").path }
        
        for (i, file) in files.enumerated() {
            #expect(FileManager.default.fileExists(atPath: file), "\(langs[i]) file should exist")
        }
        let enContents = try String(contentsOfFile: files[1], encoding: .utf8)
        let esContents = try String(contentsOfFile: files[0], encoding: .utf8)
        let frContents = try String(contentsOfFile: files[2], encoding: .utf8)

        let expectations: [(String, String, String)] = [
            (enContents, "common_app_name_text", "My App"),
            (esContents, "common_app_name_text", "jorgemrht"),
            (frContents, "common_app_name_text", "Mon App"),
            (enContents, "profile_version_text", "Version %@ (Build %@)")
        ]
        for (contents, key, value) in expectations {
            #expect(contents.contains(key), "Should contain key: \(key)")
            #expect(contents.contains(value), "Should contain value: \(value)")
        }
    }

    @Test("Throws on CSV with missing header")
    func testGenerateThrowsOnMissingHeader() async throws {
        let csv = """
        "", "common", "app_name", "text", "jorgemrht", "My App", "Mon App"
        "", "common", "language_code", "text", "es", "en", "fr"
        "", "login", "title", "text", "Login", "Login", "Connexion"
        "", "login", "username", "text", "Usuario", "Username", "Nom d'utilisateur"
        "", "login", "password", "text", "Contraseña", "Password", "Mot de passe"
        "", "login", "forgot_password", "button", "¿Contraseña olvidada?", "Forgot password?", "Mot de passe oublié?"
        "", "login", "send", "button", "Iniciar sesión", "Sign in", "Se connecter"
        "", "profile", "version", "text", "Versión {{version}} (Build {{build}})", "Version {{version}} (Build {{build}})", "Version {{version}} (Build {{build}})"
        "", "profile", "user_count", "text", "{{count}} usuarios activos", "{{count}} active users", "{{count}} utilisateurs actifs"
        "", "settings", "notifications", "text", "Notificaciones", "Notifications", "Notifications"
        "[END]"
        """
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let csvPath = tempDir.appendingPathComponent("test.csv").path
        try csv.write(toFile: csvPath, atomically: true, encoding: .utf8)
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "L10nTest",
            sourceDirectory: tempDir.path,
            csvFileName: "test.csv",
            autoAddToXcode: false,
            cleanupTemporaryFiles: false
        )
        let generator = LocalizationGenerator(config: config)
        do {
            try await generator.generate(from: csvPath)
            #expect(Bool(false), "Should throw on missing header")
        } catch {
            let errorDesc = String(describing: error)
            #expect(errorDesc.contains("Header row not found") || errorDesc.contains("Invalid CSV structure"))
        }
    }

    @Test("Throws on CSV with insufficient rows")
    func testGenerateThrowsOnInsufficientRows() async throws {
        let csv = """
        "[Check]", "[View]", "[Item]", "[Type]", "es", "en", "fr"
        "", "common", "app_name", "text", "jorgemrht", "My App", "Mon App"
        "[END]"
        """
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let csvPath = tempDir.appendingPathComponent("test.csv").path
        try csv.write(toFile: csvPath, atomically: true, encoding: .utf8)
        let config = LocalizationConfig(
            outputDirectory: tempDir.path,
            enumName: "L10nTest",
            sourceDirectory: tempDir.path,
            csvFileName: "test.csv",
            autoAddToXcode: false,
            cleanupTemporaryFiles: false
        )
        let generator = LocalizationGenerator(config: config)
        do {
            try await generator.generate(from: csvPath)
            #expect(Bool(false), "Should throw on insufficient rows")
        } catch {
            let errorDesc = String(describing: error)
            #expect(errorDesc.contains("Insufficient data") || errorDesc.contains("CSV must have at least 4 rows"))
        }
    }
}


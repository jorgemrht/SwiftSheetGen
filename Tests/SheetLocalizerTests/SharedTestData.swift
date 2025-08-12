import Foundation

public enum SharedTestData {
    
    public static let localizationCSV = """
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
    
    public static let colorsCSV = """
    Items a revisar,,,,,Desc
    Check,[Color Name],[Any Hex Value],[Light Hex Value],[Dark Hex Value],[Desc]
    ,[COMMENT],[ANY HEX VALUE],[Light HEX VALUE],[DARK HEX VALUE],Common
    ,primaryBackgroundColor,#FFF,#FFF,#FFF,El color de fondo principal para las vistas de la aplicación.
    ,secondaryBackgroundColor,#FFF,#FFF,#FFF,Para contenido agrupado o elementos sobre el fondo principal.    
    ,tertiaryBackgroundColor,#FFF,#FFF,#FFF,Para contenido agrupado dentro de elementos secundarios.        
    ,primaryTextColor,#FFF,#FFF,#FFF,Color principal para el texto más importante.    
    ,secondaryTextColor,#FFF,#FFF,#FFF,"Para texto con menor énfasis, como subtítulos o descripciones.    "
    ,tertiaryTextColor,#FFF,#FFF,#FFF,"Para texto con énfasis mínimo, como pies de foto o marcas de tiempo.    "
    ,placeholderTextColor,#FFF,#FFF,#FFF,Color para el texto de marcador de posición en campos de texto.    
    [END],,,,, 
    """
    
    public static func createTempFile(content: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).csv")
        try! content.write(to: tempFile, atomically: true, encoding: .utf8)
        return tempFile
    }
    
    public static func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
}

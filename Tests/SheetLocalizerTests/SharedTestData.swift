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
    
    public static let largeCSVData: String = {
        var content = localizationCSV
        for i in 0..<100 {
            content += "\n\"\", \"bulk_view_\(i)\", \"item_\(i)\", \"text\", \"Texto \(i)\", \"Text \(i)\", \"Texte \(i)\""
        }
        return content + "\n[END]"
    }()
    
    public static let performanceTestCSV: String = {
        var lines = ["\"[Check]\", \"[View]\", \"[Item]\", \"[Type]\", \"es\", \"en\", \"fr\""]
        for i in 0..<1000 {
            lines.append("\"\", \"perf_view_\(i % 10)\", \"item_\(i)\", \"text\", \"Texto de rendimiento \(i)\", \"Performance text \(i)\", \"Texte de performance \(i)\"")
        }
        lines.append("[END]")
        return lines.joined(separator: "\n")
    }()
    
    public static func createTempFile(content: String, extension: String = "csv") -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).\(`extension`)")
        try! content.write(to: tempFile, atomically: true, encoding: .utf8)
        return tempFile
    }
    
    public static func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftSheetGenTests")
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    public static func createMockXcodeProject(in directory: URL, name: String = "TestProject") throws {
        let projectDir = directory.appendingPathComponent("\(name).xcodeproj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        let pbxprojContent = """
        // !$*UTF8*$!
        {
        	archiveVersion = 1;
        	classes = {
        	};
        	objectVersion = 54;
        	objects = {
        /* Begin PBXFileReference section */
        		ABC123DEF456789012345678 /* AppDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = ""; };
        /* End PBXFileReference section */
        /* Begin PBXBuildFile section */
        		123456789ABCDEF012345678 /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = ABC123DEF456789012345678 /* AppDelegate.swift */; };
        /* End PBXBuildFile section */
        /* Begin PBXNativeTarget section */
        		DEF456789012345678ABCDEF /* \(name) */ = {
        			isa = PBXNativeTarget;
        			buildPhases = (
        				456789012345678ABCDEF123 /* Sources */,
        				789012345678ABCDEF123456 /* Resources */,
        			);
        			name = \(name);
        			targets = (
        				DEF456789012345678ABCDEF /* \(name) */,
        			);
        		};
        /* End PBXNativeTarget section */
        /* Begin PBXSourcesBuildPhase section */
        		456789012345678ABCDEF123 /* Sources */ = {
        			isa = PBXSourcesBuildPhase;
        			files = (
        				123456789ABCDEF012345678 /* AppDelegate.swift in Sources */,
        			);
        		};
        /* End PBXSourcesBuildPhase section */
        /* Begin PBXResourcesBuildPhase section */
        		789012345678ABCDEF123456 /* Resources */ = {
        			isa = PBXResourcesBuildPhase;
        			files = (
        			);
        		};
        /* End PBXResourcesBuildPhase section */
        	};
        	rootObject = 9012345678ABCDEF12345678 /* Project object */;
        }
        """
        
        let pbxprojFile = projectDir.appendingPathComponent("project.pbxproj")
        try pbxprojContent.write(to: pbxprojFile, atomically: true, encoding: .utf8)
    }
}

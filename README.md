# SwiftSheetGen

SwiftSheetGen is a modern Swift 6.1+ tool that automates localization file generation for iOS and macOS projects directly from Google Sheets. It provides a complete solution that downloads, processes, and generates .strings files and type-safe Swift enums.

## Why SwiftSheetGen?

### **Problems It Solves**

- ✅ **Automatic synchronization** from collaborative Google Sheets
- ✅ **Eliminates typo errors** with type-safe code
- ✅ **Intelligent autocompletion** in Xcode
- ✅ **Compile-time validation** of all keys
- ✅ **Collaborative workflow** with translators and designers
- ✅ **Cross-platform generation** (iOS/macOS) from a single source
- ✅ **Swift 6.1+ native** with modern concurrency
- ✅ **No external dependencies** (Ruby/Gems free)

## Installation

### CLI Tool (Recommended)
---
Install as a command-line tool for project automation:

### Swift Package Manager
---

***Add SwiftSheetGen to your Package.swift:***

```swift
dependencies: [
    .package(url: "https://github.com/your-username/SwiftSheetGen", from: "1.0.0")
]
```

### Build from Source
---

***Install CLI tool globally from source code:***

```bash
git clone https://github.com/your-username/SwiftSheetGen.git
cd SwiftSheetGen
swift build -c release
cp .build/release/swiftsheetgen /usr/local/bin/
```

**Verify installation:**

```bash
swiftsheetgen --version
```

## Google Sheet Configuration

### Required Format

**Your Google Sheet must follow this specific structure:**

| Status | View | Item | Type | en | es | fr |
|--------|------|------|------|----|----|----| 
| ✅ | LoginView | title | label | Login | Iniciar Sesión | Connexion |
| ✅ | LoginView | button | action | Sign In | Entrar | Se connecter |
| ⚠️ | ProfileView | header | label | Profile | Perfil | Profil |

### **Column Explanation**

- **Status**: Indicates if text is reviewed (✅) or pending (⚠️)
- **View**: View/screen name
- **Item**: Specific element (button, label, etc.)
- **Type**: Element type (label, button, placeholder, etc.)
- **Languages**: One column per supported language

# SwiftSheetGen

<p align="center">
  <img src="" alt="SwiftSheetGen Logo" width="200"/>
</p>

<p align="center">
  <strong>Generate type-safe Swift code for localizations and colors directly from a Google Sheet.</strong>
</p>

<p align="center">
  <a href="https://github.com/jorge/SwiftSheetGen/actions"><img src="https://img.shields.io/github/actions/workflow/status/jorge/SwiftSheetGen/swift.yml?branch=main&style=for-the-badge" alt="Build Status"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0+-orange?style=for-the-badge" alt="Swift Version"></a>
  <a href="/LICENSE"><img src="https://img.shields.io/github/license/jorge/SwiftSheetGen?style=for-the-badge" alt="License"></a>
</p>

---

**SwiftSheetGen** is a command-line tool that transforms your team's collaborative Google Sheets for strings and colors into compile-time safe Swift code, eliminating manual errors and keeping your Xcode project in perfect sync.

## Why SwiftSheetGen?

Stop manually managing `.strings` files and defining colors in code. SwiftSheetGen offers a better way:

-   ✅ **Single Source of Truth**: Use a Google Sheet as a collaborative CMS for designers, translators, and developers. No more conflicts or outdated values.
-   ✅ **Type-Safe & Autocomplete**: Generates Swift enums (`L10n`) and `Color` extensions, turning runtime errors into compile-time errors and enabling autocomplete in Xcode.
-   ✅ **Automated & Fast**: Built natively in Swift, it runs fast and integrates seamlessly into your build process without external dependencies like Ruby.
-   ✅ **Eliminate Manual Work**: Forget copying keys, running scripts, or dragging files into Xcode. SwiftSheetGen handles it all.

## How It Works

The tool follows a simple three-step process:
1.  **Download**: It fetches the latest version of your Google Sheet and parses it as a CSV.
2.  **Generate**: It transforms the rows into type-safe Swift code (`.swift` and `.strings` files).
3.  **Integrate**: It automatically adds or updates the generated files in your Xcode project, ready to be used.

## Installation

You can install SwiftSheetGen using the Swift Package Manager.

#### As a CLI Tool (Recommended)

Build the tool from the source and move it to a location in your `PATH`.
```bash
git clone https://github.com/jorge/SwiftSheetGen.git
cd SwiftSheetGen
swift build -c release
sudo cp .build/release/swiftsheetgen /usr/local/bin/
```
Verify the installation by running `swiftsheetgen --version`.

#### As a Package Dependency

Add `SwiftSheetGen` as a dependency to your `Package.swift` file to use its core libraries.
```swift
dependencies: [
    .package(url: "https://github.com/jorge/SwiftSheetGen.git", from: "1.0.0")
]
```

## Usage

### Basic Commands

To generate localizables, all you need to run is:
```bash
swiftsheetgen localization ""
```
This command saves the generated `.strings` and Swift files into a new `./Localizables` directory.

To generate colors, the command is:
```bash
swiftsheetgen colors ""
```
This command saves the generated Swift files into a new `./Colors` directory.

### Command Options

#### Shared Options (for `localization` and `colors`)

| Option | Shorthand | Description | Default |
|---|---|---|---|
| `--output-dir` | | The directory where generated files will be saved. For Xcode integration, this must be the directory containing your `.xcodeproj` file. | `./` |
| `--verbose` | `-v` | Enable detailed logging for debugging. | `false` |
| `--keep-csv` | | Keep the downloaded CSV file for debugging purposes. | `false` |
| `--log-privacy-level` | | Set log privacy to `public` or `private`. | `public` |

#### `localization` Specific Options

| Option | Description | Default |
|---|---|---|
| `--swift-enum-name` | Name for the generated Swift localization enum. | `L10n` |
| `--enum-separate-from-localizations` | Generate the Swift enum file in the base output directory instead of inside the `Localizables` subdirectory. | `false` |

The `colors` command does not have any specific options beyond the shared ones.

## Integrations

### Xcode
SwiftSheetGen automatically integrates the generated files into your Xcode project.

- **Compatibility:** This feature is fully compatible with **Xcode 15 and newer**.
- **Older Xcode Versions:** On older versions, if files do not appear automatically, you may need to **drag and drop them manually from Finder** for the initial setup.

For the integration to work, the directory you specify in `--output-dir` **must be the one that contains your `.xcodeproj` file**. The integration is automatic and cannot be disabled with a flag.

### Tuist
If a `Project.swift` or `Workspace.swift` file is detected in your project's root, SwiftSheetGen will skip the automatic Xcode integration and print instructions for you to add the generated files to your Tuist manifest.

## Google Sheet Setup

Your Google Sheet must have a specific structure for SwiftSheetGen to parse it correctly.

#### For Localizations
The sheet should contain columns for keys, comments, and each language.
| key | comment | en | es |
|---|---|---|---|
| `login.title` | Title on the login screen | Welcome! | ¡Bienvenido! |
| `login.button.signIn` | Sign in button text | Sign In | Iniciar Sesión |

#### For Colors
The sheet for colors requires a name and hex values for light, dark, or any appearance.
| name | anyHex | lightHex | darkHex |
|---|---|---|---|
| `primary` | | `#68478E` | `#866CA5` |
| `onPrimary` | | `#FFFFFF` | `#00172E` |
| `background` | `#F2F2F7` | | |

## Generated Code Examples

#### Localizations (`L10n.swift`)
```swift
// Auto-generated by SwiftSheetGen
import Foundation

public enum L10n: String, CaseIterable, Sendable {
    case loginTitle = "login_title"
    case loginButtonSignIn = "login_button_signIn"

    /// Returns the localized string for this key
    public var localized: String {
        NSLocalizedString(self.rawValue, bundle: .main, comment: "")
    }
    
    /// Returns a formatted localized string with arguments
    public func localized(_ args: CVarArg...) -> String {
        String(format: localized, arguments: args)
    }
}
```

#### Colors (`Colors.swift`)
```swift
// Auto-generated by SwiftSheetGen
import SwiftUI

public extension ShapeStyle where Self == Color {
    /// primary
    static var primary: Color { .init(light: .init(hex: 0x68478E), dark: .init(hex: 0x866CA5)) }
    /// onPrimary
    static var onPrimary: Color { .init(light: .init(hex: 0xFFFFFF), dark: .init(hex: 0x00172E)) }
    /// background
    static var background: Color { .init(hex: 0xF2F2F7) }
}

// ... plus extensions for dynamic colors and a SwiftUI preview
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


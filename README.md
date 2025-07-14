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

**SwiftSheetGen** is a command-line tool that automates the generation of Swift assets. It transforms your team's collaborative Google Sheets for strings and colors into compile-time safe code, eliminating manual errors and keeping your Xcode project in perfect sync.

## Features

- ✅ **Type-Safe Code**: Generates Swift enums for localizations (`L10n`) and extensions for `Color`, preventing typos and runtime errors.
- ✅ **Google Sheets as a CMS**: Use a single Google Sheet as a source of truth for designers, translators, and developers.
- ✅ **Automated Workflow**: Downloads and processes sheets in real-time, generating files directly into your project.
- ✅ **Xcode Integration**: Automatically adds the generated files to your Xcode project structure.
- ✅ **Modern & Native**: Built with Swift 6, leveraging modern concurrency. No external dependencies like Ruby required.
- ✅ **Dual Asset Support**: Manages both localizable strings and design system colors from the same tool.

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

Verify the installation by running:
```bash
swiftsheetgen --version
```

#### As a Package Dependency

Add `SwiftSheetGen` as a dependency to your `Package.swift` file to use its core libraries.

```swift
dependencies: [
    .package(url: "https://github.com/jorge/SwiftSheetGen.git", from: "1.0.0")
]
```

## Xcode Integration

SwiftSheetGen can automatically integrate the generated files into your Xcode project.

- **Compatibility:** This feature is fully compatible with **Xcode 15 and newer**.
- **Older Xcode Versions:** On older versions, if the generated files do not appear in the Project Navigator automatically, you may need to **drag and drop them manually from Finder** for the initial setup. Subsequent runs should then update the files in place.

For the integration to work, the directory you specify in the `--output-dir` option **must be the one that contains your `.xcodeproj` file**.

You can use the `--skip-xcode` flag to disable this feature entirely.

## Usage

### Basic Commands

To generate localizables, all you need to run is:
```bash
swiftsheetgen localizables ""
```
This command downloads the sheet, processes it for localizations, and saves the generated `.strings` and Swift files into a new `./Localizables` directory.

To generate colors, the command is:
```bash
swiftsheetgen colors ""
```
This command downloads the sheet, processes it for colors, and saves the generated Swift files into a new `./Colors` directory.

### Command Options

#### Shared Options (for `localizables` and `colors`)

| Option | Shorthand | Description | Default |
|---|---|---|---|
| `--output-dir` | | The directory where generated files will be saved. For Xcode integration, this must be the directory containing your `.xcodeproj` file. | `./` |
| `--verbose` | `-v` | Enable detailed logging for debugging. | `false` |
| `--keep-csv` | | Keep the downloaded CSV file for debugging purposes. | `false` |
| `--log-privacy-level` | | Set log privacy to `public` or `private`. | `public` |

#### `localizables` Specific Options

| Option | Description | Default |
|---|---|---|
| `--swift-enum-name` | Name for the generated Swift localization enum. | `L10n` |
| `--enum-separate-from-localizations` | Generate the Swift enum file in the base output directory instead of inside the `Localizables` subdirectory. | `false` |

The `colors` command does not have any specific options beyond the shared ones.

## Configuration

### Google Sheet Format

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

#### Localizations (`Strings.swift`)

```swift
// Auto-generated by SwiftSheetGen
import Foundation

public enum L10n: String, CaseIterable, Sendable {
    case commonAppNamePreText = "common_app_name_pre_text"
    case commonAppNameText = "common_app_name_text"
    case commonLanguageCodeText = "common_language_code_text"
    case loginForgotPasswordButton = "login_forgot_password_button"
    case loginPasswordText = "login_password_text"
    case loginSendButton = "login_send_button"
    case loginSignUpButton = "login_sign_up_button"
    case loginSignUpText = "login_sign_up_text"
    case loginTitleText = "login_title_text"
    case loginUsernameText = "login_username_text"
    case profileVersionText = "profile_version_text"

    /// Returns the localized string for this key
    public var localized: String {
        NSLocalizedString(self.rawValue, bundle: .main, comment: "")
    }
    
    /// Returns a formatted localized string with arguments
    public func localized(_ args: CVarArg...) -> String {
        String(format: localized, arguments: args)
    }
    
    /// Returns localized string with specific bundle
    public func localized(bundle: Bundle) -> String {
        NSLocalizedString(self.rawValue, bundle: bundle, comment: "")
    }
    
    /// SwiftUI compatible computed property
    @available(iOS 13.0, macOS 10.15, *)
    public var localizedString: LocalizedStringKey {
        LocalizedStringKey(self.rawValue)
    }
}
```

#### Colors (`Colors.swift`)

```swift
// Auto-generated by SwiftSheetGen
import SwiftUI

public extension ShapeStyle where Self == Color {
    /// primaryBackgroundColor
    static var primaryBackgroundColor: Color { .init(light: .init(hex: 0xFFF), dark: .init(hex: 0xFFF)) }
    /// secondaryBackgroundColor
    static var secondaryBackgroundColor: Color { .init(light: .init(hex: 0xFFF), dark: .init(hex: 0xFFF)) }
    /// tertiaryBackgroundColor
    static var tertiaryBackgroundColor: Color { .init(light: .init(hex: 0xFFF), dark: .init(hex: 0xFFF)) }
    /// primaryTextColor
    static var primaryTextColor: Color { .init(light: .init(hex: 0xFFF), dark: .init(hex: 0xFFF)) }
    /// secondaryTextColor
    static var secondaryTextColor: Color { .init(light: .init(hex: 0xFFF), dark: .init(hex: 0xFFF)) }
    /// tertiaryTextColor
    static var tertiaryTextColor: Color { .init(light: .init(hex: 0xFFF), dark: .init(hex: 0xFFF)) }
    /// placeholderTextColor
    static var placeholderTextColor: Color { .init(light: .init(hex: 0xFFF), dark: .init(hex: 0xFFF)) }
}

// ... plus extensions for dynamic colors and a SwiftUI preview
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

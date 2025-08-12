<p align="center">
  <img src="icon.png" alt="SwiftSheetGen Logo" width="500"/>
</p>

<p align="center">
  <strong>Generate type-safe Swift code for localizations and colors directly from a Google Sheet.</strong>
</p>

<p align="center">
  <a href="https://github.com/jorgemrht/SwiftSheetGen/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/jorgemrht/SwiftSheetGen/ci.yml?branch=main&style=for-the-badge" alt="Build Status"></a>
  <a href="https://github.com/jorgemrht/SwiftSheetGen/releases"><img src="https://img.shields.io/github/v/release/jorgemrht/SwiftSheetGen?include_prereleases&style=for-the-badge" alt="Latest Release"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0+-orange?style=for-the-badge" alt="Swift Version"></a>
  <a href="/LICENSE"><img src="https://img.shields.io/github/license/jorgemrht/SwiftSheetGen?style=for-the-badge" alt="License"></a>
</p>

---

**SwiftSheetGen** is a command-line tool that transforms your team's collaborative Google Sheets for strings and colors into compile-time safe Swift code, eliminating manual errors and keeping your Xcode project in perfect sync.

## Overview

Manually managing localizable strings and design system colors is tedious and error-prone. A typo in a key, a color hex copied incorrectly, or a file not added to the Xcode project can lead to runtime crashes and UI inconsistencies.

SwiftSheetGen solves this by using a **Google Sheet as a single source of truth**. This allows designers, translators, and developers to collaborate in one place, while the tool automates the generation of type-safe Swift code that you can use with confidence.

## Getting started

The easiest way to get started is to use the SwiftSheetGen command-line tool included with this package:

1. Add the tap (a repository of formulas): **brew tap jorgemrht/swiftSheetGen**

2. Install the tool: **brew install swiftsheetgen**

### Updating
To update to the latest version, simply run the upgrade command:
```bash
brew upgrade swiftsheetgen
```

### From Source
Build the tool from the source and move it to a location in your `PATH`.
```bash
git clone https://github.com/jorgemrht/SwiftSheetGen.git
cd SwiftSheetGen
swift build -c release
sudo cp .build/release/swiftsheetgen /usr/local/bin/
```

## Quick Start


1.  **Get your Google Sheet URL.** The sheet must be public. Here is a valid URL:
    -   Published to web URL: `https://docs.google.com/spreadsheets/d/e/1a2b3c4d5e6f7g8h9i0j.../pubhtml`

3.  **Run the command:**
    ```bash
    # For localizations
    swiftsheetgen localization "https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID/export?format=csv"
     ```
     
    ```bash
    # For colors
    swiftsheetgen colors "https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID/export?format=csv&gid=YOUR_GID"
    ```

    This will generate the necessary files in a new subdirectory (`./Localizables` or `./Colors`). That's it!


## Detailed Usage Guide

### Commands

SwiftSheetGen has two main commands:

-   `localization`: Generates `.strings` files for each language and a type-safe `L10n` enum to access them.
-   `colors`: Generates a `Color` extension with static properties for your design system colors.

### Shared Options

These options are available for both the `localization` and `colors` commands:

| Option | Shorthand | Description | Default |
|---|---|---|---|
| `--output-dir` | | The directory where generated files will be saved. For Xcode integration, this must be the directory containing your `.xcodeproj` file. | `./` |
| `--verbose` | `-v` | Enable detailed logging for debugging. | `false` |
| `--keep-csv` | | Keep the downloaded CSV file for debugging purposes. | `false` |
| `--log-privacy-level` | | Set log privacy to `public` or `private`. | `public` |

### `localization` Specific Options

| Option | Description | Default |
|---|---|---|
| `--swift-enum-name` | Name for the generated Swift localization enum. | `L10n` |
| `--enum-separate-from-localizations` | Generate the Swift enum file in the base output directory instead of inside the `Localizables` subdirectory. | `false` |

## Integrations

### Xcode
The tool automatically integrates the generated files into your Xcode project, adding them to the Project Navigator and the correct build phases.

- **Project Compatibility:** Automatic integration is only supported for projects created or last saved with **Xcode 15 or newer**. The tool modifies the `.pbxproj` file, and its structure changes between major Xcode versions.
- **Older Projects (Xcode 14 and below):** If your project was created with an older version of Xcode, the automatic integration will be skipped to avoid corrupting the project file. In this case, you must **drag and drop the generated files manually from Finder** into your Xcode Project Navigator for the initial setup.

#### How Automatic Integration Works
For the tool to find your project file (`.xcodeproj`), it automatically searches the current directory and up to two parent directories. This makes integration seamless in most cases.

*   **Running from the project root or a subdirectory:**
    If your terminal's current location is inside your project's folder structure, the tool will find the `.xcodeproj` automatically.

    ```bash
    # If your project is at /path/to/YourApp, you can run the command from:
    # /path/to/YourApp
    # /path/to/YourApp/Subfolder
    # /path/to/YourApp/Subfolder/AnotherSubfolder

    swiftsheetgen localization "..."
    ```

*   **Using the `--output-dir` option:**
    The `--output-dir` flag is optional and serves two purposes:
    1.  It specifies where the generated files should be saved.
    2.  It acts as the starting point for the Xcode project search.

    You only need this if you run the command from a location outside your project's folder or if you want to save the generated files in a very specific place.

    ```bash
    # Run from anywhere by telling the tool where your project is
    swiftsheetgen localization "..." --output-dir /path/to/YourApp
    ```

### Tuist
If a `Project.swift` or `Workspace.swift` file is detected in your project's root, SwiftSheetGen will skip the automatic Xcode integration and print instructions for you to add the generated files to your Tuist manifest.

## Google Sheet Setup

Your Google Sheet must be **publicly accessible** ("Anyone with the link can view") and have a specific structure.

#### For Localizations
The sheet requires columns for `key`, `comment`, and each language code (e.g., `en`, `es`).

| key | comment | en | es |
|---|---|---|---|
| `login.title` | Title on the login screen | Welcome! | ¡Bienvenido! |
| `login.button.signIn` | Sign in button text | Sign In | Iniciar Sesión |

#### For Colors
The sheet requires columns for `name`, `anyHex`, `lightHex`, and `darkHex`.

| name | anyHex | lightHex | darkHex |
|---|---|---|---|
| `primary` | | `#68478E` | `#866CA5` |
| `onPrimary` | | `#FFFFFF` | `#00172E` |
| `background` | `#F2F2F7` | | |

## FAQ

**Q: How do I use a private Google Sheet?**
**A:** SwiftSheetGen requires the sheet to be publicly accessible to download the CSV data. You can achieve this by going to "File" > "Share" > "Publish to web" in Google Sheets and publishing it as a CSV document. This creates a public URL without making the sheet itself public.

**Q: Will you support the new Xcode Strings Catalog (`.xcstrings`)?**
**A:** Yes, support for the modern Xcode Strings Catalog is planned for a future release. This will allow for richer localization features and even better integration with Xcode.

**Q: Can I customize the generated Swift code?**
**A:** For localizations, you can use the `--swift-enum-name` option to change the name of the generated enum. Other customizations are not available at this time but may be considered for future versions.

**Q: What happens if the Xcode integration fails?**
**A:** If the files don't appear in your project, you can simply drag the generated output directory (`Localizables` or `Colors`) from Finder into your Xcode Project Navigator. Make sure to select your main app target when prompted.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


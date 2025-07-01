import ArgumentParser

public struct SharedOptions: ParsableArguments {
    @Argument(help: "📊 Google Sheets URL (must be publicly accessible)")
    public var sheetsURL: String

    @Option(name: .long, help: "📁 Target directory for generated files (default: current directory)")
    public var outputDir: String = "./"

    @Flag(name: [.customShort("v"), .long], help: "📝 Enable detailed logging for debugging")
    public var verbose: Bool = false

    @Flag(name: .long, help: "⏭️ Skip automatic integration of generated files into Xcode project")
    public var skipXcode: Bool = false

    @Flag(name: .long, help: "💾 Keep downloaded CSV file for debugging")
    public var keepCSV: Bool = false

    @Flag(name: .long, help: "🔄 Update existing files in Xcode")
    public var forceUpdate: Bool = false

    @Option(name: .long, help: "Privacy level for log output: public (default) or private")
    public var logPrivacyLevel: String = "public"

    public init() {}
}
import Testing
import Foundation
import ArgumentParser
@testable import SwiftSheetGenCLICore

@Suite
struct SharedOptionsTest {
    
    // MARK: - Basic Parsing Tests
    
    @Test("SharedOptions correctly parses valid Google Sheets URLs",
          arguments: [
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQDNyRnXQ5jCWeN3AL9XX0a/pubhtml",
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B1CS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
          ])
    func sharedOptionsValidGoogleSheetsURLParsing(url: String) throws {
        let options = try SharedOptions.parse([url])
        
        #expect(options.sheetsURL == url)
        #expect(!options.verbose)
        #expect(!options.keepCSV)
        #expect(options.outputDir == "./")
        #expect(options.logPrivacyLevel == "public")
    }
    
    @Test("SharedOptions handles URL parsing with additional CLI parameters")
    func sharedOptionsComplexParameterCombinations() throws {
        let arguments = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml",
            "--output-dir", "/custom/output/path",
            "--verbose",
            "--keep-csv",
            "--log-privacy-level", "private"
        ]
        
        let options = try SharedOptions.parse(arguments)
        
        #expect(options.sheetsURL == "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml")
        #expect(options.outputDir == "/custom/output/path")
        #expect(options.verbose == true)
        #expect(options.keepCSV == true)
        #expect(options.logPrivacyLevel == "private")
    }
    
    @Test("SharedOptions validates required URL argument presence")
    func sharedOptionsRequiredArgumentValidation() {
        #expect(throws: (any Error).self) {
            _ = try SharedOptions.parse([])
        }
        
        #expect(throws: (any Error).self) {
            _ = try SharedOptions.parse(["--verbose", "--keep-csv"])
        }
    }
    
    // MARK: - Flag Variations Tests
    
    @Test("SharedOptions handles verbose flag variations", 
          arguments: [
              (["url", "-v"], true),
              (["url", "--verbose"], true), 
              (["url"], false)
          ])
    func sharedOptionsVerboseFlagHandling(args: [String], expectedVerbose: Bool) throws {
        let options = try SharedOptions.parse(args)
        #expect(options.verbose == expectedVerbose)
    }
    
    @Test("SharedOptions handles keep-csv flag variations",
          arguments: [
              (["url", "--keep-csv"], true),
              (["url"], false)
          ])
    func sharedOptionsKeepCSVFlagHandling(args: [String], expectedKeepCSV: Bool) throws {
        let options = try SharedOptions.parse(args)
        #expect(options.keepCSV == expectedKeepCSV)
    }
    
    // MARK: - Path Handling Tests
    
    @Test("SharedOptions handles output directory path normalization",
          arguments: [
              ("./", "./"),
              ("/absolute/path", "/absolute/path"),
              ("relative/path", "relative/path"),
              ("~/home/path", "~/home/path"),
              ("/path/with spaces/", "/path/with spaces/"),
              ("", "")
          ])
    func sharedOptionsOutputDirectoryNormalization(inputPath: String, expectedPath: String) throws {
        let args = inputPath.isEmpty ? 
            ["https://example.com/sheet"] : 
            ["https://example.com/sheet", "--output-dir", inputPath]
            
        let options = try SharedOptions.parse(args)
        
        if inputPath.isEmpty {
            #expect(options.outputDir == "./")
        } else {
            #expect(options.outputDir == expectedPath)
        }
    }
    
    @Test("SharedOptions handles special characters in paths and URLs")
    func sharedOptionsSpecialCharacterHandling() throws {
        let urlWithParams = "https://docs.google.com/spreadsheets/d/test123/edit?usp=sharing&gid=0#special"
        let pathWithSpaces = "/path/with special chars/and-symbols_123"
        
        let options = try SharedOptions.parse([
            urlWithParams,
            "--output-dir", pathWithSpaces
        ])
        
        #expect(options.sheetsURL == urlWithParams)
        #expect(options.outputDir == pathWithSpaces)
    }
    
    @Test("SharedOptions handles edge cases in URL format")
    func sharedOptionsURLEdgeCaseHandling() throws {
        let edgeCaseURLs = [
            "https://docs.google.com/spreadsheets/d//edit",
            "https://docs.google.com/spreadsheets/d/a/b/c/d/e/f/g/h/i/j/edit",
            "https://docs.google.com/spreadsheets/d/test-with-hyphens_and_underscores.123/edit"
        ]
        
        for url in edgeCaseURLs {
            let options = try SharedOptions.parse([url])
            #expect(options.sheetsURL == url)
        }
    }
    
    // MARK: - Privacy Level Tests
    
    @Test("SharedOptions log privacy level validation",
          arguments: [
              ("public", "public"),
              ("private", "private"),
              ("Public", "Public"),
              ("PRIVATE", "PRIVATE"),
              ("invalid", "invalid")
          ])
    func sharedOptionsLogPrivacyLevelHandling(inputLevel: String, expectedLevel: String) throws {
        let options = try SharedOptions.parse([
            "https://example.com/sheet",
            "--log-privacy-level", inputLevel
        ])
        
        #expect(options.logPrivacyLevel == expectedLevel)
    }
    
    @Test("SharedOptions handles privacy level edge cases")
    func sharedOptionsPrivacyLevelEdgeCases() throws {
        let edgeCases = [
            "",
            "  private  ",
            "\tpublic\t",
            "\nprivate\n",
            "pRiVaTe",
            "PUBLIC",
            "randomString",
            "12345"
        ]
        
        for privacyLevel in edgeCases {
            let options = try SharedOptions.parse([
                "https://example.com/sheet",
                "--log-privacy-level", privacyLevel
            ])
            #expect(options.logPrivacyLevel == privacyLevel)
        }
    }
    
    // MARK: - Argument Order Tests
    
    @Test("SharedOptions maintains argument order independence")
    func sharedOptionsArgumentOrderIndependence() throws {
        let url = "https://docs.google.com/spreadsheets/d/test/edit"
        
        let options1 = try SharedOptions.parse([
            url, "--verbose", "--output-dir", "/path1", "--keep-csv", "--log-privacy-level", "private"
        ])
        
        let options2 = try SharedOptions.parse([
            "--log-privacy-level", "private", "--keep-csv", url, "--output-dir", "/path1", "--verbose"
        ])
        
        #expect(options1.sheetsURL == options2.sheetsURL)
        #expect(options1.outputDir == options2.outputDir)
        #expect(options1.verbose == options2.verbose)
        #expect(options1.keepCSV == options2.keepCSV)
        #expect(options1.logPrivacyLevel == options2.logPrivacyLevel)
    }
    
    @Test("SharedOptions handles mixed argument positioning")
    func sharedOptionsMixedArgumentPositioning() throws {
        let variations = [
            ["https://test.com", "--verbose", "--output-dir", "/path", "--keep-csv"],
            ["--verbose", "https://test.com", "--output-dir", "/path", "--keep-csv"],
            ["--output-dir", "/path", "https://test.com", "--verbose", "--keep-csv"],
            ["--keep-csv", "--verbose", "--output-dir", "/path", "https://test.com"]
        ]
        
        for args in variations {
            let options = try SharedOptions.parse(args)
            #expect(options.sheetsURL == "https://test.com")
            #expect(options.outputDir == "/path")
            #expect(options.verbose == true)
            #expect(options.keepCSV == true)
        }
    }
    
    // MARK: - Default Values Tests
    
    @Test("SharedOptions default values consistency")
    func sharedOptionsDefaultValueValidation() throws {
        let minimalOptions = try SharedOptions.parse(["https://example.com/sheet"])
        
        #expect(minimalOptions.outputDir == "./")
        #expect(minimalOptions.verbose == false)
        #expect(minimalOptions.keepCSV == false)
        #expect(minimalOptions.logPrivacyLevel == "public")
    }
    
    @Test("SharedOptions default values with partial configuration")
    func sharedOptionsPartialConfigurationDefaults() throws {
        let partialConfigs = [
            (args: ["https://test.com", "--verbose"], expectVerbose: true, expectKeepCSV: false),
            (args: ["https://test.com", "--keep-csv"], expectVerbose: false, expectKeepCSV: true),
            (args: ["https://test.com", "--output-dir", "/custom"], expectVerbose: false, expectKeepCSV: false)
        ]
        
        for (args, expectVerbose, expectKeepCSV) in partialConfigs {
            let options = try SharedOptions.parse(args)
            #expect(options.verbose == expectVerbose)
            #expect(options.keepCSV == expectKeepCSV)
            #expect(options.logPrivacyLevel == "public")
        }
    }
    
    // MARK: - Validation Tests
    
    @Test("SharedOptions validates URL parameter types")
    func sharedOptionsURLParameterTypeValidation() throws {
        let validURLs = [
            "https://docs.google.com/spreadsheets/d/e/test/pubhtml",
            "http://docs.google.com/spreadsheets/d/e/test/pub?output=csv",
            "https://docs.google.com/spreadsheets/d/e/complex-id_123.test/pubhtml"
        ]
        
        for url in validURLs {
            #expect(throws: Never.self) {
                _ = try SharedOptions.parse([url])
            }
        }
    }
    
    @Test("SharedOptions validates output directory parameter types")
    func sharedOptionsOutputDirectoryParameterValidation() throws {
        let validPaths = [
            "/absolute/path",
            "relative/path",
            "./current/path",
            "../parent/path",
            "~/home/path",
            "/path/with spaces",
            "/path-with-special_chars.123"
        ]
        
        for path in validPaths {
            #expect(throws: Never.self) {
                _ = try SharedOptions.parse(["https://test.com", "--output-dir", path])
            }
        }
    }
    
    // MARK: - Help and Documentation Tests
    
    @Test("SharedOptions help text accessibility")
    func sharedOptionsHelpDocumentation() {
        #expect(throws: (any Error).self) {
            _ = try SharedOptions.parse(["--help"])
        }
    }
    
    @Test("SharedOptions handles invalid flag combinations gracefully")
    func sharedOptionsInvalidFlagCombinations() {
        let invalidCombinations = [
            ["--help", "https://test.com"],
            ["--version"],
            ["--nonexistent-flag", "https://test.com"]
        ]
        
        for args in invalidCombinations {
            #expect(throws: (any Error).self) {
                _ = try SharedOptions.parse(args)
            }
        }
    }
    
    // MARK: - Performance and Edge Cases
    
    @Test("SharedOptions handles very long argument values")
    func sharedOptionsLongArgumentValues() throws {
        let longURL = "https://docs.google.com/spreadsheets/d/e/" + String(repeating: "a", count: 1000) + "/pubhtml"
        let longPath = "/" + String(repeating: "path/", count: 100) + "end"
        let longPrivacyLevel = String(repeating: "private", count: 10)
        
        let options = try SharedOptions.parse([
            longURL,
            "--output-dir", longPath,
            "--log-privacy-level", longPrivacyLevel
        ])
        
        #expect(options.sheetsURL == longURL)
        #expect(options.outputDir == longPath)
        #expect(options.logPrivacyLevel == longPrivacyLevel)
    }
    
    @Test("SharedOptions handles unicode and special characters")
    func sharedOptionsUnicodeAndSpecialCharacters() throws {
        let unicodeURL = "https://docs.google.com/spreadsheets/d/e/tést-ũnicõdè-123/pubhtml"
        let unicodePath = "/path/with/ünicødé/chàracters/测试"
        
        let options = try SharedOptions.parse([
            unicodeURL,
            "--output-dir", unicodePath
        ])
        
        #expect(options.sheetsURL == unicodeURL)
        #expect(options.outputDir == unicodePath)
    }
    
    @Test("SharedOptions parsing is consistent across multiple invocations")
    func sharedOptionsParsingConsistency() throws {
        let args = [
            "https://docs.google.com/spreadsheets/d/e/2PACX-consistent/pubhtml",
            "--output-dir", "/consistent/path",
            "--verbose",
            "--keep-csv",
            "--log-privacy-level", "private"
        ]
        
        let options1 = try SharedOptions.parse(args)
        let options2 = try SharedOptions.parse(args)
        let options3 = try SharedOptions.parse(args)
        
        #expect(options1.sheetsURL == options2.sheetsURL)
        #expect(options2.sheetsURL == options3.sheetsURL)
        #expect(options1.outputDir == options2.outputDir)
        #expect(options2.outputDir == options3.outputDir)
        #expect(options1.verbose == options2.verbose)
        #expect(options2.verbose == options3.verbose)
        #expect(options1.keepCSV == options2.keepCSV)
        #expect(options2.keepCSV == options3.keepCSV)
        #expect(options1.logPrivacyLevel == options2.logPrivacyLevel)
        #expect(options2.logPrivacyLevel == options3.logPrivacyLevel)
    }
}

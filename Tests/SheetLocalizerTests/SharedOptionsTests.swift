import Testing
import Foundation
import ArgumentParser
@testable import SwiftSheetGenCLICore

@Suite
struct SharedOptionsTests {
    
    // MARK: - Google Sheets URL Validation
    
    @Test("SharedOptions correctly parses valid Google Sheets URLs",
          arguments: [
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B14_3YiqQDNyRnXQ5jCWeN3AL9XX0a/pubhtml",
              "https://docs.google.com/spreadsheets/d/e/2PACX-1vRj3aWiQffPzhrWzu1E8B1CS3fJ523VIu3VDNyRnXQ5jCWeN3AL9XX0a/pub?output=csv"
          ])
    func sharedOptionsValidGoogleSheetsURLParsing(url: String) throws {
        let options = try SharedOptions.parse([url])
        
        #expect(options.sheetsURL == url, "Sheets URL should be parsed exactly as provided")
        #expect(!options.verbose, "Verbose should default to false")
        #expect(!options.keepCSV, "Keep CSV should default to false") 
        #expect(options.outputDir == "./", "Output directory should default to current directory")
        #expect(options.logPrivacyLevel == "public", "Log privacy level should default to public")
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
        
        #expect(options.sheetsURL == "https://docs.google.com/spreadsheets/d/e/2PACX-1vTest123/pubhtml", "Sheets URL should be preserved")
        #expect(options.outputDir == "/custom/output/path", "Custom output directory should be set")
        #expect(options.verbose == true, "Verbose flag should be enabled")
        #expect(options.keepCSV == true, "Keep CSV flag should be enabled")
        #expect(options.logPrivacyLevel == "private", "Privacy level should be set to private")
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
    
    @Test("SharedOptions handles verbose flag variations", 
          arguments: [
              (["url", "-v"], true),
              (["url", "--verbose"], true), 
              (["url"], false)
          ])
    func sharedOptionsVerboseFlagHandling(args: [String], expectedVerbose: Bool) throws {
        let options = try SharedOptions.parse(args)
        #expect(options.verbose == expectedVerbose, "Verbose flag should match expected state")
    }
    
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
            #expect(options.outputDir == "./", "Default output directory should be current directory")
        } else {
            #expect(options.outputDir == expectedPath, "Output directory should match expected normalized path")
        }
    }
    
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
        
        #expect(options.logPrivacyLevel == expectedLevel, "Privacy level should be preserved as provided")
    }
    
    @Test("SharedOptions maintains argument order independence")
    func sharedOptionsArgumentOrderIndependence() throws {
        let url = "https://docs.google.com/spreadsheets/d/test/edit"
        
        let options1 = try SharedOptions.parse([
            url, "--verbose", "--output-dir", "/path1", "--keep-csv", "--log-privacy-level", "private"
        ])
        
        let options2 = try SharedOptions.parse([
            "--log-privacy-level", "private", "--keep-csv", url, "--output-dir", "/path1", "--verbose"
        ])
        
        #expect(options1.sheetsURL == options2.sheetsURL, "URLs should match regardless of argument order")
        #expect(options1.outputDir == options2.outputDir, "Output dirs should match regardless of order")
        #expect(options1.verbose == options2.verbose, "Verbose flags should match regardless of order")
        #expect(options1.keepCSV == options2.keepCSV, "Keep CSV flags should match regardless of order")
        #expect(options1.logPrivacyLevel == options2.logPrivacyLevel, "Privacy levels should match regardless of order")
    }
    
    @Test("SharedOptions handles special characters in paths and URLs")
    func sharedOptionsSpecialCharacterHandling() throws {
        let urlWithParams = "https://docs.google.com/spreadsheets/d/test123/edit?usp=sharing&gid=0#special"
        let pathWithSpaces = "/path/with special chars/and-symbols_123"
        
        let options = try SharedOptions.parse([
            urlWithParams,
            "--output-dir", pathWithSpaces
        ])
        
        #expect(options.sheetsURL == urlWithParams, "URL with special characters should be preserved")
        #expect(options.outputDir == pathWithSpaces, "Path with special characters should be preserved")
    }
    
    @Test("SharedOptions default values consistency")
    func sharedOptionsDefaultValueValidation() throws {
        let minimalOptions = try SharedOptions.parse(["https://example.com/sheet"])
        
        #expect(minimalOptions.outputDir == "./", "Default output directory should be current directory")
        #expect(minimalOptions.verbose == false, "Default verbose should be false")
        #expect(minimalOptions.keepCSV == false, "Default keepCSV should be false") 
        #expect(minimalOptions.logPrivacyLevel == "public", "Default log privacy should be public")
    }
    
    @Test("SharedOptions help text accessibility")
    func sharedOptionsHelpDocumentation() {
        #expect(throws: (any Error).self) {
            _ = try SharedOptions.parse(["--help"])
        }
    }
    
    @Test("SharedOptions handles edge cases in URL format")
    func sharedOptionsURLEdgeCaseHandling() throws {
        let edgeCaseURLs = [
            "https://docs.google.com/spreadsheets/d//edit",  // Empty document ID
            "https://docs.google.com/spreadsheets/d/a/b/c/d/e/f/g/h/i/j/edit", // Very long path
            "https://docs.google.com/spreadsheets/d/test-with-hyphens_and_underscores.123/edit" // Complex ID
        ]
        
        for url in edgeCaseURLs {
            let options = try SharedOptions.parse([url])
            #expect(options.sheetsURL == url, "Edge case URL '\(url)' should be preserved exactly")
        }
    }
}

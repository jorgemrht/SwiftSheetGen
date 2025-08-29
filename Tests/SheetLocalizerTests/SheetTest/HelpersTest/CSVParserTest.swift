import Testing
import Foundation
@testable import SheetLocalizer

@Suite("CSVParser Tests")
struct CSVParserTest {
    
    
    @Test("Parse localization CSV with headers and data validation")
    func parseLocalizationCSVStructure() throws {
        let result = try CSVParser.parse(SharedTestData.localizationCSV)
        
        #expect(result.count > 0)
        
        let headerRow = result.first { row in
            row.contains("[View]") && row.contains("[Item]") && row.contains("[Type]")
        }
        #expect(headerRow != nil)
        guard let header = headerRow else { return }
        
        #expect(header.count == 7)
        #expect(header[0] == "[Check]")
        #expect(header[1] == "[View]")
        #expect(header[2] == "[Item]")
        #expect(header[3] == "[Type]")
        #expect(header[4] == "es")
        #expect(header[5] == "en")
        #expect(header[6] == "fr")
        
        let dataRows = result.filter { row in
            !row.isEmpty && 
            row != header &&
            row.first != "[END]" &&
            row.count >= 7
        }
        
        #expect(dataRows.count >= 10)
        
        let firstDataRow = dataRows[0]
        #expect(firstDataRow[1] == "common") // View
        #expect(firstDataRow[2] == "app_name") // Item
        #expect(firstDataRow[3] == "text") // Type
        #expect(firstDataRow[4] == "jorgemrht") // Spanish
        #expect(firstDataRow[5] == "My App") // English
        #expect(firstDataRow[6] == "Mon App") // French
    }
    
    @Test("Parse localization CSV with quoted fields and special characters")
    func parseLocalizationCSVQuotedFields() throws {
        let result = try CSVParser.parse(SharedTestData.localizationCSV)
        
        let forgotPasswordRow = result.first { row in
            row.count > 2 && row[2] == "forgot_password"
        }
        
        #expect(forgotPasswordRow != nil)
        if let row = forgotPasswordRow {
            #expect(row[4] == "¿Contraseña olvidada?")
            #expect(row[5] == "Forgot password?")
            #expect(row[6] == "Mot de passe oublié?")
        }
    }
    
    @Test("Parse localization CSV with template variables")
    func parseLocalizationCSVTemplateVariables() throws {
        let result = try CSVParser.parse(SharedTestData.localizationCSV)
        
        let versionRow = result.first { row in
            row.count > 2 && row[2] == "version"
        }
        
        #expect(versionRow != nil)
        if let row = versionRow {
            #expect(row[4].contains("{{version}}")) // Spanish
            #expect(row[4].contains("{{build}}"))
            #expect(row[5].contains("{{version}}")) // English
            #expect(row[5].contains("{{build}}"))
        }
        
        let userCountRow = result.first { row in
            row.count > 2 && row[2] == "user_count"
        }
        
        #expect(userCountRow != nil)
        if let row = userCountRow {
            #expect(row[4].contains("{{count}}")) // Spanish
            #expect(row[5].contains("{{count}}")) // English
            #expect(row[6].contains("{{count}}")) // French
        }
    }
    
    @Test("Parse localization CSV end marker validation")
    func parseLocalizationCSVEndMarker() throws {
        let result = try CSVParser.parse(SharedTestData.localizationCSV)
        
        let endRow = result.first { $0.first == "[END]" }
        #expect(endRow != nil)
        
        if let endRow = endRow {
            #expect(endRow.count >= 1)
            #expect(endRow[0] == "[END]")
        }
    }
    
    
    @Test("Parse colors CSV structure and data validation")
    func parseColorsCSVStructure() throws {
        let result = try CSVParser.parse(SharedTestData.colorsCSV)
        
        #expect(result.count > 0)
        
        let colorRows = result.filter { row in
            row.count >= 6 && 
            !row[1].isEmpty && 
            row[1] != "[Color Name]" && 
            row[1] != "[COMMENT]" &&
            row.first != "[END]" &&
            !row[1].contains("[")
        }
        
        #expect(colorRows.count >= 7)
        
        let primaryBgRow = colorRows.first { $0[1] == "primaryBackgroundColor" }
        #expect(primaryBgRow != nil)
        if let row = primaryBgRow {
            #expect(row[1] == "primaryBackgroundColor") // Color name
            #expect(row[2] == "#FFF") // Any hex
            #expect(row[3] == "#FFF") // Light hex  
            #expect(row[4] == "#FFF") // Dark hex
            #expect(row[5].contains("color de fondo principal")) // Description
        }
    }
    
    @Test("Parse colors CSV with quoted descriptions")
    func parseColorsCSVQuotedDescriptions() throws {
        let result = try CSVParser.parse(SharedTestData.colorsCSV)
        
        let secondaryTextRow = result.first { row in
            row.count > 1 && row[1] == "secondaryTextColor"
        }
        
        #expect(secondaryTextRow != nil)
        if let row = secondaryTextRow {
            #expect(row[5].contains("menor énfasis"))
            #expect(row[5].contains("subtítulos"))
        }
    }
    
    @Test("Parse colors CSV end marker validation")
    func parseColorsCSVEndMarker() throws {
        let result = try CSVParser.parse(SharedTestData.colorsCSV)
        
        let endRow = result.first { $0.first == "[END]" }
        #expect(endRow != nil)
        
        if let endRow = endRow {
            #expect(endRow[0] == "[END]")
        }
    }
    
    
    @Test("Streaming parser for localization CSV")
    func streamingParserLocalizationCSV() async throws {
        let tempFile = createTempFile(content: SharedTestData.localizationCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = try await CSVParser.parseStream(fileURL: tempFile)
        
        #expect(result.count > 0)
        
        let headerExists = result.contains { row in
            row.contains("[View]") && row.contains("[Item]")
        }
        #expect(headerExists)
        
        let dataRows = result.filter { row in
            row.count >= 7 &&
            !row.contains("[View]") && // not header
            row.first != "[END]"
        }
        #expect(dataRows.count >= 1)
    }
    
    @Test("Streaming parser for colors CSV")
    func streamingParserColorsCSV() async throws {
        let tempFile = createTempFile(content: SharedTestData.colorsCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = try await CSVParser.parseStream(fileURL: tempFile)
        
        #expect(result.count > 0)
        
        let nonEmptyRows = result.filter { row in
            row.count > 0 && !row[0].isEmpty
        }
        #expect(nonEmptyRows.count >= 1)
        
        let hasColorContent = result.contains { row in
            row.count > 1 && (
                row[1].contains("Color") || 
                row[1].contains("primary") ||
                row[1].contains("secondary") ||
                row[1].contains("Background")
            )
        }
        #expect(hasColorContent)
    }
    
    
    @Test("File-based parsing for localization CSV")
    func fileParsingLocalizationCSV() async throws {
        let tempFile = createTempFile(content: SharedTestData.localizationCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        do {
            let result = try await CSVParser.parse(filePath: tempFile.path)
            #expect(result.count > 0)
            
            let hasValidData = result.contains { row in
                row.count >= 7 && row[1] == "common" && row[2] == "app_name"
            }
            #expect(hasValidData)
        } catch {
            #expect(error is SheetLocalizerError)
        }
    }
    
    @Test("File-based parsing for colors CSV")
    func fileParsingColorsCSV() async throws {
        let tempFile = createTempFile(content: SharedTestData.colorsCSV)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let result = try await CSVParser.parse(filePath: tempFile.path)
        
        #expect(result.count > 0)
        
        let primaryColorRow = result.first { row in
            row.count > 1 && row[1] == "primaryBackgroundColor"
        }
        
        #expect(primaryColorRow != nil)
    }
    
    
    @Test("Parse to keyed rows error handling")
    func parseToKeyedRowsErrorHandling() throws {
        #expect(throws: SheetLocalizerError.self) {
            _ = try CSVParser.parseToKeyedRows(SharedTestData.localizationCSV)
        }
    }
    
    
    @Test("CSV column count validation")
    func csvColumnCountValidation() throws {
        let locResult = try CSVParser.parse(SharedTestData.localizationCSV)
        let headerRow = locResult.first { row in
            row.contains("[View]") && row.contains("[Item]")
        }
        
        guard let header = headerRow else {
            throw SheetLocalizerError.csvParsingError("Header not found")
        }
        
        let headerColumnCount = header.count
        let validRows = locResult.filter { $0.count == headerColumnCount }
        let totalDataRows = locResult.filter { $0.first != "[END]" }.count
        
        #expect(validRows.count >= totalDataRows - 2)
    }
 
    private func createTempFile(content: String) -> URL {
        SharedTestData.createTempFile(content: content)
    }
}

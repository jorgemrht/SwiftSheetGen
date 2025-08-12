import Testing
import Foundation
@testable import SheetLocalizer

@Suite
struct CSVFormatTests {
    
    @Test
    func csvParserRealLocalizationFormat() throws {
        let result = try CSVParser.parse(SharedTestData.localizationCSV)
        
        #expect(result.count > 0)
        
        let headerRow = result[0]
        #expect(headerRow.count == 7)
        #expect(headerRow[0] == "[Check]")
        #expect(headerRow[1] == "[View]")
        #expect(headerRow[2] == "[Item]")
        #expect(headerRow[3] == "[Type]")
        #expect(headerRow[4] == "es")
        #expect(headerRow[5] == "en")
        #expect(headerRow[6] == "fr")
        
        let dataRows = result.dropFirst().filter { row in
            row.first != "[END]"
        }
        #expect(dataRows.count >= 10)
        
        let firstDataRow = Array(dataRows)[0]
        #expect(firstDataRow[1] == "common")
        #expect(firstDataRow[2] == "app_name")
        #expect(firstDataRow[3] == "text")
        #expect(firstDataRow[4] == "jorgemrht")
        #expect(firstDataRow[5] == "My App")
        #expect(firstDataRow[6] == "Mon App")
    }
    
    @Test
    func csvParserQuotedFieldsLocalization() throws {
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
    
    @Test
    func csvParserTemplateVariables() throws {
        let result = try CSVParser.parse(SharedTestData.localizationCSV)
        
        let versionRow = result.first { row in
            row.count > 2 && row[2] == "version"
        }
        
        #expect(versionRow != nil)
        if let row = versionRow {
            #expect(row[4].contains("{{version}}")) // Spanish template
            #expect(row[4].contains("{{build}}"))
            #expect(row[5].contains("{{version}}")) // English template
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
    
    @Test
    func csvParserRealColorsFormat() throws {
        let result = try CSVParser.parse(SharedTestData.colorsCSV)
        
        #expect(result.count > 0)
        
        let colorRows = result.filter { row in
            row.count >= 6 && 
            !row[1].isEmpty && 
            row[1] != "[Color Name]" && 
            row[1] != "[COMMENT]" &&
            row.first != "[END]"
        }
        
        #expect(colorRows.count >= 7)
        
        let primaryBgRow = colorRows.first { $0[1] == "primaryBackgroundColor" }
        #expect(primaryBgRow != nil)
        if let row = primaryBgRow {
            #expect(row[1] == "primaryBackgroundColor")
            #expect(row[2] == "#FFF")
            #expect(row[3] == "#FFF")
            #expect(row[4] == "#FFF")
            #expect(row[5].contains("color de fondo principal"))
        }
    }
    
    @Test
    func csvParserQuotedDescriptionsColors() throws {
        let result = try CSVParser.parse(SharedTestData.colorsCSV)
        
        let secondaryTextRow = result.first { row in
            row.count > 1 && row[1] == "secondaryTextColor"
        }
        
        #expect(secondaryTextRow != nil)
        if let row = secondaryTextRow {
            #expect(row[5].contains("menor énfasis"))
        }
    }
    
    @Test
    func csvToLocalizationEntryMapping() throws {
        let result = try CSVParser.parse(SharedTestData.localizationCSV)
        
        let headerRow = result.first { row in
            row.contains("[View]") && row.contains("[Item]") && row.contains("[Type]")
        }
        #expect(headerRow != nil)
        guard let header = headerRow else { return }
        
        let dataRows = result.filter { row in
            !row.isEmpty && 
            row.first != "[END]" && 
            row != header &&
            row.count >= 7
        }
        
        #expect(dataRows.count >= 10)
        
        let firstRow = dataRows[0]
        #expect(firstRow[1] == "common")
        #expect(firstRow[2] == "app_name")
        #expect(firstRow[3] == "text")
        #expect(firstRow[4] == "jorgemrht")
        #expect(firstRow[5] == "My App")
        #expect(firstRow[6] == "Mon App")
    }
    
    @Test
    func csvToColorEntryMapping() throws {
        let result = try CSVParser.parse(SharedTestData.colorsCSV)
        
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
            
            let name = row[1]
            let _ = row[2].isEmpty ? nil : row[2]
            let lightHex = row[3]
            let darkHex = row[4]
            let description = row[5]
            
            #expect(name == "primaryBackgroundColor")
            #expect(lightHex == "#FFF")
            #expect(darkHex == "#FFF")
            #expect(description.contains("fondo principal"))
        }
    }
    
    @Test
    func csvParserEndMarkers() throws {
        let locResult = try CSVParser.parse(SharedTestData.localizationCSV)
        let endRowLoc = locResult.first { $0.first == "[END]" }
        #expect(endRowLoc != nil)
        
        let colorResult = try CSVParser.parse(SharedTestData.colorsCSV)
        let endRowColor = colorResult.first { $0.first == "[END]" }
        #expect(endRowColor != nil)
    }
    
    @Test
    func csvParsingWithEndMarkers() throws {
        
        let locResult = try CSVParser.parse(SharedTestData.localizationCSV)
        let colorResult = try CSVParser.parse(SharedTestData.colorsCSV)
        
    
        let locEndRow = locResult.first { $0.first == "[END]" }
        let colorEndRow = colorResult.first { $0.first == "[END]" }
        
        #expect(locEndRow != nil)
        #expect(colorEndRow != nil)
        
        let locDataRows = locResult.filter { row in
            !row.isEmpty &&
            row.first != "[END]" &&
            !row.contains("[View]") && // not header
            row.count >= 7
        }
        
        let colorDataRows = colorResult.filter { row in
            row.count >= 6 &&
            !row[1].isEmpty &&
            row[1] != "[Color Name]" &&
            row[1] != "[COMMENT]" &&
            row.first != "[END]" &&
            !row[1].contains("[")
        }
        
        #expect(locDataRows.count >= 10)
        #expect(colorDataRows.count >= 7)
    }
    
    // MARK: - Column Count Validation Tests
    
    @Test
    func csvValidationColumnCounts() throws {
   
        let locResult = try CSVParser.parse(SharedTestData.localizationCSV)
        let headerColumnCount = locResult.first?.count ?? 0
        
        let validRows = locResult.filter { $0.count == headerColumnCount }
        let totalDataRows = locResult.filter { $0.first != "[END]" }.count
        
        #expect(validRows.count >= totalDataRows - 2)
    }
    
    // MARK: - Helper Functions
    
    private func createTempFile(content: String) -> URL {
        return SharedTestData.createTempFile(content: content)
    }
}

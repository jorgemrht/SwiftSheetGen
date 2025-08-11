import Testing
import Foundation
@testable import SheetLocalizer

// MARK: - CSV Parser Configuration Tests

@Suite
struct CSVParserConfigurationTests {
    
    @Test
    func test_streamingConfigDefaults() {
        let config = CSVParser.StreamingConfig.default
        
        #expect(config.bufferSize == 16384)
        #expect(config.maxMemoryUsage == 20 * 1024 * 1024)
        #expect(config.batchSize == 2000)
        #expect(config.logProgressInterval == 10)
    }
    
    @Test
    func test_streamingConfigHighPerformance() {
        let config = CSVParser.StreamingConfig.highPerformance
        
        #expect(config.bufferSize == 128 * 1024)
        #expect(config.maxMemoryUsage == 100 * 1024 * 1024)
        #expect(config.batchSize == 10000)
        #expect(config.logProgressInterval == 5)
    }
    
    @Test
    func test_streamingConfigMemoryConstrained() {
        let config = CSVParser.StreamingConfig.memoryConstrained
        
        #expect(config.bufferSize == 8192)
        #expect(config.maxMemoryUsage == 10 * 1024 * 1024)
        #expect(config.batchSize == 1000)
        #expect(config.logProgressInterval == 20)
    }
}

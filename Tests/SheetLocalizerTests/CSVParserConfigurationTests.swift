import Testing
import Foundation
@testable import SheetLocalizer

// MARK: - CSV Parser Configuration Tests

@Suite
struct CSVParserConfigurationTests {
    
    @Test("Default streaming configuration provides balanced memory and performance settings")
    func defaultStreamingConfigurationValidation() {
        let config = CSVParser.StreamingConfig.default
        
        #expect(config.bufferSize == 16384)
        #expect(config.maxMemoryUsage == 20 * 1024 * 1024)
        #expect(config.batchSize == 2000)
        #expect(config.logProgressInterval == 10)
    }
    
    @Test("High performance streaming configuration maximizes throughput for large datasets")
    func highPerformanceStreamingConfigurationValidation() {
        let config = CSVParser.StreamingConfig.highPerformance
        
        #expect(config.bufferSize == 128 * 1024)
        #expect(config.maxMemoryUsage == 100 * 1024 * 1024)
        #expect(config.batchSize == 10000)
        #expect(config.logProgressInterval == 5)
    }
    
    @Test("Memory constrained streaming configuration minimizes memory usage for resource-limited environments")
    func memoryConstrainedStreamingConfigurationValidation() {
        let config = CSVParser.StreamingConfig.memoryConstrained
        
        #expect(config.bufferSize == 8192)
        #expect(config.maxMemoryUsage == 10 * 1024 * 1024)
        #expect(config.batchSize == 1000)
        #expect(config.logProgressInterval == 20)
    }
}

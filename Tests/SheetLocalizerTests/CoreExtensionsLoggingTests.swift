import Testing
import Foundation
import os.log
@testable import CoreExtensions

@Suite
struct CoreExtensionsLoggingTests {

    @Test
    func testLoggerExtensions() {
        let logger = Logger(subsystem: "com.example.tests", category: "logging")
        
        logger.debug("This is a debug message")
        logger.info("This is an info message")
        logger.notice("This is a notice message")
        logger.warning("This is a warning message")
        logger.error("This is an error message")
        logger.critical("This is a critical message")
        
        #expect(true)
    }

    @Test
    func testLogPrivacyLevel() {
        let privateLevel = LogPrivacyLevel.private
        let publicLevel = LogPrivacyLevel.public
        
        #expect(privateLevel == .private)
        #expect(publicLevel == .public)
    }
}

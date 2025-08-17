import Testing
import Foundation
import os.log
@testable import CoreExtensions

@Suite
struct CoreExtensionsLoggingTests {

    @Test("Logger extensions support all standard logging levels")
    func loggerExtensionsBasicFunctionality() {
        let logger = Logger(subsystem: "com.example.tests", category: "logging")
        
        // Test that all logging methods can be called without throwing
        #expect(throws: Never.self) {
            logger.debug("Debug message test")
            logger.info("Info message test")
            logger.notice("Notice message test")
            logger.warning("Warning message test")
            logger.error("Error message test")
            logger.critical("Critical message test")
        }
    }

    @Test("LogPrivacyLevel enumeration provides correct privacy settings")
    func logPrivacyLevelValidation() {
        let privateLevel = LogPrivacyLevel.private
        let publicLevel = LogPrivacyLevel.public
        
        #expect(privateLevel.isPrivate == true)
        #expect(privateLevel.isPublic == false)
        #expect(publicLevel.isPrivate == false)
        #expect(publicLevel.isPublic == true)
        
        let fromPrivateString = LogPrivacyLevel(from: "private")
        let fromPublicString = LogPrivacyLevel(from: "public")
        let fromInvalidString = LogPrivacyLevel(from: "invalid")
        
        #expect(fromPrivateString.isPrivate == true)
        #expect(fromPublicString.isPublic == true)
        #expect(fromInvalidString.isPublic == true)
    }
}

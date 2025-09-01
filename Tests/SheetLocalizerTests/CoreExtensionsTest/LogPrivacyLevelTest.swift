import Testing
import Foundation
@testable import CoreExtensions

@Suite
struct LogPrivacyLevelTest {
    
    
    @Test("LogPrivacyLevel initializes from string values correctly",
          arguments: [
              ("private", LogPrivacyLevel.private),
              ("PRIVATE", LogPrivacyLevel.private),
              ("Private", LogPrivacyLevel.private),
              ("PriVaTe", LogPrivacyLevel.private),
              ("public", LogPrivacyLevel.public),
              ("PUBLIC", LogPrivacyLevel.public),
              ("Public", LogPrivacyLevel.public),
              ("invalid", LogPrivacyLevel.public),
              ("", LogPrivacyLevel.public),
              ("random", LogPrivacyLevel.public),
              ("123", LogPrivacyLevel.public)
          ])
    func logPrivacyLevelInitialization(input: String, expected: LogPrivacyLevel) {
        let level = LogPrivacyLevel(from: input)
        #expect(level == expected)
    }
    
    
    @Test("LogPrivacyLevel.isPrivate returns correct boolean values",
          arguments: [
              (LogPrivacyLevel.private, true),
              (LogPrivacyLevel.public, false)
          ])
    func logPrivacyLevelIsPrivateProperty(level: LogPrivacyLevel, expectedPrivate: Bool) {
        #expect(level.isPrivate == expectedPrivate)
    }
    
    @Test("LogPrivacyLevel.isPublic returns correct boolean values",
          arguments: [
              (LogPrivacyLevel.private, false),
              (LogPrivacyLevel.public, true)
          ])
    func logPrivacyLevelIsPublicProperty(level: LogPrivacyLevel, expectedPublic: Bool) {
        #expect(level.isPublic == expectedPublic)
    }
    
    
    @Test
    func logPrivacyLevelMutualExclusivity() {
        for level in [LogPrivacyLevel.private, LogPrivacyLevel.public] {
            #expect(level.isPrivate != level.isPublic)
        }
    }
    
    @Test
    func logPrivacyLevelRawValues() {
        #expect(LogPrivacyLevel.private.rawValue == "private")
        #expect(LogPrivacyLevel.public.rawValue == "public")
    }
    
    
    @Test
    func logPrivacyLevelWhitespaceHandling() {
        let spacedPrivate = LogPrivacyLevel(from: "  private  ")
        #expect(spacedPrivate == LogPrivacyLevel.public)
        
        let tabPrivate = LogPrivacyLevel(from: "\tprivate\t")
        #expect(tabPrivate == LogPrivacyLevel.public)
        
        let newlinePrivate = LogPrivacyLevel(from: "\nprivate\n")
        #expect(newlinePrivate == LogPrivacyLevel.public)
    }
    
    @Test
    func logPrivacyLevelCaseInsensitivity() {
        let variations = ["private", "PRIVATE", "Private", "pRiVaTe", "PrIvAtE"]
        
        for variation in variations {
            let level = LogPrivacyLevel(from: variation)
            #expect(level == LogPrivacyLevel.private)
            #expect(level.isPrivate == true)
            #expect(level.isPublic == false)
        }
    }
    
    @Test
    func logPrivacyLevelDefaultBehavior() {
        let invalidInputs = [
            "invalid", "unknown", "protected", "internal",
            "123", "true", "false", "nil", "none"
        ]
        
        for input in invalidInputs {
            let level = LogPrivacyLevel(from: input)
            #expect(level == LogPrivacyLevel.public)
            #expect(level.isPublic == true)
            #expect(level.isPrivate == false)
        }
    }
    
    
    @Test
    func logPrivacyLevelConditionalLogic() {
        let privateLevel = LogPrivacyLevel(from: "private")
        let publicLevel = LogPrivacyLevel(from: "public")
        
        var privateCount = 0
        var publicCount = 0
        
        for level in [privateLevel, publicLevel] {
            if level.isPrivate {
                privateCount += 1
            } else if level.isPublic {
                publicCount += 1
            }
        }
        
        #expect(privateCount == 1)
        #expect(publicCount == 1)
    }
    
    @Test
    func logPrivacyLevelProtocolConformance() {
        #expect(LogPrivacyLevel(rawValue: "private") == LogPrivacyLevel.private)
        #expect(LogPrivacyLevel(rawValue: "public") == LogPrivacyLevel.public)
        #expect(LogPrivacyLevel(rawValue: "invalid") == nil)
        
        let level = LogPrivacyLevel.private
        #expect(!level.rawValue.isEmpty)
    }
}

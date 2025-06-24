import Foundation

// MARK: - Collection Safe Access Extensions

public extension Collection {
    /// Safely accesses element at given index, returning nil if out of bounds
    /// - Parameter index: The index to access
    /// - Returns: Element at index or nil if out of bounds
    /// - Complexity: O(1) for RandomAccessCollection, O(n) otherwise
    @inlinable
    subscript(safeAccess index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    
    /// Safely accesses element using offset from startIndex
    /// - Parameter offset: The offset from startIndex
    /// - Returns: Element at offset or nil if out of bounds
    /// - Complexity: O(offset)
    @inlinable
    subscript(safeOffset offset: Int) -> Element? {
        guard offset >= 0 else { return nil }
        guard let targetIndex = index(startIndex, offsetBy: offset, limitedBy: endIndex) else {
            return nil
        }
        return self[targetIndex]
    }
    
    /// Returns true if all elements satisfy the given predicate or collection is empty
    /// - Parameter predicate: Predicate to test elements
    /// - Returns: Boolean indicating if all elements match condition or collection is empty
    /// - Complexity: O(n)
    func allSatisfyOrEmpty(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        guard !isEmpty else { return true }
        return try allSatisfy(predicate)
    }
    
    /// Safely retrieves the first element matching the predicate
    /// - Parameter predicate: The predicate to match
    /// - Returns: First matching element or nil
    /// - Complexity: O(n)
    @inlinable
    func firstSafe(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        try first(where: predicate)
    }
}

public extension Array {
    /// Safely accesses element at given integer index
    /// - Parameter index: The integer index to access
    /// - Returns: Element at index or nil if out of bounds
    /// - Complexity: O(1)
    @inlinable
    subscript(safeAccess index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    
    /// Safely removes and returns element at index
    /// - Parameter index: The index to remove
    /// - Returns: Removed element or nil if out of bounds
    /// - Complexity: O(n)
    @inlinable
    mutating func safeRemove(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return remove(at: index)
    }
    
    /// Safely removes elements at given indices
    /// - Parameter indices: Set of indices to remove
    /// - Returns: Array of removed elements
    /// - Complexity: O(n)
    @inlinable
    mutating func safeRemove(at indices: IndexSet) -> [Element] {
        var removedElements: [Element] = []
        for index in indices.sorted(by: >) {
            if let element = safeRemove(at: index) {
                removedElements.append(element)
            }
        }
        return removedElements.reversed()
    }
}

// MARK: - String Extensions for Better Performance

public extension String {
    /// Efficiently checks if string is empty or whitespace-only
    /// - Returns: true if empty or contains only whitespace
    /// - Complexity: O(n) worst case, O(1) best case
    @inlinable
    var isEmptyOrWhitespace: Bool {
        isEmpty || allSatisfy(\.isWhitespace)
    }
    
    /// Returns trimmed content without creating intermediate strings
    /// - Returns: String with leading/trailing whitespace removed
    /// - Complexity: O(n)
    @inlinable
    var trimmedContent: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Safely converts string to URL with validation
    /// - Returns: URL if valid, nil otherwise
    /// - Complexity: O(n)
    @inlinable
    func asURL() throws -> URL {
        guard !isEmpty else { throw URLError(.badURL) }
        guard let url = URL(string: self) else { throw URLError(.badURL) }
        return url
    }
    
    /// Checks if string contains any of the given substrings
    /// - Parameter substrings: Array of substrings to check
    /// - Returns: true if any substring is found
    /// - Complexity: O(n*m) where n is string length and m is substrings count
    @inlinable
    func containsAny(of substrings: [String]) -> Bool {
        substrings.contains { contains($0) }
    }
    
    /// Checks if string contains any of the given substrings (case insensitive)
    /// - Parameter substrings: Array of substrings to check
    /// - Returns: true if any substring is found
    /// - Complexity: O(n*m)
    @inlinable
    func containsAnyIgnoringCase(of substrings: [String]) -> Bool {
        let lowercased = self.lowercased()
        return substrings.contains { lowercased.contains($0.lowercased()) }
    }
    
    /// Safe substring extraction
    /// - Parameter range: Range to extract
    /// - Returns: Substring or nil if range is invalid
    @inlinable
    func safeSubstring(in range: Range<Int>) -> String? {
        guard range.lowerBound >= 0,
              range.upperBound <= count,
              range.lowerBound <= range.upperBound else {
            return nil
        }
        
        let startIndex = index(startIndex, offsetBy: range.lowerBound)
        let endIndex = index(startIndex, offsetBy: range.upperBound - range.lowerBound)
        return String(self[startIndex..<endIndex])
    }
}

// MARK: - URL Extensions

public extension URL {
    /// Safe file URL creation with validation
    /// - Parameter path: File path string
    /// - Returns: File URL or nil if invalid
    /// - Complexity: O(n)
    static func safeFileURL(withPath path: String) -> URL? {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        let url = URL(fileURLWithPath: path)
        return url.path.isEmpty ? nil : url
    }
    
    /// Checks if URL points to an existing file
    /// - Returns: true if file exists
    /// - Complexity: O(1)
    @inlinable
    var fileExists: Bool {
        isFileURL && FileManager.default.fileExists(atPath: path)
    }
    
    /// Safe URL creation from string with validation
    /// - Parameter string: URL string
    /// - Returns: URL or nil if invalid
    static func safeURL(from string: String) -> URL? {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return URL(string: string)
    }
}

// MARK: - FileManager Extensions

public extension FileManager {
    /// Creates directory with proper error handling and validation
    /// - Parameters:
    ///   - path: Directory path
    ///   - createIntermediates: Whether to create intermediate directories
    /// - Throws: FileManagerError for specific error cases
    func createDirectoryIfNeeded(atPath path: String, createIntermediates: Bool = true) throws {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FileManagerError.invalidPath
        }
        
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: path, isDirectory: &isDirectory)
        
        if !exists {
            try createDirectory(atPath: path, withIntermediateDirectories: createIntermediates)
        } else if !isDirectory.boolValue {
            throw FileManagerError.pathExistsButNotDirectory
        }
    }
    
    /// Safely removes item at path
    /// - Parameter path: Path to remove
    /// - Returns: true if removed successfully, false if item didn't exist
    /// - Throws: FileManager errors for other issues
    @discardableResult
    func safeRemoveItem(atPath path: String) throws -> Bool {
        guard fileExists(atPath: path) else { return false }
        try removeItem(atPath: path)
        return true
    }
    
    /// Gets file size safely
    /// - Parameter path: File path
    /// - Returns: File size in bytes or nil if file doesn't exist
    func fileSize(atPath path: String) -> Int64? {
        guard let attributes = try? attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
}

// MARK: - Custom Error Types

public enum FileManagerError: LocalizedError, Sendable {
    case invalidPath
    case pathExistsButNotDirectory
    
    public var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "The provided path is invalid or empty"
        case .pathExistsButNotDirectory:
            return "Path exists but is not a directory"
        }
    }
}

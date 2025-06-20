//
//  Created by jorge on 20/6/25.
//

// MARK: - URL Transformer
public struct GoogleSheetURLTransformer: Sendable {
    static func transformToCSV(_ urlString: String) -> String {
       
        if urlString.contains("export?format=csv") || urlString.contains("output=csv") {
            return urlString
        }
        
        if urlString.contains("/pubhtml") {
            return urlString.replacingOccurrences(of: "/pubhtml", with: "/export?format=csv")
        }
        
        if urlString.contains("/edit") {
            let baseURL = urlString.components(separatedBy: "/edit").first ?? urlString
            return "\(baseURL)/export?format=csv"
        }
        
        return urlString.hasSuffix("/")
            ? "\(urlString)export?format=csv"
            : "\(urlString)/export?format=csv"
    }
}

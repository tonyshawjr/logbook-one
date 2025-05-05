import Foundation

struct HashtagExtractor {
    // Extract all hashtags from text content
    static func extractHashtags(from text: String) -> [String] {
        // Regular expression to match hashtags
        // Matches any string that starts with # followed by one or more alphanumeric characters or underscores
        let pattern = "#[\\w]+"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            return results.map { nsString.substring(with: $0.range) }
        } catch {
            print("Error creating hashtag regex: \(error.localizedDescription)")
            return []
        }
    }
    
    // Convert hashtag array to comma-delimited string for storage
    static func hashtags(toStorageFormat hashtags: [String]) -> String {
        // Filter to ensure only proper hashtags, then join with commas
        return hashtags
            .filter { $0.starts(with: "#") && $0.count > 1 }
            .joined(separator: ",")
    }
    
    // Parse comma-delimited string back to hashtag array
    static func hashtags(fromStorageFormat string: String) -> [String] {
        // Split by comma and filter out any empty strings
        return string
            .split(separator: ",")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
    
    // Get unique hashtags from a collection of notes
    static func uniqueHashtags(from notes: [LogEntry]) -> [String] {
        var allHashtags: Set<String> = []
        
        for note in notes {
            guard let text = note.desc else { continue }
            let tags = extractHashtags(from: text)
            tags.forEach { allHashtags.insert($0) }
        }
        
        return Array(allHashtags).sorted()
    }
} 
import Foundation

struct TextSource: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let uploadDate: Date
    let wordCount: Int
    let processedDate: Date?
    
    init(id: UUID = UUID(), title: String, content: String, uploadDate: Date = Date(), wordCount: Int = 0, processedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.uploadDate = uploadDate
        self.wordCount = wordCount
        self.processedDate = processedDate
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               content.count >= 10 // Minimum content length
    }
    
    func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTitle
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyContent
        }
        
        guard content.count >= 10 else {
            throw ValidationError.contentTooShort
        }
        
        guard content.count <= 100000 else {
            throw ValidationError.contentTooLong
        }
    }
    
    var isProcessed: Bool {
        return processedDate != nil
    }
}
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
}
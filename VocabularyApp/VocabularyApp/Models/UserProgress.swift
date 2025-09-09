import Foundation

struct UserProgress: Codable {
    let wordId: UUID
    let isMemorized: Bool
    let reviewCount: Int
    let lastReviewed: Date
    
    init(wordId: UUID, isMemorized: Bool, reviewCount: Int = 1, lastReviewed: Date = Date()) {
        self.wordId = wordId
        self.isMemorized = isMemorized
        self.reviewCount = reviewCount
        self.lastReviewed = lastReviewed
    }
}
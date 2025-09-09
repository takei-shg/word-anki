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
    
    // MARK: - Validation
    
    var isValid: Bool {
        return reviewCount > 0 && lastReviewed <= Date()
    }
    
    func validate() throws {
        guard reviewCount > 0 else {
            throw ValidationError.invalidReviewCount
        }
        
        guard lastReviewed <= Date() else {
            throw ValidationError.futureReviewDate
        }
    }
    
    // MARK: - Utility Methods
    
    func incrementReviewCount(isMemorized: Bool) -> UserProgress {
        return UserProgress(
            wordId: wordId,
            isMemorized: isMemorized,
            reviewCount: reviewCount + 1,
            lastReviewed: Date()
        )
    }
}
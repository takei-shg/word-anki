import Foundation

enum ValidationError: LocalizedError {
    case emptyTitle
    case emptyContent
    case contentTooShort
    case contentTooLong
    case emptyWord
    case emptySentence
    case emptyMeaning
    case wordNotInSentence
    case invalidReviewCount
    case futureReviewDate
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Text source title cannot be empty"
        case .emptyContent:
            return "Text source content cannot be empty"
        case .contentTooShort:
            return "Text content must be at least 10 characters long"
        case .contentTooLong:
            return "Text content cannot exceed 100,000 characters"
        case .emptyWord:
            return "Word cannot be empty"
        case .emptySentence:
            return "Sentence cannot be empty"
        case .emptyMeaning:
            return "Word meaning cannot be empty"
        case .wordNotInSentence:
            return "Word must appear in the provided sentence"
        case .invalidReviewCount:
            return "Review count must be greater than 0"
        case .futureReviewDate:
            return "Review date cannot be in the future"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyTitle:
            return "Please provide a descriptive title for your text source"
        case .emptyContent:
            return "Please provide text content to learn vocabulary from"
        case .contentTooShort:
            return "Please provide more text content for better vocabulary extraction"
        case .contentTooLong:
            return "Please reduce the text content or split it into multiple sources"
        case .emptyWord:
            return "Ensure the word field is properly filled"
        case .emptySentence:
            return "Ensure the sentence field contains the contextual sentence"
        case .emptyMeaning:
            return "Ensure the meaning field contains the word definition"
        case .wordNotInSentence:
            return "Verify that the word appears in the contextual sentence"
        case .invalidReviewCount:
            return "Review count should start from 1"
        case .futureReviewDate:
            return "Use current date or a past date for review timestamp"
        }
    }
}
import Foundation

struct WordTest: Codable, Identifiable {
    let id: UUID
    let word: String
    let sentence: String
    let meaning: String
    let difficultyLevel: DifficultyLevel
    let sourceId: UUID
    
    init(id: UUID = UUID(), word: String, sentence: String, meaning: String, difficultyLevel: DifficultyLevel, sourceId: UUID) {
        self.id = id
        self.word = word
        self.sentence = sentence
        self.meaning = meaning
        self.difficultyLevel = difficultyLevel
        self.sourceId = sourceId
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        return !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               sentence.localizedCaseInsensitiveContains(word)
    }
    
    func validate() throws {
        guard !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyWord
        }
        
        guard !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptySentence
        }
        
        guard !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyMeaning
        }
        
        guard sentence.localizedCaseInsensitiveContains(word) else {
            throw ValidationError.wordNotInSentence
        }
    }
}
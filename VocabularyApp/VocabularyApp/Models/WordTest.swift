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
}
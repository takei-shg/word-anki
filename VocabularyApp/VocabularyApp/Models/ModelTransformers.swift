import Foundation
import CoreData

// MARK: - Core Data Entity Extensions for Model Transformation

extension TextSourceEntity {
    
    func toModel() -> TextSource {
        return TextSource(
            id: id ?? UUID(),
            title: title ?? "",
            content: content ?? "",
            uploadDate: uploadDate ?? Date(),
            wordCount: Int(wordCount),
            processedDate: processedDate
        )
    }
    
    func update(from model: TextSource) {
        self.id = model.id
        self.title = model.title
        self.content = model.content
        self.uploadDate = model.uploadDate
        self.wordCount = Int32(model.wordCount)
        self.processedDate = model.processedDate
        self.isProcessed = model.processedDate != nil
    }
    
    static func create(from model: TextSource, in context: NSManagedObjectContext) -> TextSourceEntity {
        let entity = TextSourceEntity(context: context)
        entity.update(from: model)
        return entity
    }
}

extension WordTestEntity {
    
    func toModel() -> WordTest? {
        guard let id = id,
              let word = word,
              let sentence = sentence,
              let meaning = meaning,
              let difficultyLevelString = difficultyLevel,
              let difficulty = DifficultyLevel(rawValue: difficultyLevelString),
              let sourceId = sourceId else {
            return nil
        }
        
        return WordTest(
            id: id,
            word: word,
            sentence: sentence,
            meaning: meaning,
            difficultyLevel: difficulty,
            sourceId: sourceId
        )
    }
    
    func update(from model: WordTest) {
        self.id = model.id
        self.word = model.word
        self.sentence = model.sentence
        self.meaning = model.meaning
        self.difficultyLevel = model.difficultyLevel.rawValue
        self.sourceId = model.sourceId
        self.createdDate = Date()
        self.isDownloaded = true
    }
    
    static func create(from model: WordTest, in context: NSManagedObjectContext) -> WordTestEntity {
        let entity = WordTestEntity(context: context)
        entity.update(from: model)
        return entity
    }
}

extension UserProgressEntity {
    
    func toModel() -> UserProgress? {
        guard let wordId = wordId else {
            return nil
        }
        
        return UserProgress(
            wordId: wordId,
            isMemorized: isMemorized,
            reviewCount: Int(reviewCount),
            lastReviewed: lastReviewed ?? Date()
        )
    }
    
    func update(from model: UserProgress) {
        self.id = UUID()
        self.wordId = model.wordId
        self.isMemorized = model.isMemorized
        self.reviewCount = Int32(model.reviewCount)
        self.lastReviewed = model.lastReviewed
        self.isSynced = false
    }
    
    static func create(from model: UserProgress, in context: NSManagedObjectContext) -> UserProgressEntity {
        let entity = UserProgressEntity(context: context)
        entity.update(from: model)
        return entity
    }
}

// MARK: - Collection Extensions

extension Array where Element == TextSourceEntity {
    func toModels() -> [TextSource] {
        return self.map { $0.toModel() }
    }
}

extension Array where Element == WordTestEntity {
    func toModels() -> [WordTest] {
        return self.compactMap { $0.toModel() }
    }
}

extension Array where Element == UserProgressEntity {
    func toModels() -> [UserProgress] {
        return self.compactMap { $0.toModel() }
    }
}

extension Array where Element == TextSource {
    func createEntities(in context: NSManagedObjectContext) -> [TextSourceEntity] {
        return self.map { TextSourceEntity.create(from: $0, in: context) }
    }
}

extension Array where Element == WordTest {
    func createEntities(in context: NSManagedObjectContext) -> [WordTestEntity] {
        return self.map { WordTestEntity.create(from: $0, in: context) }
    }
}

extension Array where Element == UserProgress {
    func createEntities(in context: NSManagedObjectContext) -> [UserProgressEntity] {
        return self.map { UserProgressEntity.create(from: $0, in: context) }
    }
}

extension SyncOperationEntity {
    
    func toModel() -> SyncOperation? {
        guard let id = id,
              let typeString = type,
              let syncType = SyncOperationType(rawValue: typeString),
              let createdDate = createdDate else {
            return nil
        }
        
        return SyncOperation(
            id: id,
            type: syncType,
            data: data,
            relatedId: relatedId,
            createdDate: createdDate,
            retryCount: retryCount,
            isProcessed: isProcessed,
            processedDate: processedDate,
            lastRetryDate: lastRetryDate
        )
    }
    
    func update(from model: SyncOperation) {
        self.id = model.id
        self.type = model.type.rawValue
        self.data = model.data
        self.relatedId = model.relatedId
        self.createdDate = model.createdDate
        self.retryCount = model.retryCount
        self.isProcessed = model.isProcessed
        self.processedDate = model.processedDate
        self.lastRetryDate = model.lastRetryDate
    }
    
    static func create(from model: SyncOperation, in context: NSManagedObjectContext) -> SyncOperationEntity {
        let entity = SyncOperationEntity(context: context)
        entity.update(from: model)
        return entity
    }
}

extension Array where Element == SyncOperationEntity {
    func toModels() -> [SyncOperation] {
        return self.compactMap { $0.toModel() }
    }
}
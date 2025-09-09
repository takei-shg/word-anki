import Foundation
import CoreData
import os.log

class WordTestRepository: RepositoryProtocol {
    typealias Entity = WordTestEntity
    typealias Model = WordTest
    
    let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.vocabularyapp", category: "wordTestRepository")
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - CRUD Operations
    
    func create(_ model: WordTest) async throws -> WordTest {
        return try await persistenceController.performBackgroundTask { context in
            let entity = WordTestEntity(context: context)
            entity.id = model.id
            entity.word = model.word
            entity.sentence = model.sentence
            entity.meaning = model.meaning
            entity.difficultyLevel = model.difficultyLevel.rawValue
            entity.sourceId = model.sourceId
            entity.createdDate = Date()
            entity.isDownloaded = true
            
            // Set up relationship with TextSource if it exists
            let sourceRequest: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
            sourceRequest.predicate = NSPredicate(format: "id == %@", model.sourceId as CVarArg)
            sourceRequest.fetchLimit = 1
            
            if let sourceEntity = try context.fetch(sourceRequest).first {
                entity.source = sourceEntity
            }
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Created word test with ID: \(model.id)")
            
            return model
        }
    }
    
    func fetch(by id: UUID) async throws -> WordTest? {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toModel()
        }
    }
    
    func fetchAll() async throws -> [WordTest] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WordTestEntity.createdDate, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func update(_ model: WordTest) async throws -> WordTest {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", model.id as CVarArg)
            request.fetchLimit = 1
            
            guard let entity = try context.fetch(request).first else {
                throw PersistenceError.entityNotFound
            }
            
            entity.word = model.word
            entity.sentence = model.sentence
            entity.meaning = model.meaning
            entity.difficultyLevel = model.difficultyLevel.rawValue
            entity.sourceId = model.sourceId
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Updated word test with ID: \(model.id)")
            
            return model
        }
    }
    
    func delete(by id: UUID) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Deleted word test with ID: \(id)")
        }
    }
    
    func deleteAll() async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = WordTestEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount
            
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Deleted \(deletedCount) word tests")
        }
    }
    
    // MARK: - Additional Methods
    
    func fetchBySource(_ sourceId: UUID) async throws -> [WordTest] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
            request.predicate = NSPredicate(format: "sourceId == %@", sourceId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WordTestEntity.createdDate, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func fetchByDifficulty(_ difficulty: DifficultyLevel) async throws -> [WordTest] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
            request.predicate = NSPredicate(format: "difficultyLevel == %@", difficulty.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WordTestEntity.createdDate, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func fetchBySourceAndDifficulty(_ sourceId: UUID, difficulty: DifficultyLevel) async throws -> [WordTest] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "sourceId == %@ AND difficultyLevel == %@",
                sourceId as CVarArg,
                difficulty.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WordTestEntity.createdDate, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func createBatch(_ models: [WordTest]) async throws -> [WordTest] {
        return try await persistenceController.performBackgroundTask { context in
            var createdModels: [WordTest] = []
            
            for model in models {
                let entity = WordTestEntity(context: context)
                entity.id = model.id
                entity.word = model.word
                entity.sentence = model.sentence
                entity.meaning = model.meaning
                entity.difficultyLevel = model.difficultyLevel.rawValue
                entity.sourceId = model.sourceId
                entity.createdDate = Date()
                entity.isDownloaded = true
                
                // Set up relationship with TextSource if it exists
                let sourceRequest: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
                sourceRequest.predicate = NSPredicate(format: "id == %@", model.sourceId as CVarArg)
                sourceRequest.fetchLimit = 1
                
                if let sourceEntity = try context.fetch(sourceRequest).first {
                    entity.source = sourceEntity
                }
                
                createdModels.append(model)
            }
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Created batch of \(models.count) word tests")
            
            return createdModels
        }
    }
    
    func deleteBySource(_ sourceId: UUID) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = WordTestEntity.fetchRequest()
            request.predicate = NSPredicate(format: "sourceId == %@", sourceId as CVarArg)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount
            
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Deleted \(deletedCount) word tests for source: \(sourceId)")
        }
    }
    
    func countByDifficulty() async throws -> [DifficultyLevel: Int] {
        return try await persistenceController.performBackgroundTask { context in
            var counts: [DifficultyLevel: Int] = [:]
            
            for difficulty in DifficultyLevel.allCases {
                let request: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
                request.predicate = NSPredicate(format: "difficultyLevel == %@", difficulty.rawValue)
                
                let count = try context.count(for: request)
                counts[difficulty] = count
            }
            
            return counts
        }
    }
}

// Note: WordTestEntity.toModel() extension is defined in ModelTransformers.swift
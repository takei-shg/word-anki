import Foundation
import CoreData
import os.log

class UserProgressRepository: RepositoryProtocol {
    typealias Entity = UserProgressEntity
    typealias Model = UserProgress
    
    let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.vocabularyapp", category: "userProgressRepository")
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - CRUD Operations
    
    func create(_ model: UserProgress) async throws -> UserProgress {
        return try await persistenceController.performBackgroundTask { context in
            let entity = UserProgressEntity(context: context)
            entity.id = UUID()
            entity.wordId = model.wordId
            entity.isMemorized = model.isMemorized
            entity.reviewCount = Int32(model.reviewCount)
            entity.lastReviewed = model.lastReviewed
            entity.isSynced = false
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Created user progress for word: \(model.wordId)")
            
            return model
        }
    }
    
    func fetch(by id: UUID) async throws -> UserProgress? {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toModel()
        }
    }
    
    func fetchAll() async throws -> [UserProgress] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProgressEntity.lastReviewed, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func update(_ model: UserProgress) async throws -> UserProgress {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "wordId == %@", model.wordId as CVarArg)
            request.fetchLimit = 1
            
            guard let entity = try context.fetch(request).first else {
                throw PersistenceError.entityNotFound
            }
            
            entity.isMemorized = model.isMemorized
            entity.reviewCount = Int32(model.reviewCount)
            entity.lastReviewed = model.lastReviewed
            entity.isSynced = false
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Updated user progress for word: \(model.wordId)")
            
            return model
        }
    }
    
    func delete(by id: UUID) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Deleted user progress with ID: \(id)")
        }
    }
    
    func deleteAll() async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = UserProgressEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount
            
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Deleted \(deletedCount) user progress records")
        }
    }
    
    // MARK: - Additional Methods
    
    func fetchByWord(_ wordId: UUID) async throws -> UserProgress? {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "wordId == %@", wordId as CVarArg)
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toModel()
        }
    }
    
    func fetchMemorized() async throws -> [UserProgress] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isMemorized == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProgressEntity.lastReviewed, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func fetchNotMemorized() async throws -> [UserProgress] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isMemorized == NO")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProgressEntity.lastReviewed, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func fetchUnsynced() async throws -> [UserProgress] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isSynced == NO")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProgressEntity.lastReviewed, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func recordProgress(_ wordId: UUID, isMemorized: Bool) async throws -> UserProgress {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "wordId == %@", wordId as CVarArg)
            request.fetchLimit = 1
            
            let entity: UserProgressEntity
            let reviewCount: Int
            
            if let existingEntity = try context.fetch(request).first {
                entity = existingEntity
                reviewCount = Int(existingEntity.reviewCount) + 1
            } else {
                entity = UserProgressEntity(context: context)
                entity.id = UUID()
                entity.wordId = wordId
                reviewCount = 1
            }
            
            entity.isMemorized = isMemorized
            entity.reviewCount = Int32(reviewCount)
            entity.lastReviewed = Date()
            entity.isSynced = false
            
            try self.persistenceController.saveBackground(context)
            
            let progress = UserProgress(
                wordId: wordId,
                isMemorized: isMemorized,
                reviewCount: reviewCount,
                lastReviewed: entity.lastReviewed!
            )
            
            self.logger.info("Recorded progress for word \(wordId): memorized=\(isMemorized), count=\(reviewCount)")
            
            return progress
        }
    }
    
    func markAsSynced(_ wordIds: [UUID]) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "wordId IN %@", wordIds)
            
            let entities = try context.fetch(request)
            for entity in entities {
                entity.isSynced = true
            }
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Marked \(entities.count) progress records as synced")
        }
    }
    
    func getStatistics() async throws -> ProgressStatistics {
        return try await persistenceController.performBackgroundTask { context in
            let allRequest: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            let totalCount = try context.count(for: allRequest)
            
            let memorizedRequest: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            memorizedRequest.predicate = NSPredicate(format: "isMemorized == YES")
            let memorizedCount = try context.count(for: memorizedRequest)
            
            let notMemorizedRequest: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
            notMemorizedRequest.predicate = NSPredicate(format: "isMemorized == NO")
            let notMemorizedCount = try context.count(for: notMemorizedRequest)
            
            // Calculate total review count
            let reviewSumRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "UserProgressEntity")
            reviewSumRequest.resultType = .dictionaryResultType
            
            let sumExpression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: "reviewCount")])
            let sumExpressionDescription = NSExpressionDescription()
            sumExpressionDescription.name = "totalReviews"
            sumExpressionDescription.expression = sumExpression
            sumExpressionDescription.expressionResultType = .integer32AttributeType
            
            reviewSumRequest.propertiesToFetch = [sumExpressionDescription]
            
            let results = try context.fetch(reviewSumRequest)
            let totalReviews = results.first?["totalReviews"] as? Int32 ?? 0
            
            return ProgressStatistics(
                totalWords: totalCount,
                memorizedWords: memorizedCount,
                notMemorizedWords: notMemorizedCount,
                totalReviews: Int(totalReviews)
            )
        }
    }
    
    func deleteByWords(_ wordIds: [UUID]) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = UserProgressEntity.fetchRequest()
            request.predicate = NSPredicate(format: "wordId IN %@", wordIds)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount
            
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Deleted \(deletedCount) progress records for specified words")
        }
    }
}

// MARK: - Supporting Types

struct ProgressStatistics {
    let totalWords: Int
    let memorizedWords: Int
    let notMemorizedWords: Int
    let totalReviews: Int
    
    var memorizedPercentage: Double {
        guard totalWords > 0 else { return 0.0 }
        return Double(memorizedWords) / Double(totalWords) * 100.0
    }
    
    var averageReviewsPerWord: Double {
        guard totalWords > 0 else { return 0.0 }
        return Double(totalReviews) / Double(totalWords)
    }
}

// Note: UserProgressEntity.toModel() extension is defined in ModelTransformers.swift
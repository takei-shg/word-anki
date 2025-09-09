import Foundation
import CoreData
import os.log

class TextSourceRepository: RepositoryProtocol {
    typealias Entity = TextSourceEntity
    typealias Model = TextSource
    
    let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.vocabularyapp", category: "textSourceRepository")
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - CRUD Operations
    
    func create(_ model: TextSource) async throws -> TextSource {
        return try await persistenceController.performBackgroundTask { context in
            let entity = TextSourceEntity(context: context)
            entity.id = model.id
            entity.title = model.title
            entity.content = model.content
            entity.uploadDate = model.uploadDate
            entity.wordCount = Int32(model.wordCount)
            entity.processedDate = model.processedDate
            entity.isProcessed = model.processedDate != nil
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Created text source with ID: \(model.id)")
            
            return model
        }
    }
    
    func fetch(by id: UUID) async throws -> TextSource? {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toModel()
        }
    }
    
    func fetchAll() async throws -> [TextSource] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TextSourceEntity.uploadDate, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func update(_ model: TextSource) async throws -> TextSource {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", model.id as CVarArg)
            request.fetchLimit = 1
            
            guard let entity = try context.fetch(request).first else {
                throw PersistenceError.entityNotFound
            }
            
            entity.title = model.title
            entity.content = model.content
            entity.uploadDate = model.uploadDate
            entity.wordCount = Int32(model.wordCount)
            entity.processedDate = model.processedDate
            entity.isProcessed = model.processedDate != nil
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Updated text source with ID: \(model.id)")
            
            return model
        }
    }
    
    func delete(by id: UUID) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Deleted text source with ID: \(id)")
        }
    }
    
    func deleteAll() async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = TextSourceEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount
            
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Deleted \(deletedCount) text sources")
        }
    }
    
    // MARK: - Additional Methods
    
    func fetchProcessed() async throws -> [TextSource] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isProcessed == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TextSourceEntity.processedDate, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func fetchUnprocessed() async throws -> [TextSource] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isProcessed == NO")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TextSourceEntity.uploadDate, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    func markAsProcessed(_ id: UUID, wordCount: Int, processedDate: Date = Date()) async throws {
        try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let entity = try context.fetch(request).first else {
                throw PersistenceError.entityNotFound
            }
            
            entity.isProcessed = true
            entity.processedDate = processedDate
            entity.wordCount = Int32(wordCount)
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Marked text source as processed: \(id)")
        }
    }
}

// Note: TextSourceEntity.toModel() extension is defined in ModelTransformers.swift
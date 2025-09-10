import Foundation
import CoreData
import os.log

/// Manages offline operations queue for synchronization when connectivity returns
class OfflineSyncQueue {
    
    // MARK: - Properties
    
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.vocabularyapp", category: "offlineSyncQueue")
    private let maxQueueSize = 1000
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        logger.info("OfflineSyncQueue initialized")
    }
    
    // MARK: - Queue Operations
    
    /// Queue progress sync operation for later processing
    func queueProgressSync(_ progress: UserProgress) async {
        await performQueueOperation { context in
            let operation = SyncOperationEntity(context: context)
            operation.id = UUID()
            operation.type = SyncOperationType.progressSync.rawValue
            operation.createdDate = Date()
            operation.retryCount = 0
            operation.isProcessed = false
            
            // Store progress data as JSON
            if let progressData = try? JSONEncoder().encode(progress) {
                operation.data = progressData
                operation.relatedId = progress.wordId
            }
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Queued progress sync for word: \(progress.wordId)")
        }
    }
    
    /// Queue text source sync operation
    func queueTextSourceSync(_ source: TextSource) async {
        await performQueueOperation { context in
            let operation = SyncOperationEntity(context: context)
            operation.id = UUID()
            operation.type = SyncOperationType.textSourceSync.rawValue
            operation.createdDate = Date()
            operation.retryCount = 0
            operation.isProcessed = false
            
            // Store source data as JSON
            if let sourceData = try? JSONEncoder().encode(source) {
                operation.data = sourceData
                operation.relatedId = source.id
            }
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Queued text source sync: \(source.title)")
        }
    }
    
    /// Queue text source deletion operation
    func queueTextSourceDeletion(_ sourceId: UUID) async {
        await performQueueOperation { context in
            let operation = SyncOperationEntity(context: context)
            operation.id = UUID()
            operation.type = SyncOperationType.textSourceDeletion.rawValue
            operation.createdDate = Date()
            operation.retryCount = 0
            operation.isProcessed = false
            operation.relatedId = sourceId
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Queued text source deletion: \(sourceId)")
        }
    }
    
    // MARK: - Queue Processing
    
    /// Process all pending sync operations
    func processPendingOperations() async {
        logger.info("Processing pending sync operations")
        
        do {
            let pendingOperations = try await fetchPendingOperations()
            logger.info("Found \(pendingOperations.count) pending operations")
            
            for operation in pendingOperations {
                await processOperation(operation)
            }
        } catch {
            logger.error("Failed to process pending operations: \(error.localizedDescription)")
        }
    }
    
    /// Process a single sync operation
    private func processOperation(_ operation: SyncOperation) async {
        logger.info("Processing operation: \(operation.type) for \(operation.relatedId?.uuidString ?? "unknown")")
        
        do {
            switch operation.type {
            case .progressSync:
                await processProgressSync(operation)
            case .textSourceSync:
                await processTextSourceSync(operation)
            case .textSourceDeletion:
                await processTextSourceDeletion(operation)
            }
            
            // Mark operation as processed
            await markOperationAsProcessed(operation.id)
            
        } catch {
            logger.error("Failed to process operation \(operation.id): \(error.localizedDescription)")
            await incrementRetryCount(operation.id)
        }
    }
    
    private func processProgressSync(_ operation: SyncOperation) async throws {
        guard let data = operation.data,
              let progress = try? JSONDecoder().decode(UserProgress.self, from: data) else {
            throw SyncError.invalidOperationData
        }
        
        // Here you would typically call your API service to sync progress
        // For now, we'll just log the operation
        logger.info("Would sync progress for word: \(progress.wordId)")
        
        // In a real implementation, you would:
        // try await apiService.syncProgress([progress])
    }
    
    private func processTextSourceSync(_ operation: SyncOperation) async throws {
        guard let data = operation.data,
              let source = try? JSONDecoder().decode(TextSource.self, from: data) else {
            throw SyncError.invalidOperationData
        }
        
        // Here you would typically call your API service to upload the text source
        logger.info("Would sync text source: \(source.title)")
        
        // In a real implementation, you would:
        // try await apiService.uploadTextSource(source)
    }
    
    private func processTextSourceDeletion(_ operation: SyncOperation) async throws {
        guard let sourceId = operation.relatedId else {
            throw SyncError.invalidOperationData
        }
        
        // Here you would typically call your API service to delete the text source
        logger.info("Would delete text source: \(sourceId)")
        
        // In a real implementation, you would:
        // try await apiService.deleteTextSource(sourceId)
    }
    
    // MARK: - Queue Management
    
    /// Get count of pending operations
    func getPendingOperationsCount() async -> Int {
        do {
            return try await persistenceController.performBackgroundTask { context in
                let request: NSFetchRequest<SyncOperationEntity> = SyncOperationEntity.fetchRequest()
                request.predicate = NSPredicate(format: "isProcessed == NO")
                return try context.count(for: request)
            }
        } catch {
            logger.error("Failed to get pending operations count: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Fetch all pending operations
    private func fetchPendingOperations() async throws -> [SyncOperation] {
        return try await persistenceController.performBackgroundTask { context in
            let request: NSFetchRequest<SyncOperationEntity> = SyncOperationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isProcessed == NO AND retryCount < 3")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \SyncOperationEntity.createdDate, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toModel() }
        }
    }
    
    /// Mark operation as processed
    private func markOperationAsProcessed(_ operationId: UUID) async {
        await performQueueOperation { context in
            let request: NSFetchRequest<SyncOperationEntity> = SyncOperationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", operationId as CVarArg)
            request.fetchLimit = 1
            
            if let entity = try context.fetch(request).first {
                entity.isProcessed = true
                entity.processedDate = Date()
                try self.persistenceController.saveBackground(context)
                self.logger.info("Marked operation as processed: \(operationId)")
            }
        }
    }
    
    /// Increment retry count for failed operation
    private func incrementRetryCount(_ operationId: UUID) async {
        await performQueueOperation { context in
            let request: NSFetchRequest<SyncOperationEntity> = SyncOperationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", operationId as CVarArg)
            request.fetchLimit = 1
            
            if let entity = try context.fetch(request).first {
                entity.retryCount += 1
                entity.lastRetryDate = Date()
                try self.persistenceController.saveBackground(context)
                self.logger.info("Incremented retry count for operation: \(operationId), count: \(entity.retryCount)")
            }
        }
    }
    
    /// Clear all operations from queue
    func clearQueue() async {
        await performQueueOperation { context in
            let request: NSFetchRequest<NSFetchRequestResult> = SyncOperationEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount
            
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Cleared \(deletedCount) operations from sync queue")
        }
    }
    
    /// Remove old processed operations to prevent queue bloat
    func cleanupProcessedOperations(olderThan days: Int = 7) async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        await performQueueOperation { context in
            let request: NSFetchRequest<NSFetchRequestResult> = SyncOperationEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isProcessed == YES AND processedDate < %@", cutoffDate as NSDate)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeCount
            
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            
            try self.persistenceController.saveBackground(context)
            self.logger.info("Cleaned up \(deletedCount) old processed operations")
        }
    }
    
    // MARK: - Helper Methods
    
    private func performQueueOperation(_ operation: @escaping (NSManagedObjectContext) throws -> Void) async {
        do {
            try await persistenceController.performBackgroundTask(operation)
        } catch {
            logger.error("Queue operation failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

// SyncOperation, SyncOperationType, and SyncError are defined in Models/SyncOperation.swift
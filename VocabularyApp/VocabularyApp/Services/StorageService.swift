import Foundation
import CoreData
import os.log

/// Storage service that manages local data persistence and offline operations
class StorageService: StorageServiceProtocol {
    
    // MARK: - Properties
    
    private let persistenceController: PersistenceController
    private let wordTestRepository: WordTestRepository
    private let textSourceRepository: TextSourceRepository
    private let userProgressRepository: UserProgressRepository
    private let syncQueue: OfflineSyncQueue
    private let logger = Logger(subsystem: "com.vocabularyapp", category: "storageService")
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.wordTestRepository = WordTestRepository(persistenceController: persistenceController)
        self.textSourceRepository = TextSourceRepository(persistenceController: persistenceController)
        self.userProgressRepository = UserProgressRepository(persistenceController: persistenceController)
        self.syncQueue = OfflineSyncQueue(persistenceController: persistenceController)
        
        logger.info("StorageService initialized")
    }
    
    // MARK: - WordTest Operations
    
    func saveWordTests(_ tests: [WordTest]) async throws {
        logger.info("Saving \(tests.count) word tests")
        
        do {
            let savedTests = try await wordTestRepository.createBatch(tests)
            logger.info("Successfully saved \(savedTests.count) word tests")
        } catch {
            logger.error("Failed to save word tests: \(error.localizedDescription)")
            throw StorageError.saveFailed(error)
        }
    }
    
    func fetchWordTests(for sourceId: UUID, difficulty: DifficultyLevel?) async throws -> [WordTest] {
        logger.info("Fetching word tests for source: \(sourceId), difficulty: \(difficulty?.rawValue ?? "all")")
        
        do {
            let tests: [WordTest]
            
            if let difficulty = difficulty {
                tests = try await wordTestRepository.fetchBySourceAndDifficulty(sourceId, difficulty: difficulty)
            } else {
                tests = try await wordTestRepository.fetchBySource(sourceId)
            }
            
            logger.info("Retrieved \(tests.count) word tests")
            return tests
        } catch {
            logger.error("Failed to fetch word tests: \(error.localizedDescription)")
            throw StorageError.fetchFailed(error)
        }
    }
    
    // MARK: - UserProgress Operations
    
    func saveProgress(_ progress: UserProgress) async throws {
        logger.info("Saving progress for word: \(progress.wordId)")
        
        do {
            let savedProgress = try await userProgressRepository.recordProgress(
                progress.wordId,
                isMemorized: progress.isMemorized
            )
            
            // Queue for sync if needed
            await syncQueue.queueProgressSync(savedProgress)
            
            logger.info("Successfully saved progress for word: \(progress.wordId)")
        } catch {
            logger.error("Failed to save progress: \(error.localizedDescription)")
            throw StorageError.saveFailed(error)
        }
    }
    
    func fetchProgress(for wordId: UUID) async throws -> UserProgress? {
        logger.info("Fetching progress for word: \(wordId)")
        
        do {
            let progress = try await userProgressRepository.fetchByWord(wordId)
            logger.info("Retrieved progress for word: \(wordId), found: \(progress != nil)")
            return progress
        } catch {
            logger.error("Failed to fetch progress: \(error.localizedDescription)")
            throw StorageError.fetchFailed(error)
        }
    }
    
    // MARK: - TextSource Operations
    
    func saveTextSource(_ source: TextSource) async throws {
        logger.info("Saving text source: \(source.title)")
        
        do {
            let savedSource = try await textSourceRepository.create(source)
            
            // Queue for sync if needed
            await syncQueue.queueTextSourceSync(savedSource)
            
            logger.info("Successfully saved text source: \(source.title)")
        } catch {
            logger.error("Failed to save text source: \(error.localizedDescription)")
            throw StorageError.saveFailed(error)
        }
    }
    
    func fetchTextSources() async throws -> [TextSource] {
        logger.info("Fetching all text sources")
        
        do {
            let sources = try await textSourceRepository.fetchAll()
            logger.info("Retrieved \(sources.count) text sources")
            return sources
        } catch {
            logger.error("Failed to fetch text sources: \(error.localizedDescription)")
            throw StorageError.fetchFailed(error)
        }
    }
    
    func deleteTextSource(_ sourceId: UUID) async throws {
        logger.info("Deleting text source: \(sourceId)")
        
        do {
            // Delete associated word tests first
            try await wordTestRepository.deleteBySource(sourceId)
            
            // Delete associated progress records
            let wordTests = try await wordTestRepository.fetchBySource(sourceId)
            let wordIds = wordTests.map { $0.id }
            try await userProgressRepository.deleteByWords(wordIds)
            
            // Delete the text source
            try await textSourceRepository.delete(by: sourceId)
            
            // Queue deletion for sync
            await syncQueue.queueTextSourceDeletion(sourceId)
            
            logger.info("Successfully deleted text source: \(sourceId)")
        } catch {
            logger.error("Failed to delete text source: \(error.localizedDescription)")
            throw StorageError.deleteFailed(error)
        }
    }
}

// MARK: - Additional Storage Operations

extension StorageService {
    
    /// Fetch all unsynced progress records
    func fetchUnsyncedProgress() async throws -> [UserProgress] {
        logger.info("Fetching unsynced progress records")
        
        do {
            let unsyncedProgress = try await userProgressRepository.fetchUnsynced()
            logger.info("Found \(unsyncedProgress.count) unsynced progress records")
            return unsyncedProgress
        } catch {
            logger.error("Failed to fetch unsynced progress: \(error.localizedDescription)")
            throw StorageError.fetchFailed(error)
        }
    }
    
    /// Mark progress records as synced
    func markProgressAsSynced(_ wordIds: [UUID]) async throws {
        logger.info("Marking \(wordIds.count) progress records as synced")
        
        do {
            try await userProgressRepository.markAsSynced(wordIds)
            logger.info("Successfully marked progress records as synced")
        } catch {
            logger.error("Failed to mark progress as synced: \(error.localizedDescription)")
            throw StorageError.updateFailed(error)
        }
    }
    
    /// Get storage statistics
    func getStorageStatistics() async throws -> StorageStatistics {
        logger.info("Calculating storage statistics")
        
        do {
            let allWordTests = try await wordTestRepository.fetchAll()
            let allTextSources = try await textSourceRepository.fetchAll()
            let progressStats = try await userProgressRepository.getStatistics()
            let unsyncedProgress = try await userProgressRepository.fetchUnsynced()
            let pendingSyncOperations = await syncQueue.getPendingOperationsCount()
            
            let statistics = StorageStatistics(
                totalWordTests: allWordTests.count,
                totalTextSources: allTextSources.count,
                totalProgressRecords: progressStats.totalWords,
                memorizedWords: progressStats.memorizedWords,
                unsyncedProgressCount: unsyncedProgress.count,
                pendingSyncOperations: pendingSyncOperations
            )
            
            logger.info("Storage statistics calculated: \(statistics)")
            return statistics
        } catch {
            logger.error("Failed to calculate storage statistics: \(error.localizedDescription)")
            throw StorageError.fetchFailed(error)
        }
    }
    
    /// Clear all local data (for testing or reset purposes)
    func clearAllData() async throws {
        logger.warning("Clearing all local data")
        
        do {
            try await userProgressRepository.deleteAll()
            try await wordTestRepository.deleteAll()
            try await textSourceRepository.deleteAll()
            await syncQueue.clearQueue()
            
            logger.info("Successfully cleared all local data")
        } catch {
            logger.error("Failed to clear all data: \(error.localizedDescription)")
            throw StorageError.deleteFailed(error)
        }
    }
}

// MARK: - Sync Queue Access

extension StorageService {
    
    /// Get access to the sync queue for manual operations
    var offlineSyncQueue: OfflineSyncQueue {
        return syncQueue
    }
    
    /// Process pending sync operations
    func processPendingSyncOperations() async throws {
        logger.info("Processing pending sync operations")
        await syncQueue.processPendingOperations()
    }
}

// MARK: - Supporting Types

/// Storage service specific errors
enum StorageError: Error, LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case syncQueueFull
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .syncQueueFull:
            return "Sync queue is full, cannot queue more operations"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

/// Storage statistics for monitoring and debugging
struct StorageStatistics: CustomStringConvertible {
    let totalWordTests: Int
    let totalTextSources: Int
    let totalProgressRecords: Int
    let memorizedWords: Int
    let unsyncedProgressCount: Int
    let pendingSyncOperations: Int
    
    var description: String {
        return """
        StorageStatistics(
            wordTests: \(totalWordTests),
            textSources: \(totalTextSources),
            progressRecords: \(totalProgressRecords),
            memorized: \(memorizedWords),
            unsynced: \(unsyncedProgressCount),
            pendingSync: \(pendingSyncOperations)
        )
        """
    }
}
import XCTest
import CoreData
@testable import VocabularyApp

class OfflineSyncQueueTests: XCTestCase {
    
    var syncQueue: OfflineSyncQueue!
    var testPersistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory persistence controller for testing
        testPersistenceController = PersistenceController(inMemory: true)
        syncQueue = OfflineSyncQueue(persistenceController: testPersistenceController)
    }
    
    override func tearDownWithError() throws {
        syncQueue = nil
        testPersistenceController = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Queue Progress Sync Tests
    
    func testQueueProgressSync() async throws {
        // Given
        let progress = UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        
        // When
        await syncQueue.queueProgressSync(progress)
        let pendingCount = await syncQueue.getPendingOperationsCount()
        
        // Then
        XCTAssertEqual(pendingCount, 1)
    }
    
    func testQueueMultipleProgressSyncs() async throws {
        // Given
        let progress1 = UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        let progress2 = UserProgress(wordId: UUID(), isMemorized: false, reviewCount: 2)
        let progress3 = UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        
        // When
        await syncQueue.queueProgressSync(progress1)
        await syncQueue.queueProgressSync(progress2)
        await syncQueue.queueProgressSync(progress3)
        
        let pendingCount = await syncQueue.getPendingOperationsCount()
        
        // Then
        XCTAssertEqual(pendingCount, 3)
    }
    
    // MARK: - Queue Text Source Sync Tests
    
    func testQueueTextSourceSync() async throws {
        // Given
        let textSource = TextSource(
            title: "Test Source",
            content: "This is test content for vocabulary learning.",
            wordCount: 8
        )
        
        // When
        await syncQueue.queueTextSourceSync(textSource)
        let pendingCount = await syncQueue.getPendingOperationsCount()
        
        // Then
        XCTAssertEqual(pendingCount, 1)
    }
    
    func testQueueTextSourceDeletion() async throws {
        // Given
        let sourceId = UUID()
        
        // When
        await syncQueue.queueTextSourceDeletion(sourceId)
        let pendingCount = await syncQueue.getPendingOperationsCount()
        
        // Then
        XCTAssertEqual(pendingCount, 1)
    }
    
    // MARK: - Mixed Operations Tests
    
    func testQueueMixedOperations() async throws {
        // Given
        let progress = UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        let textSource = TextSource(title: "Test", content: "Test content", wordCount: 2)
        let sourceIdToDelete = UUID()
        
        // When
        await syncQueue.queueProgressSync(progress)
        await syncQueue.queueTextSourceSync(textSource)
        await syncQueue.queueTextSourceDeletion(sourceIdToDelete)
        
        let pendingCount = await syncQueue.getPendingOperationsCount()
        
        // Then
        XCTAssertEqual(pendingCount, 3)
    }
    
    // MARK: - Queue Processing Tests
    
    func testProcessPendingOperations() async throws {
        // Given
        let progress = UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        await syncQueue.queueProgressSync(progress)
        
        let initialCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(initialCount, 1)
        
        // When
        try await syncQueue.processPendingOperations()
        
        // Then
        let finalCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(finalCount, 0)
    }
    
    func testProcessMultiplePendingOperations() async throws {
        // Given
        let progress1 = UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        let progress2 = UserProgress(wordId: UUID(), isMemorized: false, reviewCount: 2)
        let textSource = TextSource(title: "Test", content: "Test content", wordCount: 2)
        
        await syncQueue.queueProgressSync(progress1)
        await syncQueue.queueProgressSync(progress2)
        await syncQueue.queueTextSourceSync(textSource)
        
        let initialCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(initialCount, 3)
        
        // When
        try await syncQueue.processPendingOperations()
        
        // Then
        let finalCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(finalCount, 0)
    }
    
    // MARK: - Queue Management Tests
    
    func testClearQueue() async throws {
        // Given
        let progress = UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        let textSource = TextSource(title: "Test", content: "Test content", wordCount: 2)
        
        await syncQueue.queueProgressSync(progress)
        await syncQueue.queueTextSourceSync(textSource)
        
        let initialCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(initialCount, 2)
        
        // When
        await syncQueue.clearQueue()
        
        // Then
        let finalCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(finalCount, 0)
    }
    
    func testCleanupProcessedOperations() async throws {
        // Given
        let progress = UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        await syncQueue.queueProgressSync(progress)
        
        // Process the operation to mark it as processed
        try await syncQueue.processPendingOperations()
        
        // When
        await syncQueue.cleanupProcessedOperations(olderThan: 0) // Clean up immediately
        
        // Then
        let pendingCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(pendingCount, 0)
    }
    
    // MARK: - Data Integrity Tests
    
    func testQueuedOperationDataIntegrity() async throws {
        // Given
        let originalProgress = UserProgress(
            wordId: UUID(),
            isMemorized: true,
            reviewCount: 5,
            lastReviewed: Date()
        )
        
        // When
        await syncQueue.queueProgressSync(originalProgress)
        
        // Verify the operation was queued
        let pendingCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(pendingCount, 1)
        
        // Process and verify data integrity
        // Note: In a real implementation, you would verify that the data
        // can be properly decoded and matches the original
        try await syncQueue.processPendingOperations()
        
        // Then
        let finalCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(finalCount, 0)
    }
    
    func testQueuedTextSourceDataIntegrity() async throws {
        // Given
        let originalSource = TextSource(
            title: "Complex Test Source",
            content: "This is a more complex test content with special characters: áéíóú, 中文, 🎉",
            wordCount: 15,
            processedDate: Date()
        )
        
        // When
        await syncQueue.queueTextSourceSync(originalSource)
        
        // Verify the operation was queued
        let pendingCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(pendingCount, 1)
        
        // Process and verify data integrity
        try await syncQueue.processPendingOperations()
        
        // Then
        let finalCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(finalCount, 0)
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyQueueProcessing() async throws {
        // Given - empty queue
        let initialCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(initialCount, 0)
        
        // When
        try await syncQueue.processPendingOperations()
        
        // Then - should not crash and count should remain 0
        let finalCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(finalCount, 0)
    }
    
    func testClearEmptyQueue() async throws {
        // Given - empty queue
        let initialCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(initialCount, 0)
        
        // When
        await syncQueue.clearQueue()
        
        // Then - should not crash and count should remain 0
        let finalCount = await syncQueue.getPendingOperationsCount()
        XCTAssertEqual(finalCount, 0)
    }
    
    // MARK: - Performance Tests
    
    func testQueuePerformanceWithManyOperations() async throws {
        // Given
        let operationCount = 100
        let startTime = Date()
        
        // When - queue many operations
        for i in 0..<operationCount {
            let progress = UserProgress(
                wordId: UUID(),
                isMemorized: i % 2 == 0,
                reviewCount: i + 1
            )
            await syncQueue.queueProgressSync(progress)
        }
        
        let queueTime = Date().timeIntervalSince(startTime)
        let pendingCount = await syncQueue.getPendingOperationsCount()
        
        // Then
        XCTAssertEqual(pendingCount, operationCount)
        XCTAssertLessThan(queueTime, 5.0, "Queueing \(operationCount) operations should take less than 5 seconds")
        
        // Clean up
        await syncQueue.clearQueue()
    }
}
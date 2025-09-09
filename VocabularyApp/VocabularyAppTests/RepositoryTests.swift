import XCTest
import CoreData
@testable import VocabularyApp

class RepositoryTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var textSourceRepository: TextSourceRepository!
    var wordTestRepository: WordTestRepository!
    var userProgressRepository: UserProgressRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        
        // Initialize repositories with test persistence controller
        textSourceRepository = TextSourceRepository(persistenceController: persistenceController)
        wordTestRepository = WordTestRepository(persistenceController: persistenceController)
        userProgressRepository = UserProgressRepository(persistenceController: persistenceController)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        textSourceRepository = nil
        wordTestRepository = nil
        userProgressRepository = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - TextSource Repository Tests
    
    func testTextSourceCRUD() async throws {
        // Create
        let textSource = TextSource(
            title: "Test Source",
            content: "This is a test content for vocabulary learning.",
            wordCount: 5
        )
        
        let createdSource = try await textSourceRepository.create(textSource)
        XCTAssertEqual(createdSource.id, textSource.id)
        XCTAssertEqual(createdSource.title, textSource.title)
        
        // Read
        let fetchedSource = try await textSourceRepository.fetch(by: textSource.id)
        XCTAssertNotNil(fetchedSource)
        XCTAssertEqual(fetchedSource?.title, textSource.title)
        
        // Update
        let updatedSource = TextSource(
            id: textSource.id,
            title: "Updated Test Source",
            content: textSource.content,
            uploadDate: textSource.uploadDate,
            wordCount: 10,
            processedDate: Date()
        )
        
        let result = try await textSourceRepository.update(updatedSource)
        XCTAssertEqual(result.title, "Updated Test Source")
        XCTAssertEqual(result.wordCount, 10)
        
        // Verify update
        let refetchedSource = try await textSourceRepository.fetch(by: textSource.id)
        XCTAssertEqual(refetchedSource?.title, "Updated Test Source")
        XCTAssertEqual(refetchedSource?.wordCount, 10)
        
        // Delete
        try await textSourceRepository.delete(by: textSource.id)
        
        // Verify deletion
        let deletedSource = try await textSourceRepository.fetch(by: textSource.id)
        XCTAssertNil(deletedSource)
    }
    
    func testTextSourceProcessedStatus() async throws {
        let textSource = TextSource(
            title: "Unprocessed Source",
            content: "This source is not processed yet.",
            wordCount: 0
        )
        
        _ = try await textSourceRepository.create(textSource)
        
        // Test fetching unprocessed sources
        let unprocessedSources = try await textSourceRepository.fetchUnprocessed()
        XCTAssertEqual(unprocessedSources.count, 1)
        XCTAssertEqual(unprocessedSources.first?.id, textSource.id)
        
        // Mark as processed
        try await textSourceRepository.markAsProcessed(textSource.id, wordCount: 15)
        
        // Test fetching processed sources
        let processedSources = try await textSourceRepository.fetchProcessed()
        XCTAssertEqual(processedSources.count, 1)
        XCTAssertEqual(processedSources.first?.wordCount, 15)
        
        // Verify unprocessed list is empty
        let updatedUnprocessedSources = try await textSourceRepository.fetchUnprocessed()
        XCTAssertEqual(updatedUnprocessedSources.count, 0)
    }
    
    // MARK: - WordTest Repository Tests
    
    func testWordTestCRUD() async throws {
        // First create a text source
        let textSource = TextSource(
            title: "Test Source",
            content: "This is a test content.",
            wordCount: 1
        )
        _ = try await textSourceRepository.create(textSource)
        
        // Create word test
        let wordTest = WordTest(
            word: "test",
            sentence: "This is a test sentence.",
            meaning: "A procedure to check something",
            difficultyLevel: .beginner,
            sourceId: textSource.id
        )
        
        let createdWordTest = try await wordTestRepository.create(wordTest)
        XCTAssertEqual(createdWordTest.word, wordTest.word)
        XCTAssertEqual(createdWordTest.difficultyLevel, wordTest.difficultyLevel)
        
        // Read
        let fetchedWordTest = try await wordTestRepository.fetch(by: wordTest.id)
        XCTAssertNotNil(fetchedWordTest)
        XCTAssertEqual(fetchedWordTest?.word, wordTest.word)
        
        // Update
        let updatedWordTest = WordTest(
            id: wordTest.id,
            word: "updated",
            sentence: "This is an updated sentence.",
            meaning: "Something that has been changed",
            difficultyLevel: .intermediate,
            sourceId: textSource.id
        )
        
        let result = try await wordTestRepository.update(updatedWordTest)
        XCTAssertEqual(result.word, "updated")
        XCTAssertEqual(result.difficultyLevel, .intermediate)
        
        // Delete
        try await wordTestRepository.delete(by: wordTest.id)
        
        // Verify deletion
        let deletedWordTest = try await wordTestRepository.fetch(by: wordTest.id)
        XCTAssertNil(deletedWordTest)
    }
    
    func testWordTestFiltering() async throws {
        // Create text source
        let textSource = TextSource(
            title: "Test Source",
            content: "Test content",
            wordCount: 3
        )
        _ = try await textSourceRepository.create(textSource)
        
        // Create word tests with different difficulty levels
        let beginnerWord = WordTest(
            word: "easy",
            sentence: "This is easy.",
            meaning: "Simple",
            difficultyLevel: .beginner,
            sourceId: textSource.id
        )
        
        let intermediateWord = WordTest(
            word: "moderate",
            sentence: "This is moderate.",
            meaning: "Medium difficulty",
            difficultyLevel: .intermediate,
            sourceId: textSource.id
        )
        
        let advancedWord = WordTest(
            word: "complex",
            sentence: "This is complex.",
            meaning: "Difficult",
            difficultyLevel: .advanced,
            sourceId: textSource.id
        )
        
        _ = try await wordTestRepository.create(beginnerWord)
        _ = try await wordTestRepository.create(intermediateWord)
        _ = try await wordTestRepository.create(advancedWord)
        
        // Test filtering by difficulty
        let beginnerWords = try await wordTestRepository.fetchByDifficulty(.beginner)
        XCTAssertEqual(beginnerWords.count, 1)
        XCTAssertEqual(beginnerWords.first?.word, "easy")
        
        let intermediateWords = try await wordTestRepository.fetchByDifficulty(.intermediate)
        XCTAssertEqual(intermediateWords.count, 1)
        XCTAssertEqual(intermediateWords.first?.word, "moderate")
        
        // Test filtering by source
        let sourceWords = try await wordTestRepository.fetchBySource(textSource.id)
        XCTAssertEqual(sourceWords.count, 3)
        
        // Test filtering by source and difficulty
        let sourceBeginnerWords = try await wordTestRepository.fetchBySourceAndDifficulty(textSource.id, difficulty: .beginner)
        XCTAssertEqual(sourceBeginnerWords.count, 1)
        XCTAssertEqual(sourceBeginnerWords.first?.word, "easy")
        
        // Test difficulty count
        let difficultyCounts = try await wordTestRepository.countByDifficulty()
        XCTAssertEqual(difficultyCounts[.beginner], 1)
        XCTAssertEqual(difficultyCounts[.intermediate], 1)
        XCTAssertEqual(difficultyCounts[.advanced], 1)
    }
    
    func testWordTestBatchOperations() async throws {
        // Create text source
        let textSource = TextSource(
            title: "Batch Test Source",
            content: "Batch test content",
            wordCount: 2
        )
        _ = try await textSourceRepository.create(textSource)
        
        // Create batch of word tests
        let wordTests = [
            WordTest(
                word: "first",
                sentence: "This is the first word.",
                meaning: "Number one",
                difficultyLevel: .beginner,
                sourceId: textSource.id
            ),
            WordTest(
                word: "second",
                sentence: "This is the second word.",
                meaning: "Number two",
                difficultyLevel: .beginner,
                sourceId: textSource.id
            )
        ]
        
        let createdWords = try await wordTestRepository.createBatch(wordTests)
        XCTAssertEqual(createdWords.count, 2)
        
        // Verify batch creation
        let sourceWords = try await wordTestRepository.fetchBySource(textSource.id)
        XCTAssertEqual(sourceWords.count, 2)
        
        // Test batch deletion by source
        try await wordTestRepository.deleteBySource(textSource.id)
        
        let remainingWords = try await wordTestRepository.fetchBySource(textSource.id)
        XCTAssertEqual(remainingWords.count, 0)
    }
    
    // MARK: - UserProgress Repository Tests
    
    func testUserProgressCRUD() async throws {
        let wordId = UUID()
        
        // Create progress
        let progress = UserProgress(
            wordId: wordId,
            isMemorized: false,
            reviewCount: 1
        )
        
        let createdProgress = try await userProgressRepository.create(progress)
        XCTAssertEqual(createdProgress.wordId, wordId)
        XCTAssertFalse(createdProgress.isMemorized)
        XCTAssertEqual(createdProgress.reviewCount, 1)
        
        // Read by word
        let fetchedProgress = try await userProgressRepository.fetchByWord(wordId)
        XCTAssertNotNil(fetchedProgress)
        XCTAssertEqual(fetchedProgress?.wordId, wordId)
        
        // Update
        let updatedProgress = UserProgress(
            wordId: wordId,
            isMemorized: true,
            reviewCount: 2
        )
        
        let result = try await userProgressRepository.update(updatedProgress)
        XCTAssertTrue(result.isMemorized)
        XCTAssertEqual(result.reviewCount, 2)
        
        // Verify update
        let refetchedProgress = try await userProgressRepository.fetchByWord(wordId)
        XCTAssertTrue(refetchedProgress?.isMemorized ?? false)
        XCTAssertEqual(refetchedProgress?.reviewCount, 2)
    }
    
    func testProgressRecording() async throws {
        let wordId = UUID()
        
        // Record first progress (not memorized)
        let firstProgress = try await userProgressRepository.recordProgress(wordId, isMemorized: false)
        XCTAssertFalse(firstProgress.isMemorized)
        XCTAssertEqual(firstProgress.reviewCount, 1)
        
        // Record second progress (memorized)
        let secondProgress = try await userProgressRepository.recordProgress(wordId, isMemorized: true)
        XCTAssertTrue(secondProgress.isMemorized)
        XCTAssertEqual(secondProgress.reviewCount, 2)
        
        // Verify the progress was updated, not duplicated
        let allProgress = try await userProgressRepository.fetchAll()
        let wordProgress = allProgress.filter { $0.wordId == wordId }
        XCTAssertEqual(wordProgress.count, 1)
        XCTAssertTrue(wordProgress.first?.isMemorized ?? false)
        XCTAssertEqual(wordProgress.first?.reviewCount, 2)
    }
    
    func testProgressFiltering() async throws {
        let wordId1 = UUID()
        let wordId2 = UUID()
        let wordId3 = UUID()
        
        // Create different progress records
        _ = try await userProgressRepository.recordProgress(wordId1, isMemorized: true)
        _ = try await userProgressRepository.recordProgress(wordId2, isMemorized: false)
        _ = try await userProgressRepository.recordProgress(wordId3, isMemorized: true)
        
        // Test memorized filtering
        let memorizedProgress = try await userProgressRepository.fetchMemorized()
        XCTAssertEqual(memorizedProgress.count, 2)
        
        let notMemorizedProgress = try await userProgressRepository.fetchNotMemorized()
        XCTAssertEqual(notMemorizedProgress.count, 1)
        XCTAssertEqual(notMemorizedProgress.first?.wordId, wordId2)
    }
    
    func testProgressStatistics() async throws {
        let wordIds = [UUID(), UUID(), UUID(), UUID()]
        
        // Create progress records
        _ = try await userProgressRepository.recordProgress(wordIds[0], isMemorized: true)
        _ = try await userProgressRepository.recordProgress(wordIds[1], isMemorized: true)
        _ = try await userProgressRepository.recordProgress(wordIds[2], isMemorized: false)
        _ = try await userProgressRepository.recordProgress(wordIds[3], isMemorized: false)
        
        // Add additional reviews
        _ = try await userProgressRepository.recordProgress(wordIds[0], isMemorized: true)
        _ = try await userProgressRepository.recordProgress(wordIds[1], isMemorized: false)
        
        let statistics = try await userProgressRepository.getStatistics()
        
        XCTAssertEqual(statistics.totalWords, 4)
        XCTAssertEqual(statistics.memorizedWords, 1) // Only wordIds[0] is still memorized
        XCTAssertEqual(statistics.notMemorizedWords, 3)
        XCTAssertEqual(statistics.totalReviews, 6) // 2+2+1+1 reviews
        XCTAssertEqual(statistics.memorizedPercentage, 25.0)
        XCTAssertEqual(statistics.averageReviewsPerWord, 1.5)
    }
    
    func testProgressSyncStatus() async throws {
        let wordId = UUID()
        
        // Record progress (should be unsynced initially)
        _ = try await userProgressRepository.recordProgress(wordId, isMemorized: true)
        
        let unsyncedProgress = try await userProgressRepository.fetchUnsynced()
        XCTAssertEqual(unsyncedProgress.count, 1)
        XCTAssertEqual(unsyncedProgress.first?.wordId, wordId)
        
        // Mark as synced
        try await userProgressRepository.markAsSynced([wordId])
        
        let updatedUnsyncedProgress = try await userProgressRepository.fetchUnsynced()
        XCTAssertEqual(updatedUnsyncedProgress.count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testRepositoryIntegration() async throws {
        // Create a complete workflow: TextSource -> WordTests -> UserProgress
        
        // 1. Create text source
        let textSource = TextSource(
            title: "Integration Test Source",
            content: "This is an integration test content with multiple words.",
            wordCount: 0
        )
        _ = try await textSourceRepository.create(textSource)
        
        // 2. Create word tests for the source
        let wordTests = [
            WordTest(
                word: "integration",
                sentence: "This is an integration test.",
                meaning: "The process of combining parts",
                difficultyLevel: .intermediate,
                sourceId: textSource.id
            ),
            WordTest(
                word: "test",
                sentence: "This is a test word.",
                meaning: "A procedure to check something",
                difficultyLevel: .beginner,
                sourceId: textSource.id
            )
        ]
        
        _ = try await wordTestRepository.createBatch(wordTests)
        
        // 3. Mark source as processed
        try await textSourceRepository.markAsProcessed(textSource.id, wordCount: wordTests.count)
        
        // 4. Record progress for words
        for wordTest in wordTests {
            _ = try await userProgressRepository.recordProgress(wordTest.id, isMemorized: false)
        }
        
        // 5. Verify the complete workflow
        let processedSources = try await textSourceRepository.fetchProcessed()
        XCTAssertEqual(processedSources.count, 1)
        XCTAssertEqual(processedSources.first?.wordCount, 2)
        
        let sourceWords = try await wordTestRepository.fetchBySource(textSource.id)
        XCTAssertEqual(sourceWords.count, 2)
        
        let allProgress = try await userProgressRepository.fetchAll()
        XCTAssertEqual(allProgress.count, 2)
        
        let statistics = try await userProgressRepository.getStatistics()
        XCTAssertEqual(statistics.totalWords, 2)
        XCTAssertEqual(statistics.notMemorizedWords, 2)
        
        // 6. Clean up by deleting source (should cascade)
        try await wordTestRepository.deleteBySource(textSource.id)
        try await userProgressRepository.deleteByWords(wordTests.map { $0.id })
        try await textSourceRepository.delete(by: textSource.id)
        
        // Verify cleanup
        let remainingWords = try await wordTestRepository.fetchBySource(textSource.id)
        XCTAssertEqual(remainingWords.count, 0)
        
        let remainingSources = try await textSourceRepository.fetchAll()
        XCTAssertEqual(remainingSources.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async throws {
        // Test fetching non-existent entity
        let nonExistentId = UUID()
        let nonExistentSource = try await textSourceRepository.fetch(by: nonExistentId)
        XCTAssertNil(nonExistentSource)
        
        // Test updating non-existent entity
        let nonExistentTextSource = TextSource(
            id: nonExistentId,
            title: "Non-existent",
            content: "This doesn't exist"
        )
        
        do {
            _ = try await textSourceRepository.update(nonExistentTextSource)
            XCTFail("Should have thrown an error")
        } catch PersistenceError.entityNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
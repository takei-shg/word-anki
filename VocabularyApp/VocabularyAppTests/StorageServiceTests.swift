import XCTest
import CoreData
@testable import VocabularyApp

class StorageServiceTests: XCTestCase {
    
    var storageService: StorageService!
    var testPersistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory persistence controller for testing
        testPersistenceController = PersistenceController(inMemory: true)
        storageService = StorageService(persistenceController: testPersistenceController)
    }
    
    override func tearDownWithError() throws {
        storageService = nil
        testPersistenceController = nil
        try super.tearDownWithError()
    }
    
    // MARK: - WordTest Tests
    
    func testSaveAndFetchWordTests() async throws {
        // Given
        let textSource = createTestTextSource()
        try await storageService.saveTextSource(textSource)
        
        let wordTests = createTestWordTests(sourceId: textSource.id)
        
        // When
        try await storageService.saveWordTests(wordTests)
        let fetchedTests = try await storageService.fetchWordTests(for: textSource.id, difficulty: nil)
        
        // Then
        XCTAssertEqual(fetchedTests.count, wordTests.count)
        XCTAssertEqual(Set(fetchedTests.map { $0.id }), Set(wordTests.map { $0.id }))
    }
    
    func testFetchWordTestsByDifficulty() async throws {
        // Given
        let textSource = createTestTextSource()
        try await storageService.saveTextSource(textSource)
        
        let wordTests = createTestWordTests(sourceId: textSource.id)
        try await storageService.saveWordTests(wordTests)
        
        // When
        let beginnerTests = try await storageService.fetchWordTests(for: textSource.id, difficulty: .beginner)
        let intermediateTests = try await storageService.fetchWordTests(for: textSource.id, difficulty: .intermediate)
        
        // Then
        XCTAssertEqual(beginnerTests.count, 1)
        XCTAssertEqual(intermediateTests.count, 1)
        XCTAssertEqual(beginnerTests.first?.difficultyLevel, .beginner)
        XCTAssertEqual(intermediateTests.first?.difficultyLevel, .intermediate)
    }
    
    // MARK: - UserProgress Tests
    
    func testSaveAndFetchProgress() async throws {
        // Given
        let wordId = UUID()
        let progress = UserProgress(wordId: wordId, isMemorized: true, reviewCount: 1)
        
        // When
        try await storageService.saveProgress(progress)
        let fetchedProgress = try await storageService.fetchProgress(for: wordId)
        
        // Then
        XCTAssertNotNil(fetchedProgress)
        XCTAssertEqual(fetchedProgress?.wordId, wordId)
        XCTAssertEqual(fetchedProgress?.isMemorized, true)
        XCTAssertEqual(fetchedProgress?.reviewCount, 1)
    }
    
    func testProgressUpdate() async throws {
        // Given
        let wordId = UUID()
        let initialProgress = UserProgress(wordId: wordId, isMemorized: false, reviewCount: 1)
        try await storageService.saveProgress(initialProgress)
        
        // When
        let updatedProgress = UserProgress(wordId: wordId, isMemorized: true, reviewCount: 2)
        try await storageService.saveProgress(updatedProgress)
        
        let fetchedProgress = try await storageService.fetchProgress(for: wordId)
        
        // Then
        XCTAssertNotNil(fetchedProgress)
        XCTAssertEqual(fetchedProgress?.isMemorized, true)
        XCTAssertEqual(fetchedProgress?.reviewCount, 2)
    }
    
    // MARK: - TextSource Tests
    
    func testSaveAndFetchTextSources() async throws {
        // Given
        let textSources = [
            createTestTextSource(title: "Source 1"),
            createTestTextSource(title: "Source 2")
        ]
        
        // When
        for source in textSources {
            try await storageService.saveTextSource(source)
        }
        let fetchedSources = try await storageService.fetchTextSources()
        
        // Then
        XCTAssertEqual(fetchedSources.count, 2)
        XCTAssertTrue(fetchedSources.contains { $0.title == "Source 1" })
        XCTAssertTrue(fetchedSources.contains { $0.title == "Source 2" })
    }
    
    func testDeleteTextSource() async throws {
        // Given
        let textSource = createTestTextSource()
        try await storageService.saveTextSource(textSource)
        
        let wordTests = createTestWordTests(sourceId: textSource.id)
        try await storageService.saveWordTests(wordTests)
        
        // When
        try await storageService.deleteTextSource(textSource.id)
        
        // Then
        let fetchedSources = try await storageService.fetchTextSources()
        let fetchedTests = try await storageService.fetchWordTests(for: textSource.id, difficulty: nil)
        
        XCTAssertTrue(fetchedSources.isEmpty)
        XCTAssertTrue(fetchedTests.isEmpty)
    }
    
    // MARK: - Sync Operations Tests
    
    func testFetchUnsyncedProgress() async throws {
        // Given
        let wordId1 = UUID()
        let wordId2 = UUID()
        
        let progress1 = UserProgress(wordId: wordId1, isMemorized: true)
        let progress2 = UserProgress(wordId: wordId2, isMemorized: false)
        
        try await storageService.saveProgress(progress1)
        try await storageService.saveProgress(progress2)
        
        // When
        let unsyncedProgress = try await storageService.fetchUnsyncedProgress()
        
        // Then
        XCTAssertEqual(unsyncedProgress.count, 2)
        XCTAssertTrue(unsyncedProgress.contains { $0.wordId == wordId1 })
        XCTAssertTrue(unsyncedProgress.contains { $0.wordId == wordId2 })
    }
    
    func testMarkProgressAsSynced() async throws {
        // Given
        let wordId = UUID()
        let progress = UserProgress(wordId: wordId, isMemorized: true)
        try await storageService.saveProgress(progress)
        
        // When
        try await storageService.markProgressAsSynced([wordId])
        let unsyncedProgress = try await storageService.fetchUnsyncedProgress()
        
        // Then
        XCTAssertTrue(unsyncedProgress.isEmpty)
    }
    
    // MARK: - Storage Statistics Tests
    
    func testStorageStatistics() async throws {
        // Given
        let textSource = createTestTextSource()
        try await storageService.saveTextSource(textSource)
        
        let wordTests = createTestWordTests(sourceId: textSource.id)
        try await storageService.saveWordTests(wordTests)
        
        let progress1 = UserProgress(wordId: wordTests[0].id, isMemorized: true)
        let progress2 = UserProgress(wordId: wordTests[1].id, isMemorized: false)
        try await storageService.saveProgress(progress1)
        try await storageService.saveProgress(progress2)
        
        // When
        let statistics = try await storageService.getStorageStatistics()
        
        // Then
        XCTAssertEqual(statistics.totalWordTests, 3)
        XCTAssertEqual(statistics.totalTextSources, 1)
        XCTAssertEqual(statistics.totalProgressRecords, 2)
        XCTAssertEqual(statistics.memorizedWords, 1)
    }
    
    // MARK: - Clear Data Tests
    
    func testClearAllData() async throws {
        // Given
        let textSource = createTestTextSource()
        try await storageService.saveTextSource(textSource)
        
        let wordTests = createTestWordTests(sourceId: textSource.id)
        try await storageService.saveWordTests(wordTests)
        
        let progress = UserProgress(wordId: wordTests[0].id, isMemorized: true)
        try await storageService.saveProgress(progress)
        
        // When
        try await storageService.clearAllData()
        
        // Then
        let sources = try await storageService.fetchTextSources()
        let tests = try await storageService.fetchWordTests(for: textSource.id, difficulty: nil)
        let unsyncedProgress = try await storageService.fetchUnsyncedProgress()
        
        XCTAssertTrue(sources.isEmpty)
        XCTAssertTrue(tests.isEmpty)
        XCTAssertTrue(unsyncedProgress.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testFetchNonExistentProgress() async throws {
        // Given
        let nonExistentWordId = UUID()
        
        // When
        let progress = try await storageService.fetchProgress(for: nonExistentWordId)
        
        // Then
        XCTAssertNil(progress)
    }
    
    func testFetchWordTestsForNonExistentSource() async throws {
        // Given
        let nonExistentSourceId = UUID()
        
        // When
        let wordTests = try await storageService.fetchWordTests(for: nonExistentSourceId, difficulty: nil)
        
        // Then
        XCTAssertTrue(wordTests.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTextSource(title: String = "Test Source") -> TextSource {
        return TextSource(
            title: title,
            content: "This is a test content with some words to learn.",
            wordCount: 10
        )
    }
    
    private func createTestWordTests(sourceId: UUID) -> [WordTest] {
        return [
            WordTest(
                word: "test",
                sentence: "This is a test sentence.",
                meaning: "A procedure to check something",
                difficultyLevel: .beginner,
                sourceId: sourceId
            ),
            WordTest(
                word: "content",
                sentence: "The content is very interesting.",
                meaning: "Information or material",
                difficultyLevel: .intermediate,
                sourceId: sourceId
            ),
            WordTest(
                word: "procedure",
                sentence: "Follow the procedure carefully.",
                meaning: "A series of actions",
                difficultyLevel: .advanced,
                sourceId: sourceId
            )
        ]
    }
}
import XCTest
import CoreData
@testable import VocabularyApp

class ProgressTrackingServiceTests: XCTestCase {
    var progressTrackingService: ProgressTrackingService!
    var mockUserProgressRepository: MockUserProgressRepository!
    var mockWordTestRepository: MockWordTestRepository!
    
    override func setUp() {
        super.setUp()
        mockUserProgressRepository = MockUserProgressRepository()
        mockWordTestRepository = MockWordTestRepository()
        progressTrackingService = ProgressTrackingService(
            userProgressRepository: mockUserProgressRepository,
            wordTestRepository: mockWordTestRepository
        )
    }
    
    override func tearDown() {
        progressTrackingService = nil
        mockUserProgressRepository = nil
        mockWordTestRepository = nil
        super.tearDown()
    }
    
    // MARK: - Session Management Tests
    
    func testStartSession() {
        let wordIds = [UUID(), UUID(), UUID()]
        
        progressTrackingService.startSession(with: wordIds)
        
        XCTAssertEqual(progressTrackingService.getCurrentWord(), wordIds[0])
        XCTAssertTrue(progressTrackingService.hasNextWord())
        XCTAssertFalse(progressTrackingService.isSessionComplete())
    }
    
    func testEndSession() {
        let wordIds = [UUID(), UUID()]
        progressTrackingService.startSession(with: wordIds)
        
        progressTrackingService.endSession()
        
        XCTAssertNil(progressTrackingService.getCurrentWord())
        XCTAssertFalse(progressTrackingService.hasNextWord())
        XCTAssertTrue(progressTrackingService.isSessionComplete())
    }
    
    func testSessionProgression() {
        let wordIds = [UUID(), UUID(), UUID()]
        progressTrackingService.startSession(with: wordIds)
        
        // Initially at first word
        XCTAssertEqual(progressTrackingService.getCurrentWord(), wordIds[0])
        
        // Record response for first word
        Task {
            await progressTrackingService.recordResponse(wordId: wordIds[0], isMemorized: true)
        }
        
        // Should advance to second word
        XCTAssertEqual(progressTrackingService.getCurrentWord(), wordIds[1])
        XCTAssertTrue(progressTrackingService.hasNextWord())
        XCTAssertFalse(progressTrackingService.isSessionComplete())
    }
    
    func testSessionCompletion() async {
        let wordIds = [UUID(), UUID()]
        progressTrackingService.startSession(with: wordIds)
        
        // Complete all words
        await progressTrackingService.recordResponse(wordId: wordIds[0], isMemorized: true)
        await progressTrackingService.recordResponse(wordId: wordIds[1], isMemorized: false)
        
        XCTAssertFalse(progressTrackingService.hasNextWord())
        XCTAssertTrue(progressTrackingService.isSessionComplete())
    }
    
    // MARK: - Progress Recording Tests
    
    func testRecordResponse() async {
        let wordId = UUID()
        mockUserProgressRepository.shouldSucceed = true
        
        await progressTrackingService.recordResponse(wordId: wordId, isMemorized: true)
        
        XCTAssertTrue(mockUserProgressRepository.recordProgressCalled)
        XCTAssertEqual(mockUserProgressRepository.lastRecordedWordId, wordId)
        XCTAssertEqual(mockUserProgressRepository.lastRecordedIsMemorized, true)
    }
    
    func testRecordResponseFailure() async {
        let wordId = UUID()
        mockUserProgressRepository.shouldSucceed = false
        
        await progressTrackingService.recordResponse(wordId: wordId, isMemorized: true)
        
        // Should handle error gracefully without crashing
        XCTAssertTrue(mockUserProgressRepository.recordProgressCalled)
    }
    
    // MARK: - Session Progress Tests
    
    func testGetSessionProgressEmpty() async {
        let progress = await progressTrackingService.getSessionProgress()
        
        XCTAssertEqual(progress.currentWordIndex, 0)
        XCTAssertEqual(progress.totalWords, 0)
        XCTAssertEqual(progress.memorizedCount, 0)
        XCTAssertEqual(progress.notMemorizedCount, 0)
        XCTAssertEqual(progress.completionPercentage, 0.0)
    }
    
    func testGetSessionProgressWithResponses() async {
        let wordIds = [UUID(), UUID(), UUID()]
        progressTrackingService.startSession(with: wordIds)
        
        // Record some responses
        await progressTrackingService.recordResponse(wordId: wordIds[0], isMemorized: true)
        await progressTrackingService.recordResponse(wordId: wordIds[1], isMemorized: false)
        
        let progress = await progressTrackingService.getSessionProgress()
        
        XCTAssertEqual(progress.currentWordIndex, 2)
        XCTAssertEqual(progress.totalWords, 3)
        XCTAssertEqual(progress.memorizedCount, 1)
        XCTAssertEqual(progress.notMemorizedCount, 1)
        XCTAssertEqual(progress.completionPercentage, 66.66666666666667, accuracy: 0.01)
    }
    
    // MARK: - Overall Progress Tests
    
    func testGetOverallProgressSuccess() async {
        mockUserProgressRepository.shouldSucceed = true
        mockUserProgressRepository.mockStatistics = ProgressStatistics(
            totalWords: 100,
            memorizedWords: 75,
            notMemorizedWords: 25,
            totalReviews: 150
        )
        mockWordTestRepository.mockWordTests = [
            createMockWordTest(sourceId: UUID()),
            createMockWordTest(sourceId: UUID())
        ]
        
        let progress = await progressTrackingService.getOverallProgress()
        
        XCTAssertEqual(progress.totalWordsStudied, 100)
        XCTAssertEqual(progress.totalWordsMemorized, 75)
        XCTAssertEqual(progress.totalSources, 2)
        XCTAssertEqual(progress.memorizationRate, 75.0)
    }
    
    func testGetOverallProgressFailure() async {
        mockUserProgressRepository.shouldSucceed = false
        
        let progress = await progressTrackingService.getOverallProgress()
        
        XCTAssertEqual(progress.totalWordsStudied, 0)
        XCTAssertEqual(progress.totalWordsMemorized, 0)
        XCTAssertEqual(progress.totalSources, 0)
        XCTAssertEqual(progress.averageSessionScore, 0.0)
    }
    
    // MARK: - Progress Retrieval Tests
    
    func testGetProgressForWord() async {
        let wordId = UUID()
        let expectedProgress = UserProgress(wordId: wordId, isMemorized: true, reviewCount: 3)
        mockUserProgressRepository.mockUserProgress = expectedProgress
        mockUserProgressRepository.shouldSucceed = true
        
        let progress = await progressTrackingService.getProgressForWord(wordId)
        
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.wordId, wordId)
        XCTAssertEqual(progress?.isMemorized, true)
        XCTAssertEqual(progress?.reviewCount, 3)
    }
    
    func testGetProgressForWordFailure() async {
        let wordId = UUID()
        mockUserProgressRepository.shouldSucceed = false
        
        let progress = await progressTrackingService.getProgressForWord(wordId)
        
        XCTAssertNil(progress)
    }
    
    func testGetMemorizedWords() async {
        let memorizedProgress = [
            UserProgress(wordId: UUID(), isMemorized: true),
            UserProgress(wordId: UUID(), isMemorized: true)
        ]
        mockUserProgressRepository.mockMemorizedProgress = memorizedProgress
        mockUserProgressRepository.shouldSucceed = true
        
        let result = await progressTrackingService.getMemorizedWords()
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.isMemorized })
    }
    
    func testGetNotMemorizedWords() async {
        let notMemorizedProgress = [
            UserProgress(wordId: UUID(), isMemorized: false),
            UserProgress(wordId: UUID(), isMemorized: false)
        ]
        mockUserProgressRepository.mockNotMemorizedProgress = notMemorizedProgress
        mockUserProgressRepository.shouldSucceed = true
        
        let result = await progressTrackingService.getNotMemorizedWords()
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { !$0.isMemorized })
    }
    
    // MARK: - Source Progress Tests
    
    func testGetProgressBySource() async {
        let sourceId = UUID()
        let wordTests = [
            createMockWordTest(sourceId: sourceId),
            createMockWordTest(sourceId: sourceId),
            createMockWordTest(sourceId: sourceId)
        ]
        
        mockWordTestRepository.mockWordTestsBySource[sourceId] = wordTests
        mockUserProgressRepository.mockProgressByWord = [
            wordTests[0].id: UserProgress(wordId: wordTests[0].id, isMemorized: true, reviewCount: 2),
            wordTests[1].id: UserProgress(wordId: wordTests[1].id, isMemorized: false, reviewCount: 1),
            wordTests[2].id: UserProgress(wordId: wordTests[2].id, isMemorized: true, reviewCount: 3)
        ]
        mockUserProgressRepository.shouldSucceed = true
        mockWordTestRepository.shouldSucceed = true
        
        let progress = await progressTrackingService.getProgressBySource(sourceId)
        
        XCTAssertEqual(progress.sourceId, sourceId)
        XCTAssertEqual(progress.totalWords, 3)
        XCTAssertEqual(progress.memorizedWords, 2)
        XCTAssertEqual(progress.notMemorizedWords, 1)
        XCTAssertEqual(progress.totalReviews, 6)
        XCTAssertEqual(progress.completionPercentage, 100.0)
        XCTAssertEqual(progress.memorizationRate, 66.66666666666667, accuracy: 0.01)
        XCTAssertEqual(progress.averageReviewsPerWord, 2.0)
    }
    
    // MARK: - Difficulty Progress Tests
    
    func testGetProgressByDifficulty() async {
        let difficulty = DifficultyLevel.intermediate
        let wordTests = [
            createMockWordTest(difficulty: difficulty),
            createMockWordTest(difficulty: difficulty)
        ]
        
        mockWordTestRepository.mockWordTestsByDifficulty[difficulty] = wordTests
        mockUserProgressRepository.mockProgressByWord = [
            wordTests[0].id: UserProgress(wordId: wordTests[0].id, isMemorized: true, reviewCount: 1),
            wordTests[1].id: UserProgress(wordId: wordTests[1].id, isMemorized: false, reviewCount: 2)
        ]
        mockUserProgressRepository.shouldSucceed = true
        mockWordTestRepository.shouldSucceed = true
        
        let progress = await progressTrackingService.getProgressByDifficulty(difficulty)
        
        XCTAssertEqual(progress.difficulty, difficulty)
        XCTAssertEqual(progress.totalWords, 2)
        XCTAssertEqual(progress.memorizedWords, 1)
        XCTAssertEqual(progress.notMemorizedWords, 1)
        XCTAssertEqual(progress.totalReviews, 3)
        XCTAssertEqual(progress.completionPercentage, 100.0)
        XCTAssertEqual(progress.memorizationRate, 50.0)
        XCTAssertEqual(progress.averageReviewsPerWord, 1.5)
    }
    
    // MARK: - Helper Methods
    
    private func createMockWordTest(sourceId: UUID = UUID(), difficulty: DifficultyLevel = .beginner) -> WordTest {
        return WordTest(
            id: UUID(),
            word: "test",
            sentence: "This is a test sentence.",
            meaning: "A test word",
            difficultyLevel: difficulty,
            sourceId: sourceId
        )
    }
}

// MARK: - Mock Classes

class MockUserProgressRepository: UserProgressRepository {
    var shouldSucceed = true
    var recordProgressCalled = false
    var lastRecordedWordId: UUID?
    var lastRecordedIsMemorized: Bool?
    
    var mockUserProgress: UserProgress?
    var mockStatistics = ProgressStatistics(totalWords: 0, memorizedWords: 0, notMemorizedWords: 0, totalReviews: 0)
    var mockMemorizedProgress: [UserProgress] = []
    var mockNotMemorizedProgress: [UserProgress] = []
    var mockProgressByWord: [UUID: UserProgress] = [:]
    
    override func recordProgress(_ wordId: UUID, isMemorized: Bool) async throws -> UserProgress {
        recordProgressCalled = true
        lastRecordedWordId = wordId
        lastRecordedIsMemorized = isMemorized
        
        if !shouldSucceed {
            throw PersistenceError.failedToSave(NSError(domain: "TestError", code: 1, userInfo: nil))
        }
        
        let progress = UserProgress(wordId: wordId, isMemorized: isMemorized)
        mockProgressByWord[wordId] = progress
        return progress
    }
    
    override func fetchByWord(_ wordId: UUID) async throws -> UserProgress? {
        if !shouldSucceed {
            throw PersistenceError.entityNotFound
        }
        return mockProgressByWord[wordId] ?? mockUserProgress
    }
    
    override func getStatistics() async throws -> ProgressStatistics {
        if !shouldSucceed {
            throw PersistenceError.entityNotFound
        }
        return mockStatistics
    }
    
    override func fetchMemorized() async throws -> [UserProgress] {
        if !shouldSucceed {
            throw PersistenceError.entityNotFound
        }
        return mockMemorizedProgress
    }
    
    override func fetchNotMemorized() async throws -> [UserProgress] {
        if !shouldSucceed {
            throw PersistenceError.entityNotFound
        }
        return mockNotMemorizedProgress
    }
    
    override func fetchAll() async throws -> [UserProgress] {
        if !shouldSucceed {
            throw PersistenceError.entityNotFound
        }
        return mockMemorizedProgress + mockNotMemorizedProgress
    }
}

class MockWordTestRepository: WordTestRepository {
    var shouldSucceed = true
    var mockWordTests: [WordTest] = []
    var mockWordTestsBySource: [UUID: [WordTest]] = [:]
    var mockWordTestsByDifficulty: [DifficultyLevel: [WordTest]] = [:]
    
    override func fetchAll() async throws -> [WordTest] {
        if !shouldSucceed {
            throw PersistenceError.entityNotFound
        }
        return mockWordTests
    }
    
    override func fetchBySource(_ sourceId: UUID) async throws -> [WordTest] {
        if !shouldSucceed {
            throw PersistenceError.entityNotFound
        }
        return mockWordTestsBySource[sourceId] ?? []
    }
    
    override func fetchByDifficulty(_ difficulty: DifficultyLevel) async throws -> [WordTest] {
        if !shouldSucceed {
            throw PersistenceError.entityNotFound
        }
        return mockWordTestsByDifficulty[difficulty] ?? []
    }
}
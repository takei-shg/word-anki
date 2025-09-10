import XCTest
import CoreData
@testable import VocabularyApp

class ProgressTrackingServiceIntegrationTests: XCTestCase {
    var progressTrackingService: ProgressTrackingService!
    var persistenceController: PersistenceController!
    var userProgressRepository: UserProgressRepository!
    var wordTestRepository: WordTestRepository!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        persistenceController = PersistenceController.inMemory
        userProgressRepository = UserProgressRepository(persistenceController: persistenceController)
        wordTestRepository = WordTestRepository(persistenceController: persistenceController)
        progressTrackingService = ProgressTrackingService(
            userProgressRepository: userProgressRepository,
            wordTestRepository: wordTestRepository
        )
    }
    
    override func tearDown() {
        progressTrackingService = nil
        userProgressRepository = nil
        wordTestRepository = nil
        persistenceController = nil
        super.tearDown()
    }
    
    func testCompleteWordTestSession() async throws {
        // Create test data
        let sourceId = UUID()
        let wordTests = [
            WordTest(id: UUID(), word: "hello", sentence: "Hello world!", meaning: "A greeting", difficultyLevel: .beginner, sourceId: sourceId),
            WordTest(id: UUID(), word: "world", sentence: "Hello world!", meaning: "The earth", difficultyLevel: .beginner, sourceId: sourceId),
            WordTest(id: UUID(), word: "test", sentence: "This is a test.", meaning: "An examination", difficultyLevel: .intermediate, sourceId: sourceId)
        ]
        
        // Save word tests to repository
        for wordTest in wordTests {
            _ = try await wordTestRepository.create(wordTest)
        }
        
        // Start a session with the word IDs
        let wordIds = wordTests.map { $0.id }
        progressTrackingService.startSession(with: wordIds)
        
        // Verify initial session state
        var sessionProgress = await progressTrackingService.getSessionProgress()
        XCTAssertEqual(sessionProgress.currentWordIndex, 0)
        XCTAssertEqual(sessionProgress.totalWords, 3)
        XCTAssertEqual(sessionProgress.memorizedCount, 0)
        XCTAssertEqual(sessionProgress.notMemorizedCount, 0)
        
        // Record responses for each word
        await progressTrackingService.recordResponse(wordId: wordIds[0], isMemorized: true)
        await progressTrackingService.recordResponse(wordId: wordIds[1], isMemorized: false)
        await progressTrackingService.recordResponse(wordId: wordIds[2], isMemorized: true)
        
        // Verify session progress after responses
        sessionProgress = await progressTrackingService.getSessionProgress()
        XCTAssertEqual(sessionProgress.currentWordIndex, 3)
        XCTAssertEqual(sessionProgress.totalWords, 3)
        XCTAssertEqual(sessionProgress.memorizedCount, 2)
        XCTAssertEqual(sessionProgress.notMemorizedCount, 1)
        XCTAssertEqual(sessionProgress.completionPercentage, 100.0)
        
        // Verify session is complete
        XCTAssertTrue(progressTrackingService.isSessionComplete())
        XCTAssertFalse(progressTrackingService.hasNextWord())
        
        // Verify overall progress
        let overallProgress = await progressTrackingService.getOverallProgress()
        XCTAssertEqual(overallProgress.totalWordsStudied, 3)
        XCTAssertEqual(overallProgress.totalWordsMemorized, 2)
        XCTAssertEqual(overallProgress.memorizationRate, 66.66666666666667, accuracy: 0.01)
        
        // Verify individual word progress
        for (index, wordId) in wordIds.enumerated() {
            let wordProgress = await progressTrackingService.getProgressForWord(wordId)
            XCTAssertNotNil(wordProgress)
            XCTAssertEqual(wordProgress?.wordId, wordId)
            XCTAssertEqual(wordProgress?.reviewCount, 1)
            
            if index == 1 { // Second word was marked as not memorized
                XCTAssertFalse(wordProgress?.isMemorized ?? true)
            } else {
                XCTAssertTrue(wordProgress?.isMemorized ?? false)
            }
        }
        
        // Test source-specific progress
        let sourceProgress = await progressTrackingService.getProgressBySource(sourceId)
        XCTAssertEqual(sourceProgress.sourceId, sourceId)
        XCTAssertEqual(sourceProgress.totalWords, 3)
        XCTAssertEqual(sourceProgress.memorizedWords, 2)
        XCTAssertEqual(sourceProgress.notMemorizedWords, 1)
        XCTAssertEqual(sourceProgress.totalReviews, 3)
        XCTAssertEqual(sourceProgress.completionPercentage, 100.0)
        XCTAssertEqual(sourceProgress.memorizationRate, 66.66666666666667, accuracy: 0.01)
        
        // Test difficulty-specific progress
        let beginnerProgress = await progressTrackingService.getProgressByDifficulty(.beginner)
        XCTAssertEqual(beginnerProgress.difficulty, .beginner)
        XCTAssertEqual(beginnerProgress.totalWords, 2)
        XCTAssertEqual(beginnerProgress.memorizedWords, 1)
        XCTAssertEqual(beginnerProgress.notMemorizedWords, 1)
        
        let intermediateProgress = await progressTrackingService.getProgressByDifficulty(.intermediate)
        XCTAssertEqual(intermediateProgress.difficulty, .intermediate)
        XCTAssertEqual(intermediateProgress.totalWords, 1)
        XCTAssertEqual(intermediateProgress.memorizedWords, 1)
        XCTAssertEqual(intermediateProgress.notMemorizedWords, 0)
    }
    
    func testSessionResumption() async throws {
        // Create test data
        let wordIds = [UUID(), UUID(), UUID()]
        
        // Start session and complete first word
        progressTrackingService.startSession(with: wordIds)
        await progressTrackingService.recordResponse(wordId: wordIds[0], isMemorized: true)
        
        // Verify we're at the second word
        XCTAssertEqual(progressTrackingService.getCurrentWord(), wordIds[1])
        XCTAssertTrue(progressTrackingService.hasNextWord())
        XCTAssertFalse(progressTrackingService.isSessionComplete())
        
        // Simulate app restart by creating new service instance
        let newProgressTrackingService = ProgressTrackingService(
            userProgressRepository: userProgressRepository,
            wordTestRepository: wordTestRepository
        )
        
        // Resume session with remaining words
        let remainingWords = Array(wordIds[1...])
        newProgressTrackingService.startSession(with: remainingWords)
        
        // Complete remaining words
        await newProgressTrackingService.recordResponse(wordId: wordIds[1], isMemorized: false)
        await newProgressTrackingService.recordResponse(wordId: wordIds[2], isMemorized: true)
        
        // Verify final progress
        let finalProgress = await newProgressTrackingService.getSessionProgress()
        XCTAssertEqual(finalProgress.memorizedCount, 1)
        XCTAssertEqual(finalProgress.notMemorizedCount, 1)
        XCTAssertTrue(newProgressTrackingService.isSessionComplete())
    }
    
    func testProgressPersistence() async throws {
        let wordId = UUID()
        
        // Record initial response
        await progressTrackingService.recordResponse(wordId: wordId, isMemorized: false)
        
        // Verify progress was saved
        var progress = await progressTrackingService.getProgressForWord(wordId)
        XCTAssertNotNil(progress)
        XCTAssertFalse(progress?.isMemorized ?? true)
        XCTAssertEqual(progress?.reviewCount, 1)
        
        // Record another response for the same word
        await progressTrackingService.recordResponse(wordId: wordId, isMemorized: true)
        
        // Verify progress was updated
        progress = await progressTrackingService.getProgressForWord(wordId)
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress?.isMemorized ?? false)
        XCTAssertEqual(progress?.reviewCount, 2)
    }
}
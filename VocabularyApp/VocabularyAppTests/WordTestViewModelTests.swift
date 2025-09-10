import XCTest
@testable import VocabularyApp

@MainActor
final class WordTestViewModelTests: XCTestCase {
    
    var viewModel: WordTestViewModel!
    var mockStorageService: MockStorageService!
    var mockProgressService: MockProgressTrackingService!
    
    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        mockProgressService = MockProgressTrackingService()
        
        viewModel = WordTestViewModel(
            storageService: mockStorageService,
            progressService: mockProgressService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockStorageService = nil
        mockProgressService = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestWords() -> [WordTest] {
        return [
            WordTest(word: "apple", sentence: "I ate an apple", meaning: "A fruit", difficultyLevel: .beginner, sourceId: UUID()),
            WordTest(word: "beautiful", sentence: "The sunset is beautiful", meaning: "Attractive", difficultyLevel: .intermediate, sourceId: UUID()),
            WordTest(word: "magnificent", sentence: "The view was magnificent", meaning: "Impressive", difficultyLevel: .advanced, sourceId: UUID())
        ]
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNil(viewModel.currentWord)
        XCTAssertTrue(viewModel.wordTests.isEmpty)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.sessionState, .notStarted)
        XCTAssertEqual(viewModel.wordDisplayState, .showingWord)
        XCTAssertNil(viewModel.selectedDifficulty)
        XCTAssertEqual(viewModel.memorizedCount, 0)
        XCTAssertEqual(viewModel.notMemorizedCount, 0)
    }
    
    // MARK: - Session Management Tests
    
    func testStartSessionSuccess() async {
        // Given
        let sourceId = UUID()
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        
        // When
        await viewModel.startSession(sourceId: sourceId, difficulty: .beginner)
        
        // Then
        XCTAssertEqual(viewModel.selectedSourceId, sourceId)
        XCTAssertEqual(viewModel.selectedDifficulty, .beginner)
        XCTAssertEqual(viewModel.sessionState, .ready)
        XCTAssertNotNil(viewModel.currentWord)
        XCTAssertFalse(viewModel.wordTests.isEmpty)
    }
    
    func testStartSessionWithNoWords() async {
        // Given
        let sourceId = UUID()
        mockStorageService.wordTests = []
        
        // When
        await viewModel.startSession(sourceId: sourceId, difficulty: .beginner)
        
        // Then
        XCTAssertTrue(viewModel.hasError)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testStartSessionFailure() async {
        // Given
        let sourceId = UUID()
        mockStorageService.shouldThrowError = true
        mockStorageService.error = StorageError.fetchFailed
        
        // When
        await viewModel.startSession(sourceId: sourceId, difficulty: .beginner)
        
        // Then
        XCTAssertTrue(viewModel.hasError)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testResumeSession() async {
        // Given
        let sourceId = UUID()
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        await viewModel.startSession(sourceId: sourceId, difficulty: nil)
        
        // When
        await viewModel.resumeSession()
        
        // Then
        XCTAssertTrue(viewModel.isSessionActive)
        XCTAssertNotNil(viewModel.currentWord)
    }
    
    func testRestartSession() async {
        // Given
        let sourceId = UUID()
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        await viewModel.startSession(sourceId: sourceId, difficulty: nil)
        viewModel.currentIndex = 2
        
        // When
        await viewModel.restartSession()
        
        // Then
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.memorizedCount, 0)
        XCTAssertEqual(viewModel.notMemorizedCount, 0)
    }
    
    func testEndSession() {
        // Given
        viewModel.sessionState = .inProgress
        viewModel.currentIndex = 1
        
        // When
        viewModel.endSession()
        
        // Then
        XCTAssertEqual(viewModel.sessionState, .notStarted)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertNil(viewModel.currentWord)
    }
    
    // MARK: - Word Navigation Tests
    
    func testShowMeaning() {
        // Given
        viewModel.wordDisplayState = .showingWord
        
        // When
        viewModel.showMeaning()
        
        // Then
        XCTAssertEqual(viewModel.wordDisplayState, .showingMeaning)
    }
    
    func testShowMeaningWhenAlreadyShowing() {
        // Given
        viewModel.wordDisplayState = .showingMeaning
        
        // When
        viewModel.showMeaning()
        
        // Then
        XCTAssertEqual(viewModel.wordDisplayState, .showingMeaning)
    }
    
    func testRecordResponseMemorized() async {
        // Given
        let sourceId = UUID()
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        await viewModel.startSession(sourceId: sourceId, difficulty: nil)
        viewModel.showMeaning()
        
        // When
        await viewModel.recordResponse(isMemorized: true)
        
        // Then
        XCTAssertEqual(viewModel.memorizedCount, 1)
        XCTAssertEqual(viewModel.notMemorizedCount, 0)
        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertEqual(mockProgressService.recordResponseCallCount, 1)
    }
    
    func testRecordResponseNotMemorized() async {
        // Given
        let sourceId = UUID()
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        await viewModel.startSession(sourceId: sourceId, difficulty: nil)
        viewModel.showMeaning()
        
        // When
        await viewModel.recordResponse(isMemorized: false)
        
        // Then
        XCTAssertEqual(viewModel.memorizedCount, 0)
        XCTAssertEqual(viewModel.notMemorizedCount, 1)
        XCTAssertEqual(viewModel.currentIndex, 1)
    }
    
    func testRecordResponseCompletesSession() async {
        // Given
        let sourceId = UUID()
        let testWords = [createTestWords()[0]] // Only one word
        mockStorageService.wordTests = testWords
        await viewModel.startSession(sourceId: sourceId, difficulty: nil)
        viewModel.showMeaning()
        
        // When
        await viewModel.recordResponse(isMemorized: true)
        
        // Then
        XCTAssertTrue(viewModel.isSessionCompleted)
        XCTAssertTrue(viewModel.showingSessionComplete)
    }
    
    func testGoToPreviousWord() {
        // Given
        let sourceId = UUID()
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        viewModel.wordTests = testWords
        viewModel.currentIndex = 2
        viewModel.memorizedCount = 2
        
        // When
        viewModel.goToPreviousWord()
        
        // Then
        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertEqual(viewModel.memorizedCount, 1)
    }
    
    func testGoToPreviousWordAtBeginning() {
        // Given
        viewModel.currentIndex = 0
        
        // When
        viewModel.goToPreviousWord()
        
        // Then
        XCTAssertEqual(viewModel.currentIndex, 0)
    }
    
    func testSkipCurrentWord() async {
        // Given
        let sourceId = UUID()
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        await viewModel.startSession(sourceId: sourceId, difficulty: nil)
        let initialIndex = viewModel.currentIndex
        
        // When
        await viewModel.skipCurrentWord()
        
        // Then
        XCTAssertEqual(viewModel.currentIndex, initialIndex + 1)
    }
    
    // MARK: - Difficulty Management Tests
    
    func testSelectDifficulty() {
        // When
        viewModel.selectDifficulty(.intermediate)
        
        // Then
        XCTAssertEqual(viewModel.selectedDifficulty, .intermediate)
    }
    
    func testClearDifficultySelection() {
        // Given
        viewModel.selectDifficulty(.advanced)
        
        // When
        viewModel.clearDifficultySelection()
        
        // Then
        XCTAssertNil(viewModel.selectedDifficulty)
    }
    
    func testLoadAvailableDifficulties() async {
        // Given
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        
        // When
        let difficulties = await viewModel.loadAvailableDifficulties(for: UUID())
        
        // Then
        XCTAssertEqual(difficulties.count, 3)
        XCTAssertTrue(difficulties.contains(.beginner))
        XCTAssertTrue(difficulties.contains(.intermediate))
        XCTAssertTrue(difficulties.contains(.advanced))
    }
    
    func testGetWordCount() async {
        // Given
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords
        
        // When
        let count = await viewModel.getWordCount(for: UUID(), difficulty: nil)
        
        // Then
        XCTAssertEqual(count, 3)
    }
    
    func testGetWordCountForSpecificDifficulty() async {
        // Given
        let testWords = createTestWords()
        mockStorageService.wordTests = testWords.filter { $0.difficultyLevel == .beginner }
        
        // When
        let count = await viewModel.getWordCount(for: UUID(), difficulty: .beginner)
        
        // Then
        XCTAssertEqual(count, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        // Given
        viewModel.errorMessage = "Test error"
        viewModel.sessionState = .error("Test error")
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.sessionState, .notStarted)
    }
    
    func testRetryLoading() async {
        // Given
        let sourceId = UUID()
        viewModel.selectedSourceId = sourceId
        viewModel.selectedDifficulty = .beginner
        mockStorageService.wordTests = createTestWords()
        
        // When
        await viewModel.retryLoading()
        
        // Then
        XCTAssertEqual(viewModel.sessionState, .ready)
        XCTAssertFalse(viewModel.wordTests.isEmpty)
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsLoading() {
        // Given - not loading
        viewModel.sessionState = .ready
        XCTAssertFalse(viewModel.isLoading)
        
        // When - loading
        viewModel.sessionState = .loading
        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testHasError() {
        // Given - no error
        viewModel.sessionState = .ready
        XCTAssertFalse(viewModel.hasError)
        
        // When - has error
        viewModel.sessionState = .error("Test error")
        XCTAssertTrue(viewModel.hasError)
    }
    
    func testIsSessionActive() {
        // Test different states
        viewModel.sessionState = .notStarted
        XCTAssertFalse(viewModel.isSessionActive)
        
        viewModel.sessionState = .ready
        XCTAssertTrue(viewModel.isSessionActive)
        
        viewModel.sessionState = .inProgress
        XCTAssertTrue(viewModel.isSessionActive)
        
        viewModel.sessionState = .completed
        XCTAssertFalse(viewModel.isSessionActive)
    }
    
    func testIsSessionCompleted() {
        // Given - not completed
        viewModel.sessionState = .inProgress
        XCTAssertFalse(viewModel.isSessionCompleted)
        
        // When - completed
        viewModel.sessionState = .completed
        XCTAssertTrue(viewModel.isSessionCompleted)
    }
    
    func testProgressPercentage() {
        // Given
        viewModel.wordTests = createTestWords()
        viewModel.currentIndex = 1
        
        // When
        let percentage = viewModel.progressPercentage
        
        // Then
        XCTAssertEqual(percentage, 33.333333333333336, accuracy: 0.1)
    }
    
    func testProgressPercentageWithNoWords() {
        // Given
        viewModel.wordTests = []
        viewModel.currentIndex = 0
        
        // When
        let percentage = viewModel.progressPercentage
        
        // Then
        XCTAssertEqual(percentage, 0)
    }
    
    func testRemainingWords() {
        // Given
        viewModel.wordTests = createTestWords()
        viewModel.currentIndex = 1
        
        // When
        let remaining = viewModel.remainingWords
        
        // Then
        XCTAssertEqual(remaining, 2)
    }
    
    func testCanShowMeaning() {
        // Given
        viewModel.currentWord = createTestWords()[0]
        viewModel.wordDisplayState = .showingWord
        
        // Then
        XCTAssertTrue(viewModel.canShowMeaning)
        
        // When
        viewModel.wordDisplayState = .showingMeaning
        XCTAssertFalse(viewModel.canShowMeaning)
    }
    
    func testCanRecordResponse() {
        // Given
        viewModel.currentWord = createTestWords()[0]
        viewModel.wordDisplayState = .showingMeaning
        
        // Then
        XCTAssertTrue(viewModel.canRecordResponse)
        
        // When
        viewModel.wordDisplayState = .showingWord
        XCTAssertFalse(viewModel.canRecordResponse)
    }
    
    func testSessionSummary() {
        // Given
        viewModel.memorizedCount = 3
        viewModel.notMemorizedCount = 2
        
        // When
        let summary = viewModel.sessionSummary
        
        // Then
        XCTAssertEqual(summary, "3/5 words memorized (60%)")
    }
    
    func testSessionSummaryWithNoWords() {
        // Given
        viewModel.memorizedCount = 0
        viewModel.notMemorizedCount = 0
        
        // When
        let summary = viewModel.sessionSummary
        
        // Then
        XCTAssertEqual(summary, "No words completed")
    }
    
    func testFormatSessionTime() {
        // This test is challenging because sessionDuration depends on sessionStartTime
        // We'll test the format method indirectly
        let formattedTime = viewModel.formatSessionTime()
        XCTAssertTrue(formattedTime.contains(":"))
        XCTAssertEqual(formattedTime.count, 5) // Format: MM:SS
    }
    
    // MARK: - Progress Integration Tests
    
    func testGetOverallProgress() async {
        // Given
        let expectedProgress = OverallProgress(
            totalWordsStudied: 10,
            totalWordsMemorized: 7,
            totalSources: 2,
            averageSessionScore: 0.7
        )
        mockProgressService.overallProgress = expectedProgress
        
        // When
        let progress = await viewModel.getOverallProgress()
        
        // Then
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.totalWordsStudied, 10)
        XCTAssertEqual(progress?.totalWordsMemorized, 7)
    }
    
    func testGetWordProgress() async {
        // Given
        let word = createTestWords()[0]
        let expectedProgress = UserProgress(wordId: word.id, isMemorized: true, reviewCount: 3, lastReviewed: Date())
        mockStorageService.userProgress = expectedProgress
        
        // When
        let progress = await viewModel.getWordProgress(for: word)
        
        // Then
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.wordId, word.id)
        XCTAssertTrue(progress?.isMemorized ?? false)
    }
}

// MARK: - Enum Tests

final class WordTestSessionStateTests: XCTestCase {
    
    func testSessionStateEquality() {
        XCTAssertEqual(WordTestSessionState.notStarted, WordTestSessionState.notStarted)
        XCTAssertEqual(WordTestSessionState.loading, WordTestSessionState.loading)
        XCTAssertEqual(WordTestSessionState.ready, WordTestSessionState.ready)
        XCTAssertEqual(WordTestSessionState.inProgress, WordTestSessionState.inProgress)
        XCTAssertEqual(WordTestSessionState.completed, WordTestSessionState.completed)
        
        // Note: .error cases with different messages are not equal
        XCTAssertNotEqual(WordTestSessionState.error("Error 1"), WordTestSessionState.error("Error 2"))
    }
}

final class WordDisplayStateTests: XCTestCase {
    
    func testDisplayStateEquality() {
        XCTAssertEqual(WordDisplayState.showingWord, WordDisplayState.showingWord)
        XCTAssertEqual(WordDisplayState.showingMeaning, WordDisplayState.showingMeaning)
        XCTAssertEqual(WordDisplayState.awaitingResponse, WordDisplayState.awaitingResponse)
    }
}
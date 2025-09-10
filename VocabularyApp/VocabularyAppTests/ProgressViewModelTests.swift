import XCTest
@testable import VocabularyApp

@MainActor
final class ProgressViewModelTests: XCTestCase {
    
    var viewModel: ProgressViewModel!
    var mockProgressService: MockProgressTrackingService!
    var mockStorageService: MockStorageService!
    
    override func setUp() {
        super.setUp()
        mockProgressService = MockProgressTrackingService()
        mockStorageService = MockStorageService()
        
        viewModel = ProgressViewModel(
            progressService: mockProgressService,
            storageService: mockStorageService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockProgressService = nil
        mockStorageService = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestTextSources() -> [TextSource] {
        return [
            TextSource(id: UUID(), title: "Source 1", content: "Content 1", wordCount: 10),
            TextSource(id: UUID(), title: "Source 2", content: "Content 2", wordCount: 15)
        ]
    }
    
    private func createTestWordTests(sourceId: UUID) -> [WordTest] {
        return [
            WordTest(word: "apple", sentence: "I ate an apple", meaning: "A fruit", difficultyLevel: .beginner, sourceId: sourceId),
            WordTest(word: "beautiful", sentence: "The sunset is beautiful", meaning: "Attractive", difficultyLevel: .intermediate, sourceId: sourceId),
            WordTest(word: "magnificent", sentence: "The view was magnificent", meaning: "Impressive", difficultyLevel: .advanced, sourceId: sourceId)
        ]
    }
    
    private func createTestUserProgress(wordId: UUID, isMemorized: Bool = true) -> UserProgress {
        return UserProgress(wordId: wordId, isMemorized: isMemorized, reviewCount: 1, lastReviewed: Date())
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNil(viewModel.sessionProgress)
        XCTAssertNil(viewModel.overallProgress)
        XCTAssertTrue(viewModel.sourceProgresses.isEmpty)
        XCTAssertTrue(viewModel.difficultyProgresses.isEmpty)
        XCTAssertNil(viewModel.progressStatistics)
        XCTAssertEqual(viewModel.selectedTimeRange, .allTime)
        XCTAssertFalse(viewModel.showingDetailedStats)
    }
    
    // MARK: - Progress Loading Tests
    
    func testLoadSessionProgress() async {
        // Given
        let expectedProgress = SessionProgress(
            currentWordIndex: 5,
            totalWords: 10,
            memorizedCount: 3,
            notMemorizedCount: 2
        )
        mockProgressService.sessionProgress = expectedProgress
        
        // When
        await viewModel.loadSessionProgress()
        
        // Then
        XCTAssertNotNil(viewModel.sessionProgress)
        XCTAssertEqual(viewModel.sessionProgress?.currentWordIndex, 5)
        XCTAssertEqual(viewModel.sessionProgress?.totalWords, 10)
        XCTAssertEqual(viewModel.sessionProgress?.memorizedCount, 3)
    }
    
    func testLoadOverallProgress() async {
        // Given
        let expectedProgress = OverallProgress(
            totalWordsStudied: 50,
            totalWordsMemorized: 35,
            totalSources: 3,
            averageSessionScore: 0.7
        )
        mockProgressService.overallProgress = expectedProgress
        
        // When
        await viewModel.loadOverallProgress()
        
        // Then
        XCTAssertNotNil(viewModel.overallProgress)
        XCTAssertEqual(viewModel.overallProgress?.totalWordsStudied, 50)
        XCTAssertEqual(viewModel.overallProgress?.totalWordsMemorized, 35)
        XCTAssertEqual(viewModel.overallProgress?.totalSources, 3)
    }
    
    func testLoadSourceProgresses() async {
        // Given
        let testSources = createTestTextSources()
        mockStorageService.textSources = testSources
        
        for source in testSources {
            let wordTests = createTestWordTests(sourceId: source.id)
            mockStorageService.wordTests = wordTests
            
            // Add some progress for the words
            for word in wordTests {
                mockStorageService.userProgress = createTestUserProgress(wordId: word.id)
            }
        }
        
        // When
        await viewModel.loadSourceProgresses()
        
        // Then
        XCTAssertEqual(viewModel.sourceProgresses.count, 2)
        XCTAssertEqual(viewModel.sourceProgresses[0].sourceName, "Source 1")
        XCTAssertEqual(viewModel.sourceProgresses[1].sourceName, "Source 2")
    }
    
    func testLoadDifficultyProgresses() async {
        // Given
        let testSources = createTestTextSources()
        mockStorageService.textSources = testSources
        
        let wordTests = createTestWordTests(sourceId: testSources[0].id)
        mockStorageService.wordTests = wordTests
        
        // When
        await viewModel.loadDifficultyProgresses()
        
        // Then
        XCTAssertEqual(viewModel.difficultyProgresses.count, 3) // beginner, intermediate, advanced
        
        let beginnerProgress = viewModel.difficultyProgresses.first { $0.difficulty == .beginner }
        XCTAssertNotNil(beginnerProgress)
    }
    
    func testLoadAllProgress() async {
        // Given
        mockProgressService.sessionProgress = SessionProgress(currentWordIndex: 1, totalWords: 5, memorizedCount: 1, notMemorizedCount: 0)
        mockProgressService.overallProgress = OverallProgress(totalWordsStudied: 10, totalWordsMemorized: 7, totalSources: 1, averageSessionScore: 0.7)
        mockStorageService.textSources = createTestTextSources()
        
        // When
        await viewModel.loadAllProgress()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.sessionProgress)
        XCTAssertNotNil(viewModel.overallProgress)
        XCTAssertNotNil(viewModel.progressStatistics)
    }
    
    // MARK: - Progress Calculation Tests
    
    func testSourceProgressCalculation() {
        // Test the SourceProgress struct calculations
        let sourceProgress = SourceProgress(
            sourceId: UUID(),
            sourceName: "Test Source",
            totalWords: 20,
            memorizedWords: 15,
            studiedWords: 18,
            lastStudied: Date()
        )
        
        XCTAssertEqual(sourceProgress.memorizationRate, 83.33333333333334, accuracy: 0.1)
        XCTAssertEqual(sourceProgress.completionRate, 90.0, accuracy: 0.1)
    }
    
    func testDifficultyProgressCalculation() {
        // Test the DifficultyProgress struct calculations
        let difficultyProgress = DifficultyProgress(
            difficulty: .intermediate,
            totalWords: 25,
            memorizedWords: 20,
            studiedWords: 22
        )
        
        XCTAssertEqual(difficultyProgress.memorizationRate, 90.90909090909092, accuracy: 0.1)
        XCTAssertEqual(difficultyProgress.completionRate, 88.0, accuracy: 0.1)
    }
    
    func testProgressStatisticsFormatting() {
        // Test the ProgressStatistics formatting methods
        let stats = ProgressStatistics(
            totalSessions: 10,
            totalStudyTime: 3665, // 1 hour, 1 minute, 5 seconds
            averageSessionLength: 366.5, // 6 minutes, 6.5 seconds
            streakDays: 5,
            lastStudyDate: Date()
        )
        
        XCTAssertEqual(stats.totalStudyTimeFormatted, "1h 1m")
        XCTAssertEqual(stats.averageSessionLengthFormatted, "6m 6s")
    }
    
    // MARK: - Public Methods Tests
    
    func testRefreshProgress() async {
        // Given
        mockProgressService.overallProgress = OverallProgress(totalWordsStudied: 5, totalWordsMemorized: 3, totalSources: 1, averageSessionScore: 0.6)
        
        // When
        await viewModel.refreshProgress()
        
        // Then
        XCTAssertNotNil(viewModel.overallProgress)
        XCTAssertEqual(viewModel.overallProgress?.totalWordsStudied, 5)
    }
    
    func testGetProgressForSource() {
        // Given
        let sourceId = UUID()
        let sourceProgress = SourceProgress(
            sourceId: sourceId,
            sourceName: "Test Source",
            totalWords: 10,
            memorizedWords: 7,
            studiedWords: 8,
            lastStudied: Date()
        )
        viewModel.sourceProgresses = [sourceProgress]
        
        // When
        let result = viewModel.getProgressForSource(sourceId)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.sourceId, sourceId)
        XCTAssertEqual(result?.sourceName, "Test Source")
    }
    
    func testGetProgressForDifficulty() {
        // Given
        let difficultyProgress = DifficultyProgress(
            difficulty: .intermediate,
            totalWords: 15,
            memorizedWords: 10,
            studiedWords: 12
        )
        viewModel.difficultyProgresses = [difficultyProgress]
        
        // When
        let result = viewModel.getProgressForDifficulty(.intermediate)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.difficulty, .intermediate)
        XCTAssertEqual(result?.totalWords, 15)
    }
    
    func testSelectTimeRange() {
        // When
        viewModel.selectTimeRange(.thisWeek)
        
        // Then
        XCTAssertEqual(viewModel.selectedTimeRange, .thisWeek)
    }
    
    func testToggleDetailedStats() {
        // Given
        XCTAssertFalse(viewModel.showingDetailedStats)
        
        // When
        viewModel.toggleDetailedStats()
        
        // Then
        XCTAssertTrue(viewModel.showingDetailedStats)
        
        // When
        viewModel.toggleDetailedStats()
        
        // Then
        XCTAssertFalse(viewModel.showingDetailedStats)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        // Given
        viewModel.errorMessage = "Test error"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Computed Properties Tests
    
    func testHasProgress() {
        // Given - no progress
        XCTAssertFalse(viewModel.hasProgress)
        
        // When - add progress
        viewModel.overallProgress = OverallProgress(totalWordsStudied: 5, totalWordsMemorized: 3, totalSources: 1, averageSessionScore: 0.6)
        
        // Then
        XCTAssertTrue(viewModel.hasProgress)
    }
    
    func testTotalSourcesWithProgress() {
        // Given
        let sourceProgresses = [
            SourceProgress(sourceId: UUID(), sourceName: "Source 1", totalWords: 10, memorizedWords: 5, studiedWords: 7, lastStudied: Date()),
            SourceProgress(sourceId: UUID(), sourceName: "Source 2", totalWords: 8, memorizedWords: 0, studiedWords: 0, lastStudied: nil),
            SourceProgress(sourceId: UUID(), sourceName: "Source 3", totalWords: 12, memorizedWords: 8, studiedWords: 10, lastStudied: Date())
        ]
        viewModel.sourceProgresses = sourceProgresses
        
        // When
        let count = viewModel.totalSourcesWithProgress
        
        // Then
        XCTAssertEqual(count, 2) // Only sources 1 and 3 have studied words
    }
    
    func testAverageMemorizationRate() {
        // Given
        let sourceProgresses = [
            SourceProgress(sourceId: UUID(), sourceName: "Source 1", totalWords: 10, memorizedWords: 8, studiedWords: 10, lastStudied: Date()), // 80%
            SourceProgress(sourceId: UUID(), sourceName: "Source 2", totalWords: 10, memorizedWords: 6, studiedWords: 10, lastStudied: Date()), // 60%
            SourceProgress(sourceId: UUID(), sourceName: "Source 3", totalWords: 10, memorizedWords: 0, studiedWords: 0, lastStudied: nil) // No progress, should be excluded
        ]
        viewModel.sourceProgresses = sourceProgresses
        
        // When
        let averageRate = viewModel.averageMemorizationRate
        
        // Then
        XCTAssertEqual(averageRate, 70.0, accuracy: 0.1) // (80 + 60) / 2 = 70
    }
    
    func testMostStudiedSource() {
        // Given
        let sourceProgresses = [
            SourceProgress(sourceId: UUID(), sourceName: "Source 1", totalWords: 10, memorizedWords: 5, studiedWords: 7, lastStudied: Date()),
            SourceProgress(sourceId: UUID(), sourceName: "Source 2", totalWords: 8, memorizedWords: 3, studiedWords: 12, lastStudied: Date()),
            SourceProgress(sourceId: UUID(), sourceName: "Source 3", totalWords: 12, memorizedWords: 8, studiedWords: 5, lastStudied: Date())
        ]
        viewModel.sourceProgresses = sourceProgresses
        
        // When
        let mostStudied = viewModel.mostStudiedSource
        
        // Then
        XCTAssertNotNil(mostStudied)
        XCTAssertEqual(mostStudied?.sourceName, "Source 2") // 12 studied words
    }
    
    func testBestPerformingDifficulty() {
        // Given
        let difficultyProgresses = [
            DifficultyProgress(difficulty: .beginner, totalWords: 10, memorizedWords: 9, studiedWords: 10), // 90%
            DifficultyProgress(difficulty: .intermediate, totalWords: 10, memorizedWords: 7, studiedWords: 10), // 70%
            DifficultyProgress(difficulty: .advanced, totalWords: 10, memorizedWords: 5, studiedWords: 10) // 50%
        ]
        viewModel.difficultyProgresses = difficultyProgresses
        
        // When
        let bestPerforming = viewModel.bestPerformingDifficulty
        
        // Then
        XCTAssertNotNil(bestPerforming)
        XCTAssertEqual(bestPerforming?.difficulty, .beginner)
    }
    
    func testFormattedOverallStats() {
        // Given - no progress
        XCTAssertEqual(viewModel.formattedOverallStats, "No progress data")
        
        // When - add progress
        viewModel.overallProgress = OverallProgress(
            totalWordsStudied: 50,
            totalWordsMemorized: 35,
            totalSources: 3,
            averageSessionScore: 0.7
        )
        
        // Then
        let stats = viewModel.formattedOverallStats
        XCTAssertTrue(stats.contains("50 words studied"))
        XCTAssertTrue(stats.contains("35 words memorized"))
        XCTAssertTrue(stats.contains("70% success rate"))
    }
    
    func testProgressSummary() {
        // Given - no progress
        XCTAssertEqual(viewModel.progressSummary, "Start studying to see your progress!")
        
        // When - add progress
        viewModel.overallProgress = OverallProgress(totalWordsStudied: 25, totalWordsMemorized: 18, totalSources: 2, averageSessionScore: 0.72)
        viewModel.sourceProgresses = [
            SourceProgress(sourceId: UUID(), sourceName: "Source 1", totalWords: 10, memorizedWords: 8, studiedWords: 10, lastStudied: Date()),
            SourceProgress(sourceId: UUID(), sourceName: "Source 2", totalWords: 15, memorizedWords: 10, studiedWords: 15, lastStudied: Date())
        ]
        
        // Then
        let summary = viewModel.progressSummary
        XCTAssertTrue(summary.contains("25 words"))
        XCTAssertTrue(summary.contains("2 sources"))
        XCTAssertTrue(summary.contains("18 of them"))
    }
}

// MARK: - Supporting Types Tests

final class TimeRangeTests: XCTestCase {
    
    func testTimeRangeValues() {
        XCTAssertEqual(TimeRange.today.rawValue, "Today")
        XCTAssertEqual(TimeRange.thisWeek.rawValue, "This Week")
        XCTAssertEqual(TimeRange.thisMonth.rawValue, "This Month")
        XCTAssertEqual(TimeRange.allTime.rawValue, "All Time")
    }
    
    func testTimeRangeDateRanges() {
        let now = Date()
        let calendar = Calendar.current
        
        // Test today
        let todayRange = TimeRange.today.dateRange
        XCTAssertTrue(calendar.isDate(todayRange.start, inSameDayAs: now))
        XCTAssertTrue(todayRange.end.timeIntervalSince(now) < 1) // Should be very close to now
        
        // Test all time
        let allTimeRange = TimeRange.allTime.dateRange
        XCTAssertEqual(allTimeRange.start, Date.distantPast)
        XCTAssertTrue(allTimeRange.end.timeIntervalSince(now) < 1) // Should be very close to now
    }
    
    func testTimeRangeCaseIterable() {
        let allRanges = TimeRange.allCases
        XCTAssertEqual(allRanges.count, 4)
        XCTAssertTrue(allRanges.contains(.today))
        XCTAssertTrue(allRanges.contains(.thisWeek))
        XCTAssertTrue(allRanges.contains(.thisMonth))
        XCTAssertTrue(allRanges.contains(.allTime))
    }
}

final class SourceProgressTests: XCTestCase {
    
    func testSourceProgressCalculations() {
        let progress = SourceProgress(
            sourceId: UUID(),
            sourceName: "Test",
            totalWords: 20,
            memorizedWords: 15,
            studiedWords: 18,
            lastStudied: Date()
        )
        
        XCTAssertEqual(progress.memorizationRate, 83.33333333333334, accuracy: 0.1)
        XCTAssertEqual(progress.completionRate, 90.0, accuracy: 0.1)
    }
    
    func testSourceProgressWithZeroStudiedWords() {
        let progress = SourceProgress(
            sourceId: UUID(),
            sourceName: "Test",
            totalWords: 20,
            memorizedWords: 0,
            studiedWords: 0,
            lastStudied: nil
        )
        
        XCTAssertEqual(progress.memorizationRate, 0)
        XCTAssertEqual(progress.completionRate, 0)
    }
}

final class DifficultyProgressTests: XCTestCase {
    
    func testDifficultyProgressCalculations() {
        let progress = DifficultyProgress(
            difficulty: .intermediate,
            totalWords: 25,
            memorizedWords: 20,
            studiedWords: 22
        )
        
        XCTAssertEqual(progress.memorizationRate, 90.90909090909092, accuracy: 0.1)
        XCTAssertEqual(progress.completionRate, 88.0, accuracy: 0.1)
    }
    
    func testDifficultyProgressWithZeroWords() {
        let progress = DifficultyProgress(
            difficulty: .beginner,
            totalWords: 0,
            memorizedWords: 0,
            studiedWords: 0
        )
        
        XCTAssertEqual(progress.memorizationRate, 0)
        XCTAssertEqual(progress.completionRate, 0)
    }
}

final class ProgressStatisticsTests: XCTestCase {
    
    func testProgressStatisticsFormatting() {
        let stats = ProgressStatistics(
            totalSessions: 15,
            totalStudyTime: 7265, // 2 hours, 1 minute, 5 seconds
            averageSessionLength: 484.33, // 8 minutes, 4.33 seconds
            streakDays: 7,
            lastStudyDate: Date()
        )
        
        XCTAssertEqual(stats.totalStudyTimeFormatted, "2h 1m")
        XCTAssertEqual(stats.averageSessionLengthFormatted, "8m 4s")
    }
    
    func testProgressStatisticsFormattingWithZeroTime() {
        let stats = ProgressStatistics(
            totalSessions: 0,
            totalStudyTime: 0,
            averageSessionLength: 0,
            streakDays: 0,
            lastStudyDate: nil
        )
        
        XCTAssertEqual(stats.totalStudyTimeFormatted, "0h 0m")
        XCTAssertEqual(stats.averageSessionLengthFormatted, "0m 0s")
    }
}
import Foundation
import SwiftUI

enum WordTestSessionState {
    case notStarted
    case loading
    case ready
    case inProgress
    case completed
    case error(String)
}

enum WordDisplayState {
    case showingWord
    case showingMeaning
    case awaitingResponse
}

@MainActor
class WordTestViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentWord: WordTest?
    @Published var wordTests: [WordTest] = []
    @Published var currentIndex: Int = 0
    @Published var sessionState: WordTestSessionState = .notStarted
    @Published var wordDisplayState: WordDisplayState = .showingWord
    @Published var selectedDifficulty: DifficultyLevel?
    @Published var selectedSourceId: UUID?
    @Published var errorMessage: String?
    
    // Session progress
    @Published var memorizedCount: Int = 0
    @Published var notMemorizedCount: Int = 0
    @Published var sessionProgress: SessionProgress?
    
    // UI state
    @Published var showingSessionComplete: Bool = false
    @Published var canContinue: Bool = false
    
    // MARK: - Dependencies
    private let storageService: StorageServiceProtocol
    private let progressService: ProgressTrackingServiceProtocol
    
    // MARK: - Private Properties
    private var sessionStartTime: Date?
    private var currentWordStartTime: Date?
    
    // MARK: - Initialization
    init(storageService: StorageServiceProtocol, progressService: ProgressTrackingServiceProtocol) {
        self.storageService = storageService
        self.progressService = progressService
    }
    
    // MARK: - Session Management
    
    func startSession(sourceId: UUID, difficulty: DifficultyLevel?) async {
        selectedSourceId = sourceId
        selectedDifficulty = difficulty
        sessionState = .loading
        errorMessage = nil
        
        await loadWordTests(for: sourceId, difficulty: difficulty)
        
        if !wordTests.isEmpty {
            startNewSession()
        }
    }
    
    func resumeSession() async {
        guard sessionState == .inProgress || sessionState == .ready else { return }
        
        if currentIndex < wordTests.count {
            setCurrentWord()
            sessionState = .inProgress
        } else {
            completeSession()
        }
    }
    
    func restartSession() async {
        guard let sourceId = selectedSourceId else { return }
        
        resetSessionState()
        await startSession(sourceId: sourceId, difficulty: selectedDifficulty)
    }
    
    func endSession() {
        resetSessionState()
        sessionState = .notStarted
    }
    
    private func startNewSession() {
        currentIndex = 0
        memorizedCount = 0
        notMemorizedCount = 0
        sessionStartTime = Date()
        sessionState = .ready
        
        setCurrentWord()
        updateSessionProgress()
    }
    
    private func completeSession() {
        sessionState = .completed
        showingSessionComplete = true
        updateSessionProgress()
    }
    
    private func resetSessionState() {
        currentWord = nil
        wordTests = []
        currentIndex = 0
        memorizedCount = 0
        notMemorizedCount = 0
        sessionProgress = nil
        sessionStartTime = nil
        currentWordStartTime = nil
        wordDisplayState = .showingWord
        showingSessionComplete = false
        canContinue = false
    }
    
    // MARK: - Word Test Loading
    
    func loadWordTests(for sourceId: UUID, difficulty: DifficultyLevel?) async {
        sessionState = .loading
        errorMessage = nil
        
        do {
            let tests = try await storageService.fetchWordTests(for: sourceId, difficulty: difficulty)
            wordTests = tests.shuffled() // Randomize order for better learning
            
            if wordTests.isEmpty {
                sessionState = .error("No words found for the selected difficulty level")
            } else {
                sessionState = .ready
            }
        } catch {
            let message = "Failed to load word tests: \(error.localizedDescription)"
            errorMessage = message
            sessionState = .error(message)
        }
    }
    
    func loadAvailableDifficulties(for sourceId: UUID) async -> [DifficultyLevel] {
        do {
            let allTests = try await storageService.fetchWordTests(for: sourceId, difficulty: nil)
            let difficulties = Set(allTests.map { $0.difficultyLevel })
            return Array(difficulties).sorted { $0.rawValue < $1.rawValue }
        } catch {
            return []
        }
    }
    
    func getWordCount(for sourceId: UUID, difficulty: DifficultyLevel?) async -> Int {
        do {
            let tests = try await storageService.fetchWordTests(for: sourceId, difficulty: difficulty)
            return tests.count
        } catch {
            return 0
        }
    }
    
    // MARK: - Word Navigation
    
    func showMeaning() {
        guard wordDisplayState == .showingWord else { return }
        wordDisplayState = .showingMeaning
        currentWordStartTime = Date()
    }
    
    func recordResponse(isMemorized: Bool) async {
        guard let currentWord = currentWord else { return }
        guard wordDisplayState == .showingMeaning else { return }
        
        wordDisplayState = .awaitingResponse
        
        // Record the response
        await progressService.recordResponse(wordId: currentWord.id, isMemorized: isMemorized)
        
        // Update local counts
        if isMemorized {
            memorizedCount += 1
        } else {
            notMemorizedCount += 1
        }
        
        // Move to next word or complete session
        await moveToNextWord()
    }
    
    private func moveToNextWord() async {
        currentIndex += 1
        
        if currentIndex < wordTests.count {
            setCurrentWord()
            updateSessionProgress()
            wordDisplayState = .showingWord
        } else {
            completeSession()
        }
    }
    
    private func setCurrentWord() {
        guard currentIndex < wordTests.count else {
            currentWord = nil
            return
        }
        
        currentWord = wordTests[currentIndex]
        wordDisplayState = .showingWord
        canContinue = currentIndex > 0
    }
    
    func goToPreviousWord() {
        guard currentIndex > 0 else { return }
        
        currentIndex -= 1
        setCurrentWord()
        updateSessionProgress()
        
        // Adjust counts (this is approximate since we don't track individual responses)
        if memorizedCount > 0 {
            memorizedCount -= 1
        } else if notMemorizedCount > 0 {
            notMemorizedCount -= 1
        }
    }
    
    func skipCurrentWord() async {
        await moveToNextWord()
    }
    
    // MARK: - Progress Tracking
    
    private func updateSessionProgress() {
        sessionProgress = SessionProgress(
            currentWordIndex: currentIndex,
            totalWords: wordTests.count,
            memorizedCount: memorizedCount,
            notMemorizedCount: notMemorizedCount
        )
    }
    
    func getOverallProgress() async -> OverallProgress? {
        return await progressService.getOverallProgress()
    }
    
    // MARK: - Difficulty Management
    
    func selectDifficulty(_ difficulty: DifficultyLevel) {
        selectedDifficulty = difficulty
    }
    
    func clearDifficultySelection() {
        selectedDifficulty = nil
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
        if case .error = sessionState {
            sessionState = .notStarted
        }
    }
    
    func retryLoading() async {
        guard let sourceId = selectedSourceId else { return }
        await loadWordTests(for: sourceId, difficulty: selectedDifficulty)
    }
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        if case .loading = sessionState {
            return true
        }
        return false
    }
    
    var hasError: Bool {
        if case .error = sessionState {
            return true
        }
        return false
    }
    
    var isSessionActive: Bool {
        switch sessionState {
        case .ready, .inProgress:
            return true
        default:
            return false
        }
    }
    
    var isSessionCompleted: Bool {
        if case .completed = sessionState {
            return true
        }
        return false
    }
    
    var progressPercentage: Double {
        guard wordTests.count > 0 else { return 0 }
        return Double(currentIndex) / Double(wordTests.count) * 100
    }
    
    var remainingWords: Int {
        max(0, wordTests.count - currentIndex)
    }
    
    var canShowMeaning: Bool {
        wordDisplayState == .showingWord && currentWord != nil
    }
    
    var canRecordResponse: Bool {
        wordDisplayState == .showingMeaning && currentWord != nil
    }
    
    var sessionDuration: TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    var sessionSummary: String {
        let total = memorizedCount + notMemorizedCount
        guard total > 0 else { return "No words completed" }
        
        let percentage = Double(memorizedCount) / Double(total) * 100
        return "\(memorizedCount)/\(total) words memorized (\(Int(percentage))%)"
    }
    
    // MARK: - Utility Methods
    
    func getWordProgress(for word: WordTest) async -> UserProgress? {
        do {
            return try await storageService.fetchProgress(for: word.id)
        } catch {
            return nil
        }
    }
    
    func formatSessionTime() -> String {
        let duration = sessionDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
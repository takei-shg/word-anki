import Foundation

// MARK: - Progress Tracking Service Demo
// This file demonstrates how to use the ProgressTrackingService

class ProgressTrackingServiceDemo {
    private let progressService: ProgressTrackingService
    
    init() {
        self.progressService = ProgressTrackingService()
    }
    
    // MARK: - Demo Functions
    
    /// Demonstrates a complete word test session
    func demonstrateWordTestSession() async {
        print("=== Progress Tracking Service Demo ===")
        
        // Sample word IDs for a session
        let wordIds = [UUID(), UUID(), UUID(), UUID(), UUID()]
        
        // Start a new session
        progressService.startSession(with: wordIds)
        print("Started session with \(wordIds.count) words")
        
        // Simulate user responses
        let responses = [true, false, true, true, false] // memorized status
        
        for (index, wordId) in wordIds.enumerated() {
            let isMemorized = responses[index]
            
            // Record user response
            await progressService.recordResponse(wordId: wordId, isMemorized: isMemorized)
            
            // Show progress after each response
            let sessionProgress = await progressService.getSessionProgress()
            print("Word \(index + 1): \(isMemorized ? "Memorized" : "Not Memorized")")
            print("  Progress: \(sessionProgress.currentWordIndex)/\(sessionProgress.totalWords) (\(String(format: "%.1f", sessionProgress.completionPercentage))%)")
            print("  Memorized: \(sessionProgress.memorizedCount), Not Memorized: \(sessionProgress.notMemorizedCount)")
        }
        
        // Show final session results
        let finalProgress = await progressService.getSessionProgress()
        print("\n=== Session Complete ===")
        print("Total words: \(finalProgress.totalWords)")
        print("Memorized: \(finalProgress.memorizedCount)")
        print("Not memorized: \(finalProgress.notMemorizedCount)")
        print("Success rate: \(String(format: "%.1f", Double(finalProgress.memorizedCount) / Double(finalProgress.totalWords) * 100))%")
        
        // Show overall progress
        let overallProgress = await progressService.getOverallProgress()
        print("\n=== Overall Progress ===")
        print("Total words studied: \(overallProgress.totalWordsStudied)")
        print("Total memorized: \(overallProgress.totalWordsMemorized)")
        print("Memorization rate: \(String(format: "%.1f", overallProgress.memorizationRate))%")
        print("Average session score: \(String(format: "%.1f", overallProgress.averageSessionScore))%")
        
        // End the session
        progressService.endSession()
        print("\nSession ended.")
    }
    
    /// Demonstrates session management features
    func demonstrateSessionManagement() async {
        print("\n=== Session Management Demo ===")
        
        let wordIds = [UUID(), UUID(), UUID()]
        
        // Start session
        progressService.startSession(with: wordIds)
        print("Session started with \(wordIds.count) words")
        
        // Check current word
        if let currentWord = progressService.getCurrentWord() {
            print("Current word ID: \(currentWord)")
        }
        
        // Check if there are more words
        print("Has next word: \(progressService.hasNextWord())")
        print("Is session complete: \(progressService.isSessionComplete())")
        
        // Complete first word
        await progressService.recordResponse(wordId: wordIds[0], isMemorized: true)
        print("Completed first word")
        
        // Check progress
        if let currentWord = progressService.getCurrentWord() {
            print("Current word ID: \(currentWord)")
        }
        print("Has next word: \(progressService.hasNextWord())")
        print("Is session complete: \(progressService.isSessionComplete())")
        
        // Complete remaining words
        await progressService.recordResponse(wordId: wordIds[1], isMemorized: false)
        await progressService.recordResponse(wordId: wordIds[2], isMemorized: true)
        
        print("Has next word: \(progressService.hasNextWord())")
        print("Is session complete: \(progressService.isSessionComplete())")
        
        progressService.endSession()
    }
    
    /// Demonstrates progress statistics features
    func demonstrateProgressStatistics() async {
        print("\n=== Progress Statistics Demo ===")
        
        // This would typically use real data from the repositories
        // For demo purposes, we'll show the structure
        
        let sampleSourceId = UUID()
        let sampleDifficulty = DifficultyLevel.intermediate
        
        // Get source-specific progress
        let sourceProgress = await progressService.getProgressBySource(sampleSourceId)
        print("Source Progress:")
        print("  Total words: \(sourceProgress.totalWords)")
        print("  Memorized: \(sourceProgress.memorizedWords)")
        print("  Not memorized: \(sourceProgress.notMemorizedWords)")
        print("  Completion: \(String(format: "%.1f", sourceProgress.completionPercentage))%")
        print("  Memorization rate: \(String(format: "%.1f", sourceProgress.memorizationRate))%")
        print("  Avg reviews per word: \(String(format: "%.1f", sourceProgress.averageReviewsPerWord))")
        
        // Get difficulty-specific progress
        let difficultyProgress = await progressService.getProgressByDifficulty(sampleDifficulty)
        print("\nDifficulty Progress (\(sampleDifficulty.displayName)):")
        print("  Total words: \(difficultyProgress.totalWords)")
        print("  Memorized: \(difficultyProgress.memorizedWords)")
        print("  Not memorized: \(difficultyProgress.notMemorizedWords)")
        print("  Completion: \(String(format: "%.1f", difficultyProgress.completionPercentage))%")
        print("  Memorization rate: \(String(format: "%.1f", difficultyProgress.memorizationRate))%")
        
        // Get memorized and not memorized words
        let memorizedWords = await progressService.getMemorizedWords()
        let notMemorizedWords = await progressService.getNotMemorizedWords()
        
        print("\nWord Lists:")
        print("  Memorized words: \(memorizedWords.count)")
        print("  Not memorized words: \(notMemorizedWords.count)")
    }
}

// MARK: - Usage Example
/*
 To use the ProgressTrackingService in your app:
 
 1. Create an instance:
    let progressService = ProgressTrackingService()
 
 2. Start a session:
    progressService.startSession(with: wordIds)
 
 3. Record user responses:
    await progressService.recordResponse(wordId: wordId, isMemorized: true)
 
 4. Get progress updates:
    let progress = await progressService.getSessionProgress()
    let overallProgress = await progressService.getOverallProgress()
 
 5. End the session:
    progressService.endSession()
 
 The service automatically handles:
 - Progress persistence through UserProgressRepository
 - Session state management
 - Statistics calculation
 - Error handling and logging
 */
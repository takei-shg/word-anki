import Foundation
import os.log

class ProgressTrackingService: ProgressTrackingServiceProtocol {
    private let userProgressRepository: UserProgressRepository
    private let wordTestRepository: WordTestRepository
    private let logger = Logger(subsystem: "com.vocabularyapp", category: "progressTrackingService")
    
    // Session state
    private var currentSessionWords: [UUID] = []
    private var currentSessionProgress: [UUID: Bool] = [:]
    private var currentWordIndex: Int = 0
    
    init(userProgressRepository: UserProgressRepository = UserProgressRepository(),
         wordTestRepository: WordTestRepository = WordTestRepository()) {
        self.userProgressRepository = userProgressRepository
        self.wordTestRepository = wordTestRepository
    }
    
    // MARK: - ProgressTrackingServiceProtocol Implementation
    
    func recordResponse(wordId: UUID, isMemorized: Bool) async {
        do {
            // Record the response in the repository
            let progress = try await userProgressRepository.recordProgress(wordId, isMemorized: isMemorized)
            
            // Update session progress
            currentSessionProgress[wordId] = isMemorized
            
            // Advance to next word if this word is in current session
            if let index = currentSessionWords.firstIndex(of: wordId) {
                currentWordIndex = index + 1
            }
            
            logger.info("Recorded response for word \(wordId): memorized=\(isMemorized)")
        } catch {
            logger.error("Failed to record response for word \(wordId): \(error.localizedDescription)")
        }
    }
    
    func getSessionProgress() async -> SessionProgress {
        let totalWords = currentSessionWords.count
        let memorizedCount = currentSessionProgress.values.filter { $0 }.count
        let notMemorizedCount = currentSessionProgress.values.filter { !$0 }.count
        
        return SessionProgress(
            currentWordIndex: currentWordIndex,
            totalWords: totalWords,
            memorizedCount: memorizedCount,
            notMemorizedCount: notMemorizedCount
        )
    }
    
    func getOverallProgress() async -> OverallProgress {
        do {
            let statistics = try await userProgressRepository.getStatistics()
            let sourceCount = try await getUniqueSourceCount()
            let averageScore = try await calculateAverageSessionScore()
            
            return OverallProgress(
                totalWordsStudied: statistics.totalWords,
                totalWordsMemorized: statistics.memorizedWords,
                totalSources: sourceCount,
                averageSessionScore: averageScore
            )
        } catch {
            logger.error("Failed to get overall progress: \(error.localizedDescription)")
            return OverallProgress(
                totalWordsStudied: 0,
                totalWordsMemorized: 0,
                totalSources: 0,
                averageSessionScore: 0.0
            )
        }
    }
    
    // MARK: - Session Management
    
    func startSession(with wordIds: [UUID]) {
        currentSessionWords = wordIds
        currentSessionProgress.removeAll()
        currentWordIndex = 0
        logger.info("Started new session with \(wordIds.count) words")
    }
    
    func endSession() {
        logger.info("Ended session with \(currentSessionWords.count) words, \(currentSessionProgress.count) responses")
        currentSessionWords.removeAll()
        currentSessionProgress.removeAll()
        currentWordIndex = 0
    }
    
    func getCurrentWord() -> UUID? {
        guard currentWordIndex < currentSessionWords.count else { return nil }
        return currentSessionWords[currentWordIndex]
    }
    
    func hasNextWord() -> Bool {
        return currentWordIndex < currentSessionWords.count
    }
    
    func isSessionComplete() -> Bool {
        return currentWordIndex >= currentSessionWords.count
    }
    
    // MARK: - Progress Statistics
    
    func getProgressForWord(_ wordId: UUID) async -> UserProgress? {
        do {
            return try await userProgressRepository.fetchByWord(wordId)
        } catch {
            logger.error("Failed to get progress for word \(wordId): \(error.localizedDescription)")
            return nil
        }
    }
    
    func getMemorizedWords() async -> [UserProgress] {
        do {
            return try await userProgressRepository.fetchMemorized()
        } catch {
            logger.error("Failed to get memorized words: \(error.localizedDescription)")
            return []
        }
    }
    
    func getNotMemorizedWords() async -> [UserProgress] {
        do {
            return try await userProgressRepository.fetchNotMemorized()
        } catch {
            logger.error("Failed to get not memorized words: \(error.localizedDescription)")
            return []
        }
    }
    
    func getProgressBySource(_ sourceId: UUID) async -> SourceProgress {
        do {
            let allWords = try await wordTestRepository.fetchBySource(sourceId)
            let allWordIds = allWords.map { $0.id }
            
            var memorizedCount = 0
            var notMemorizedCount = 0
            var totalReviews = 0
            
            for wordId in allWordIds {
                if let progress = try await userProgressRepository.fetchByWord(wordId) {
                    if progress.isMemorized {
                        memorizedCount += 1
                    } else {
                        notMemorizedCount += 1
                    }
                    totalReviews += progress.reviewCount
                }
            }
            
            return SourceProgress(
                sourceId: sourceId,
                totalWords: allWords.count,
                memorizedWords: memorizedCount,
                notMemorizedWords: notMemorizedCount,
                totalReviews: totalReviews
            )
        } catch {
            logger.error("Failed to get progress for source \(sourceId): \(error.localizedDescription)")
            return SourceProgress(
                sourceId: sourceId,
                totalWords: 0,
                memorizedWords: 0,
                notMemorizedWords: 0,
                totalReviews: 0
            )
        }
    }
    
    func getProgressByDifficulty(_ difficulty: DifficultyLevel) async -> DifficultyProgress {
        do {
            let allWords = try await wordTestRepository.fetchByDifficulty(difficulty)
            let allWordIds = allWords.map { $0.id }
            
            var memorizedCount = 0
            var notMemorizedCount = 0
            var totalReviews = 0
            
            for wordId in allWordIds {
                if let progress = try await userProgressRepository.fetchByWord(wordId) {
                    if progress.isMemorized {
                        memorizedCount += 1
                    } else {
                        notMemorizedCount += 1
                    }
                    totalReviews += progress.reviewCount
                }
            }
            
            return DifficultyProgress(
                difficulty: difficulty,
                totalWords: allWords.count,
                memorizedWords: memorizedCount,
                notMemorizedWords: notMemorizedCount,
                totalReviews: totalReviews
            )
        } catch {
            logger.error("Failed to get progress for difficulty \(difficulty): \(error.localizedDescription)")
            return DifficultyProgress(
                difficulty: difficulty,
                totalWords: 0,
                memorizedWords: 0,
                notMemorizedWords: 0,
                totalReviews: 0
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getUniqueSourceCount() async throws -> Int {
        let allWords = try await wordTestRepository.fetchAll()
        let uniqueSourceIds = Set(allWords.map { $0.sourceId })
        return uniqueSourceIds.count
    }
    
    private func calculateAverageSessionScore() async throws -> Double {
        let allProgress = try await userProgressRepository.fetchAll()
        
        guard !allProgress.isEmpty else { return 0.0 }
        
        let totalScore = allProgress.reduce(0.0) { sum, progress in
            return sum + (progress.isMemorized ? 1.0 : 0.0)
        }
        
        return totalScore / Double(allProgress.count) * 100.0
    }
}

// MARK: - Supporting Types

struct SourceProgress {
    let sourceId: UUID
    let totalWords: Int
    let memorizedWords: Int
    let notMemorizedWords: Int
    let totalReviews: Int
    
    var completionPercentage: Double {
        guard totalWords > 0 else { return 0.0 }
        let studiedWords = memorizedWords + notMemorizedWords
        return Double(studiedWords) / Double(totalWords) * 100.0
    }
    
    var memorizationRate: Double {
        let studiedWords = memorizedWords + notMemorizedWords
        guard studiedWords > 0 else { return 0.0 }
        return Double(memorizedWords) / Double(studiedWords) * 100.0
    }
    
    var averageReviewsPerWord: Double {
        let studiedWords = memorizedWords + notMemorizedWords
        guard studiedWords > 0 else { return 0.0 }
        return Double(totalReviews) / Double(studiedWords)
    }
}

struct DifficultyProgress {
    let difficulty: DifficultyLevel
    let totalWords: Int
    let memorizedWords: Int
    let notMemorizedWords: Int
    let totalReviews: Int
    
    var completionPercentage: Double {
        guard totalWords > 0 else { return 0.0 }
        let studiedWords = memorizedWords + notMemorizedWords
        return Double(studiedWords) / Double(totalWords) * 100.0
    }
    
    var memorizationRate: Double {
        let studiedWords = memorizedWords + notMemorizedWords
        guard studiedWords > 0 else { return 0.0 }
        return Double(memorizedWords) / Double(studiedWords) * 100.0
    }
    
    var averageReviewsPerWord: Double {
        let studiedWords = memorizedWords + notMemorizedWords
        guard studiedWords > 0 else { return 0.0 }
        return Double(totalReviews) / Double(studiedWords)
    }
}
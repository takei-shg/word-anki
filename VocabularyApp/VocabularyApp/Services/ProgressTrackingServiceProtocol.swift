import Foundation

struct SessionProgress {
    let currentWordIndex: Int
    let totalWords: Int
    let memorizedCount: Int
    let notMemorizedCount: Int
    
    var completionPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(currentWordIndex) / Double(totalWords) * 100
    }
}

struct OverallProgress {
    let totalWordsStudied: Int
    let totalWordsMemorized: Int
    let totalSources: Int
    let averageSessionScore: Double
    
    var memorizationRate: Double {
        guard totalWordsStudied > 0 else { return 0 }
        return Double(totalWordsMemorized) / Double(totalWordsStudied) * 100
    }
}

protocol ProgressTrackingServiceProtocol {
    func recordResponse(wordId: UUID, isMemorized: Bool) async
    func getSessionProgress() async -> SessionProgress
    func getOverallProgress() async -> OverallProgress
}
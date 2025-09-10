import Foundation
import SwiftUI

struct SourceProgress {
    let sourceId: UUID
    let sourceName: String
    let totalWords: Int
    let memorizedWords: Int
    let studiedWords: Int
    let lastStudied: Date?
    
    var memorizationRate: Double {
        guard studiedWords > 0 else { return 0 }
        return Double(memorizedWords) / Double(studiedWords) * 100
    }
    
    var completionRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(studiedWords) / Double(totalWords) * 100
    }
}

struct DifficultyProgress {
    let difficulty: DifficultyLevel
    let totalWords: Int
    let memorizedWords: Int
    let studiedWords: Int
    
    var memorizationRate: Double {
        guard studiedWords > 0 else { return 0 }
        return Double(memorizedWords) / Double(studiedWords) * 100
    }
    
    var completionRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(studiedWords) / Double(totalWords) * 100
    }
}

struct ProgressStatistics {
    let totalSessions: Int
    let totalStudyTime: TimeInterval
    let averageSessionLength: TimeInterval
    let streakDays: Int
    let lastStudyDate: Date?
    
    var averageSessionLengthFormatted: String {
        let minutes = Int(averageSessionLength) / 60
        let seconds = Int(averageSessionLength) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    var totalStudyTimeFormatted: String {
        let hours = Int(totalStudyTime) / 3600
        let minutes = Int(totalStudyTime) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

@MainActor
class ProgressViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var sessionProgress: SessionProgress?
    @Published var overallProgress: OverallProgress?
    @Published var sourceProgresses: [SourceProgress] = []
    @Published var difficultyProgresses: [DifficultyProgress] = []
    @Published var progressStatistics: ProgressStatistics?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: TimeRange = .allTime
    @Published var showingDetailedStats: Bool = false
    
    // MARK: - Dependencies
    private let progressService: ProgressTrackingServiceProtocol
    private let storageService: StorageServiceProtocol
    
    // MARK: - Private Properties
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    init(progressService: ProgressTrackingServiceProtocol, storageService: StorageServiceProtocol) {
        self.progressService = progressService
        self.storageService = storageService
        
        Task {
            await loadAllProgress()
        }
        
        startPeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Progress Loading
    
    func loadAllProgress() async {
        isLoading = true
        errorMessage = nil
        
        async let sessionTask = loadSessionProgress()
        async let overallTask = loadOverallProgress()
        async let sourceTask = loadSourceProgresses()
        async let difficultyTask = loadDifficultyProgresses()
        async let statsTask = loadProgressStatistics()
        
        await sessionTask
        await overallTask
        await sourceTask
        await difficultyTask
        await statsTask
        
        isLoading = false
    }
    
    func loadSessionProgress() async {
        do {
            sessionProgress = await progressService.getSessionProgress()
        } catch {
            handleError("Failed to load session progress: \(error.localizedDescription)")
        }
    }
    
    func loadOverallProgress() async {
        do {
            overallProgress = await progressService.getOverallProgress()
        } catch {
            handleError("Failed to load overall progress: \(error.localizedDescription)")
        }
    }
    
    func loadSourceProgresses() async {
        do {
            let textSources = try await storageService.fetchTextSources()
            var progresses: [SourceProgress] = []
            
            for source in textSources {
                let sourceProgress = await calculateSourceProgress(for: source)
                progresses.append(sourceProgress)
            }
            
            sourceProgresses = progresses.sorted { $0.lastStudied ?? Date.distantPast > $1.lastStudied ?? Date.distantPast }
        } catch {
            handleError("Failed to load source progress: \(error.localizedDescription)")
        }
    }
    
    func loadDifficultyProgresses() async {
        do {
            var progresses: [DifficultyProgress] = []
            
            for difficulty in DifficultyLevel.allCases {
                let difficultyProgress = await calculateDifficultyProgress(for: difficulty)
                progresses.append(difficultyProgress)
            }
            
            difficultyProgresses = progresses
        } catch {
            handleError("Failed to load difficulty progress: \(error.localizedDescription)")
        }
    }
    
    func loadProgressStatistics() async {
        do {
            progressStatistics = await calculateProgressStatistics()
        } catch {
            handleError("Failed to load progress statistics: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Progress Calculations
    
    private func calculateSourceProgress(for source: TextSource) async -> SourceProgress {
        do {
            let allWords = try await storageService.fetchWordTests(for: source.id, difficulty: nil)
            var memorizedCount = 0
            var studiedCount = 0
            var lastStudied: Date?
            
            for word in allWords {
                if let progress = try? await storageService.fetchProgress(for: word.id) {
                    studiedCount += 1
                    if progress.isMemorized {
                        memorizedCount += 1
                    }
                    
                    if let lastReviewed = lastStudied {
                        if progress.lastReviewed > lastReviewed {
                            lastStudied = progress.lastReviewed
                        }
                    } else {
                        lastStudied = progress.lastReviewed
                    }
                }
            }
            
            return SourceProgress(
                sourceId: source.id,
                sourceName: source.title,
                totalWords: allWords.count,
                memorizedWords: memorizedCount,
                studiedWords: studiedCount,
                lastStudied: lastStudied
            )
        } catch {
            return SourceProgress(
                sourceId: source.id,
                sourceName: source.title,
                totalWords: 0,
                memorizedWords: 0,
                studiedWords: 0,
                lastStudied: nil
            )
        }
    }
    
    private func calculateDifficultyProgress(for difficulty: DifficultyLevel) async -> DifficultyProgress {
        do {
            let textSources = try await storageService.fetchTextSources()
            var totalWords = 0
            var memorizedCount = 0
            var studiedCount = 0
            
            for source in textSources {
                let words = try await storageService.fetchWordTests(for: source.id, difficulty: difficulty)
                totalWords += words.count
                
                for word in words {
                    if let progress = try? await storageService.fetchProgress(for: word.id) {
                        studiedCount += 1
                        if progress.isMemorized {
                            memorizedCount += 1
                        }
                    }
                }
            }
            
            return DifficultyProgress(
                difficulty: difficulty,
                totalWords: totalWords,
                memorizedWords: memorizedCount,
                studiedWords: studiedCount
            )
        } catch {
            return DifficultyProgress(
                difficulty: difficulty,
                totalWords: 0,
                memorizedWords: 0,
                studiedWords: 0
            )
        }
    }
    
    private func calculateProgressStatistics() async -> ProgressStatistics {
        // This is a simplified implementation
        // In a real app, you'd track session data more comprehensively
        let totalSessions = await estimateTotalSessions()
        let totalStudyTime = await estimateTotalStudyTime()
        let averageSessionLength = totalSessions > 0 ? totalStudyTime / Double(totalSessions) : 0
        let streakDays = await calculateStreakDays()
        let lastStudyDate = await getLastStudyDate()
        
        return ProgressStatistics(
            totalSessions: totalSessions,
            totalStudyTime: totalStudyTime,
            averageSessionLength: averageSessionLength,
            streakDays: streakDays,
            lastStudyDate: lastStudyDate
        )
    }
    
    private func estimateTotalSessions() async -> Int {
        // Estimate based on unique study dates
        // This is simplified - in a real app you'd track sessions explicitly
        return max(1, sourceProgresses.reduce(0) { $0 + $1.studiedWords } / 10)
    }
    
    private func estimateTotalStudyTime() async -> TimeInterval {
        // Estimate based on words studied (assuming 30 seconds per word)
        let totalWordsStudied = sourceProgresses.reduce(0) { $0 + $1.studiedWords }
        return Double(totalWordsStudied) * 30.0
    }
    
    private func calculateStreakDays() async -> Int {
        // Simplified streak calculation
        // In a real app, you'd track daily study activity
        guard let lastStudy = await getLastStudyDate() else { return 0 }
        
        let daysSinceLastStudy = Calendar.current.dateComponents([.day], from: lastStudy, to: Date()).day ?? 0
        return daysSinceLastStudy <= 1 ? max(1, 7 - daysSinceLastStudy) : 0
    }
    
    private func getLastStudyDate() async -> Date? {
        return sourceProgresses.compactMap { $0.lastStudied }.max()
    }
    
    // MARK: - Public Methods
    
    func refreshProgress() async {
        await loadAllProgress()
    }
    
    func getProgressForSource(_ sourceId: UUID) -> SourceProgress? {
        return sourceProgresses.first { $0.sourceId == sourceId }
    }
    
    func getProgressForDifficulty(_ difficulty: DifficultyLevel) -> DifficultyProgress? {
        return difficultyProgresses.first { $0.difficulty == difficulty }
    }
    
    func selectTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        Task {
            await loadAllProgress()
        }
    }
    
    func toggleDetailedStats() {
        showingDetailedStats.toggle()
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) {
        errorMessage = message
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Periodic Refresh
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                await self.loadSessionProgress()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var hasProgress: Bool {
        return overallProgress?.totalWordsStudied ?? 0 > 0
    }
    
    var totalSourcesWithProgress: Int {
        return sourceProgresses.filter { $0.studiedWords > 0 }.count
    }
    
    var averageMemorizationRate: Double {
        let rates = sourceProgresses.compactMap { $0.studiedWords > 0 ? $0.memorizationRate : nil }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }
    
    var mostStudiedSource: SourceProgress? {
        return sourceProgresses.max { $0.studiedWords < $1.studiedWords }
    }
    
    var bestPerformingDifficulty: DifficultyProgress? {
        return difficultyProgresses.max { $0.memorizationRate < $1.memorizationRate }
    }
    
    var formattedOverallStats: String {
        guard let overall = overallProgress else { return "No progress data" }
        
        return """
        \(overall.totalWordsStudied) words studied
        \(overall.totalWordsMemorized) words memorized
        \(Int(overall.memorizationRate))% success rate
        """
    }
    
    var progressSummary: String {
        guard hasProgress else { return "Start studying to see your progress!" }
        
        let totalStudied = overallProgress?.totalWordsStudied ?? 0
        let totalMemorized = overallProgress?.totalWordsMemorized ?? 0
        let sources = totalSourcesWithProgress
        
        return "You've studied \(totalStudied) words from \(sources) sources and memorized \(totalMemorized) of them."
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case allTime = "All Time"
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (start, now)
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (start, now)
        case .allTime:
            return (Date.distantPast, now)
        }
    }
}
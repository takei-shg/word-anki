import Foundation

protocol StorageServiceProtocol {
    func saveWordTests(_ tests: [WordTest]) async throws
    func fetchWordTests(for sourceId: UUID, difficulty: DifficultyLevel?) async throws -> [WordTest]
    func saveProgress(_ progress: UserProgress) async throws
    func fetchProgress(for wordId: UUID) async throws -> UserProgress?
    func saveTextSource(_ source: TextSource) async throws
    func fetchTextSources() async throws -> [TextSource]
    func deleteTextSource(_ sourceId: UUID) async throws
}
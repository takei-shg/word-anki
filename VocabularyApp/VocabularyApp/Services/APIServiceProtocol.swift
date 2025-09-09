import Foundation

protocol APIServiceProtocol {
    func uploadTextSource(_ source: TextSource) async throws -> TextSource
    func fetchWordTests(for sourceId: UUID, difficulty: DifficultyLevel?) async throws -> [WordTest]
    func syncProgress(_ progress: [UserProgress]) async throws
}
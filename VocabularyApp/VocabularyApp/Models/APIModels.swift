import Foundation

// MARK: - API Request Models

struct UploadTextRequest: Codable {
    let title: String
    let content: String
    let userId: String?
    
    init(title: String, content: String, userId: String? = nil) {
        self.title = title
        self.content = content
        self.userId = userId
    }
    
    init(from textSource: TextSource, userId: String? = nil) {
        self.title = textSource.title
        self.content = textSource.content
        self.userId = userId
    }
}

struct SyncProgressRequest: Codable {
    let progress: [UserProgress]
    let userId: String?
    
    init(progress: [UserProgress], userId: String? = nil) {
        self.progress = progress
        self.userId = userId
    }
}

// MARK: - API Response Models

struct UploadTextResponse: Codable {
    let id: UUID
    let title: String
    let status: ProcessingStatus
    let estimatedProcessingTime: TimeInterval?
    let wordCount: Int?
    
    enum ProcessingStatus: String, Codable {
        case queued = "queued"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
    }
}

struct WordTestResponse: Codable {
    let words: [WordTest]
    let totalCount: Int
    let difficultyDistribution: [String: Int]
    let sourceId: UUID
    
    var beginnerCount: Int {
        return difficultyDistribution["beginner"] ?? 0
    }
    
    var intermediateCount: Int {
        return difficultyDistribution["intermediate"] ?? 0
    }
    
    var advancedCount: Int {
        return difficultyDistribution["advanced"] ?? 0
    }
}

struct SyncProgressResponse: Codable {
    let syncedCount: Int
    let failedCount: Int
    let conflicts: [ProgressConflict]?
    
    struct ProgressConflict: Codable {
        let wordId: UUID
        let localProgress: UserProgress
        let serverProgress: UserProgress
        let recommendedResolution: ConflictResolution
        
        enum ConflictResolution: String, Codable {
            case useLocal = "use_local"
            case useServer = "use_server"
            case merge = "merge"
        }
    }
}

struct ProcessingStatusResponse: Codable {
    let sourceId: UUID
    let status: UploadTextResponse.ProcessingStatus
    let progress: Double // 0.0 to 1.0
    let message: String?
    let completedAt: Date?
    let errorMessage: String?
}

// MARK: - API Error Models

struct APIError: Codable, LocalizedError {
    let code: String
    let message: String
    let details: [String: String]?
    
    var errorDescription: String? {
        return message
    }
    
    var failureReason: String? {
        return details?["reason"]
    }
    
    var recoverySuggestion: String? {
        return details?["suggestion"]
    }
}

// MARK: - Pagination Models

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: PaginationInfo
    
    struct PaginationInfo: Codable {
        let currentPage: Int
        let totalPages: Int
        let totalItems: Int
        let itemsPerPage: Int
        let hasNextPage: Bool
        let hasPreviousPage: Bool
    }
}

// MARK: - Filter and Query Models

struct WordTestQuery: Codable {
    let sourceId: UUID?
    let difficulty: DifficultyLevel?
    let limit: Int?
    let offset: Int?
    let includeMemorized: Bool?
    
    init(sourceId: UUID? = nil, 
         difficulty: DifficultyLevel? = nil, 
         limit: Int? = nil, 
         offset: Int? = nil, 
         includeMemorized: Bool? = nil) {
        self.sourceId = sourceId
        self.difficulty = difficulty
        self.limit = limit
        self.offset = offset
        self.includeMemorized = includeMemorized
    }
}

struct TextSourceQuery: Codable {
    let userId: String?
    let includeProcessed: Bool?
    let sortBy: SortOption?
    let sortOrder: SortOrder?
    
    enum SortOption: String, Codable {
        case uploadDate = "upload_date"
        case title = "title"
        case wordCount = "word_count"
        case processedDate = "processed_date"
    }
    
    enum SortOrder: String, Codable {
        case ascending = "asc"
        case descending = "desc"
    }
    
    init(userId: String? = nil, 
         includeProcessed: Bool? = nil, 
         sortBy: SortOption? = nil, 
         sortOrder: SortOrder? = nil) {
        self.userId = userId
        self.includeProcessed = includeProcessed
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
}
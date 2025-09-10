import Foundation

// MARK: - Sync Operation Models

/// Types of sync operations
enum SyncOperationType: String, CaseIterable {
    case progressSync = "progress_sync"
    case textSourceSync = "text_source_sync"
    case textSourceDeletion = "text_source_deletion"
}

/// Sync operation model
struct SyncOperation {
    let id: UUID
    let type: SyncOperationType
    let data: Data?
    let relatedId: UUID?
    let createdDate: Date
    let retryCount: Int32
    let isProcessed: Bool
    let processedDate: Date?
    let lastRetryDate: Date?
    
    init(id: UUID = UUID(), type: SyncOperationType, data: Data? = nil, relatedId: UUID? = nil, createdDate: Date = Date(), retryCount: Int32 = 0, isProcessed: Bool = false, processedDate: Date? = nil, lastRetryDate: Date? = nil) {
        self.id = id
        self.type = type
        self.data = data
        self.relatedId = relatedId
        self.createdDate = createdDate
        self.retryCount = retryCount
        self.isProcessed = isProcessed
        self.processedDate = processedDate
        self.lastRetryDate = lastRetryDate
    }
}

/// Sync operation errors
enum SyncError: Error, LocalizedError {
    case invalidOperationData
    case operationFailed(Error)
    case maxRetriesExceeded
    case queueFull
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidOperationData:
            return "Invalid operation data"
        case .operationFailed(let error):
            return "Operation failed: \(error.localizedDescription)"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .queueFull:
            return "Sync queue is full"
        case .networkUnavailable:
            return "Network is unavailable"
        }
    }
}
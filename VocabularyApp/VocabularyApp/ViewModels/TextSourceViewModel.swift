import Foundation
import SwiftUI

enum TextSourceUploadState {
    case idle
    case uploading
    case processing
    case completed
    case failed(String)
}

@MainActor
class TextSourceViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var textSources: [TextSource] = []
    @Published var isLoading: Bool = false
    @Published var uploadState: TextSourceUploadState = .idle
    @Published var errorMessage: String?
    @Published var selectedSource: TextSource?
    @Published var showingDeleteConfirmation: Bool = false
    @Published var sourceToDelete: TextSource?
    
    // Upload form state
    @Published var uploadTitle: String = ""
    @Published var uploadContent: String = ""
    @Published var isUploadFormValid: Bool = false
    
    // MARK: - Dependencies
    private let storageService: StorageServiceProtocol
    private let apiService: APIServiceProtocol
    
    // MARK: - Initialization
    init(storageService: StorageServiceProtocol, apiService: APIServiceProtocol) {
        self.storageService = storageService
        self.apiService = apiService
        
        Task {
            await loadTextSources()
        }
    }
    
    // MARK: - Text Source Management
    
    func loadTextSources() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let sources = try await storageService.fetchTextSources()
            textSources = sources.sorted { $0.uploadDate > $1.uploadDate }
        } catch {
            errorMessage = "Failed to load text sources: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshTextSources() async {
        await loadTextSources()
    }
    
    func selectSource(_ source: TextSource) {
        selectedSource = source
    }
    
    func clearSelection() {
        selectedSource = nil
    }
    
    // MARK: - Text Upload
    
    func uploadTextSource(title: String, content: String) async -> Bool {
        guard validateUploadInput(title: title, content: content) else {
            return false
        }
        
        uploadState = .uploading
        errorMessage = nil
        
        do {
            // Create text source
            let textSource = TextSource(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                wordCount: estimateWordCount(content)
            )
            
            // Validate the source
            try textSource.validate()
            
            // Save locally first
            try await storageService.saveTextSource(textSource)
            
            // Upload to backend for processing
            uploadState = .processing
            let processedSource = try await apiService.uploadTextSource(textSource)
            
            // Update local storage with processed source
            try await storageService.saveTextSource(processedSource)
            
            // Reload sources
            await loadTextSources()
            
            uploadState = .completed
            clearUploadForm()
            
            return true
            
        } catch let validationError as ValidationError {
            errorMessage = validationError.localizedDescription
            uploadState = .failed(validationError.localizedDescription)
        } catch {
            let message = "Failed to upload text source: \(error.localizedDescription)"
            errorMessage = message
            uploadState = .failed(message)
        }
        
        return false
    }
    
    func uploadTextFromFile(url: URL) async -> Bool {
        do {
            let content = try String(contentsOf: url)
            let title = url.deletingPathExtension().lastPathComponent
            return await uploadTextSource(title: title, content: content)
        } catch {
            let message = "Failed to read file: \(error.localizedDescription)"
            errorMessage = message
            uploadState = .failed(message)
            return false
        }
    }
    
    // MARK: - Text Source Deletion
    
    func requestDeleteSource(_ source: TextSource) {
        sourceToDelete = source
        showingDeleteConfirmation = true
    }
    
    func confirmDeleteSource() async {
        guard let source = sourceToDelete else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await storageService.deleteTextSource(source.id)
            await loadTextSources()
            
            // Clear selection if deleted source was selected
            if selectedSource?.id == source.id {
                selectedSource = nil
            }
        } catch {
            errorMessage = "Failed to delete text source: \(error.localizedDescription)"
        }
        
        isLoading = false
        cancelDeleteSource()
    }
    
    func cancelDeleteSource() {
        sourceToDelete = nil
        showingDeleteConfirmation = false
    }
    
    // MARK: - Upload Form Management
    
    func updateUploadTitle(_ title: String) {
        uploadTitle = title
        validateUploadForm()
    }
    
    func updateUploadContent(_ content: String) {
        uploadContent = content
        validateUploadForm()
    }
    
    func clearUploadForm() {
        uploadTitle = ""
        uploadContent = ""
        isUploadFormValid = false
        uploadState = .idle
    }
    
    private func validateUploadForm() {
        isUploadFormValid = validateUploadInput(title: uploadTitle, content: uploadContent)
    }
    
    private func validateUploadInput(title: String, content: String) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedTitle.isEmpty &&
               !trimmedContent.isEmpty &&
               trimmedContent.count >= 10 &&
               trimmedContent.count <= 100000
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
        if case .failed = uploadState {
            uploadState = .idle
        }
    }
    
    func retryLastOperation() async {
        if case .failed = uploadState {
            await uploadTextSource(title: uploadTitle, content: uploadContent)
        } else {
            await loadTextSources()
        }
    }
    
    // MARK: - Utility Methods
    
    private func estimateWordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    func getSourceStatistics(_ source: TextSource) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var stats = "\(source.wordCount) words"
        if let processedDate = source.processedDate {
            stats += " • Processed \(formatter.string(from: processedDate))"
        } else {
            stats += " • Processing..."
        }
        
        return stats
    }
    
    // MARK: - Computed Properties
    
    var hasTextSources: Bool {
        !textSources.isEmpty
    }
    
    var processedSources: [TextSource] {
        textSources.filter { $0.isProcessed }
    }
    
    var unprocessedSources: [TextSource] {
        textSources.filter { !$0.isProcessed }
    }
    
    var isUploading: Bool {
        if case .uploading = uploadState {
            return true
        }
        if case .processing = uploadState {
            return true
        }
        return false
    }
    
    var uploadStatusMessage: String {
        switch uploadState {
        case .idle:
            return ""
        case .uploading:
            return "Uploading text source..."
        case .processing:
            return "Processing text for vocabulary extraction..."
        case .completed:
            return "Text source uploaded successfully!"
        case .failed(let message):
            return message
        }
    }
}
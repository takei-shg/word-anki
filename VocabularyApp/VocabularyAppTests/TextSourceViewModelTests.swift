import XCTest
@testable import VocabularyApp

@MainActor
final class TextSourceViewModelTests: XCTestCase {
    
    var viewModel: TextSourceViewModel!
    var mockStorageService: MockStorageService!
    var mockAPIService: MockAPIService!
    
    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        mockAPIService = MockAPIService()
        
        viewModel = TextSourceViewModel(
            storageService: mockStorageService,
            apiService: mockAPIService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockStorageService = nil
        mockAPIService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertTrue(viewModel.textSources.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.selectedSource)
        XCTAssertEqual(viewModel.uploadState, .idle)
        XCTAssertFalse(viewModel.isUploadFormValid)
    }
    
    // MARK: - Text Source Loading Tests
    
    func testLoadTextSourcesSuccess() async {
        // Given
        let testSources = [
            TextSource(title: "Source 1", content: "Test content 1"),
            TextSource(title: "Source 2", content: "Test content 2")
        ]
        mockStorageService.textSources = testSources
        
        // When
        await viewModel.loadTextSources()
        
        // Then
        XCTAssertEqual(viewModel.textSources.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadTextSourcesFailure() async {
        // Given
        mockStorageService.shouldThrowError = true
        mockStorageService.error = StorageError.fetchFailed
        
        // When
        await viewModel.loadTextSources()
        
        // Then
        XCTAssertTrue(viewModel.textSources.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testRefreshTextSources() async {
        // Given
        let testSources = [TextSource(title: "Source 1", content: "Test content 1")]
        mockStorageService.textSources = testSources
        
        // When
        await viewModel.refreshTextSources()
        
        // Then
        XCTAssertEqual(viewModel.textSources.count, 1)
        XCTAssertEqual(mockStorageService.fetchTextSourcesCallCount, 2) // Once in init, once in refresh
    }
    
    // MARK: - Source Selection Tests
    
    func testSelectSource() {
        // Given
        let source = TextSource(title: "Test Source", content: "Test content")
        
        // When
        viewModel.selectSource(source)
        
        // Then
        XCTAssertEqual(viewModel.selectedSource?.id, source.id)
    }
    
    func testClearSelection() {
        // Given
        let source = TextSource(title: "Test Source", content: "Test content")
        viewModel.selectSource(source)
        
        // When
        viewModel.clearSelection()
        
        // Then
        XCTAssertNil(viewModel.selectedSource)
    }
    
    // MARK: - Text Upload Tests
    
    func testUploadTextSourceSuccess() async {
        // Given
        let title = "Test Title"
        let content = "This is a test content with more than ten characters"
        mockStorageService.shouldThrowError = false
        mockAPIService.shouldSucceed = true
        
        // When
        let result = await viewModel.uploadTextSource(title: title, content: content)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.uploadState, .completed)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockStorageService.saveTextSourceCallCount, 2) // Once for local save, once for processed
        XCTAssertEqual(mockAPIService.uploadTextSourceCallCount, 1)
    }
    
    func testUploadTextSourceValidationFailure() async {
        // Given
        let title = ""
        let content = "Short"
        
        // When
        let result = await viewModel.uploadTextSource(title: title, content: content)
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockStorageService.saveTextSourceCallCount, 0)
        XCTAssertEqual(mockAPIService.uploadTextSourceCallCount, 0)
    }
    
    func testUploadTextSourceAPIFailure() async {
        // Given
        let title = "Test Title"
        let content = "This is a test content with more than ten characters"
        mockStorageService.shouldThrowError = false
        mockAPIService.shouldSucceed = false
        mockAPIService.error = APIError.networkError
        
        // When
        let result = await viewModel.uploadTextSource(title: title, content: content)
        
        // Then
        XCTAssertFalse(result)
        XCTAssertTrue(viewModel.uploadState == .failed("Failed to upload text source: The operation couldn't be completed. (VocabularyApp.APIError error 0.)"))
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testUploadTextSourceStorageFailure() async {
        // Given
        let title = "Test Title"
        let content = "This is a test content with more than ten characters"
        mockStorageService.shouldThrowError = true
        mockStorageService.error = StorageError.saveFailed
        
        // When
        let result = await viewModel.uploadTextSource(title: title, content: content)
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(mockAPIService.uploadTextSourceCallCount, 0)
    }
    
    // MARK: - Upload Form Management Tests
    
    func testUpdateUploadTitle() {
        // Given
        let title = "Test Title"
        viewModel.updateUploadContent("This is valid content with more than ten characters")
        
        // When
        viewModel.updateUploadTitle(title)
        
        // Then
        XCTAssertEqual(viewModel.uploadTitle, title)
        XCTAssertTrue(viewModel.isUploadFormValid)
    }
    
    func testUpdateUploadContent() {
        // Given
        let content = "This is valid content with more than ten characters"
        viewModel.updateUploadTitle("Test Title")
        
        // When
        viewModel.updateUploadContent(content)
        
        // Then
        XCTAssertEqual(viewModel.uploadContent, content)
        XCTAssertTrue(viewModel.isUploadFormValid)
    }
    
    func testUploadFormValidationInvalidTitle() {
        // Given
        viewModel.updateUploadContent("This is valid content with more than ten characters")
        
        // When
        viewModel.updateUploadTitle("")
        
        // Then
        XCTAssertFalse(viewModel.isUploadFormValid)
    }
    
    func testUploadFormValidationInvalidContent() {
        // Given
        viewModel.updateUploadTitle("Valid Title")
        
        // When
        viewModel.updateUploadContent("Short")
        
        // Then
        XCTAssertFalse(viewModel.isUploadFormValid)
    }
    
    func testClearUploadForm() {
        // Given
        viewModel.updateUploadTitle("Test Title")
        viewModel.updateUploadContent("Test content")
        
        // When
        viewModel.clearUploadForm()
        
        // Then
        XCTAssertEqual(viewModel.uploadTitle, "")
        XCTAssertEqual(viewModel.uploadContent, "")
        XCTAssertFalse(viewModel.isUploadFormValid)
        XCTAssertEqual(viewModel.uploadState, .idle)
    }
    
    // MARK: - Source Deletion Tests
    
    func testRequestDeleteSource() {
        // Given
        let source = TextSource(title: "Test Source", content: "Test content")
        
        // When
        viewModel.requestDeleteSource(source)
        
        // Then
        XCTAssertEqual(viewModel.sourceToDelete?.id, source.id)
        XCTAssertTrue(viewModel.showingDeleteConfirmation)
    }
    
    func testConfirmDeleteSourceSuccess() async {
        // Given
        let source = TextSource(title: "Test Source", content: "Test content")
        viewModel.requestDeleteSource(source)
        mockStorageService.shouldThrowError = false
        
        // When
        await viewModel.confirmDeleteSource()
        
        // Then
        XCTAssertNil(viewModel.sourceToDelete)
        XCTAssertFalse(viewModel.showingDeleteConfirmation)
        XCTAssertEqual(mockStorageService.deleteTextSourceCallCount, 1)
    }
    
    func testConfirmDeleteSourceFailure() async {
        // Given
        let source = TextSource(title: "Test Source", content: "Test content")
        viewModel.requestDeleteSource(source)
        mockStorageService.shouldThrowError = true
        mockStorageService.error = StorageError.deleteFailed
        
        // When
        await viewModel.confirmDeleteSource()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.sourceToDelete)
        XCTAssertFalse(viewModel.showingDeleteConfirmation)
    }
    
    func testCancelDeleteSource() {
        // Given
        let source = TextSource(title: "Test Source", content: "Test content")
        viewModel.requestDeleteSource(source)
        
        // When
        viewModel.cancelDeleteSource()
        
        // Then
        XCTAssertNil(viewModel.sourceToDelete)
        XCTAssertFalse(viewModel.showingDeleteConfirmation)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        // Given
        viewModel.errorMessage = "Test error"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testClearErrorWithFailedUploadState() {
        // Given
        viewModel.uploadState = .failed("Test error")
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertEqual(viewModel.uploadState, .idle)
    }
    
    func testRetryLastOperationWithFailedUpload() async {
        // Given
        viewModel.uploadState = .failed("Test error")
        viewModel.uploadTitle = "Test Title"
        viewModel.uploadContent = "This is valid content with more than ten characters"
        mockStorageService.shouldThrowError = false
        mockAPIService.shouldSucceed = true
        
        // When
        await viewModel.retryLastOperation()
        
        // Then
        XCTAssertEqual(viewModel.uploadState, .completed)
    }
    
    // MARK: - Computed Properties Tests
    
    func testHasTextSources() {
        // Given - empty sources
        XCTAssertFalse(viewModel.hasTextSources)
        
        // When
        viewModel.textSources = [TextSource(title: "Test", content: "Test content")]
        
        // Then
        XCTAssertTrue(viewModel.hasTextSources)
    }
    
    func testProcessedSources() {
        // Given
        let processedSource = TextSource(title: "Processed", content: "Content", processedDate: Date())
        let unprocessedSource = TextSource(title: "Unprocessed", content: "Content")
        viewModel.textSources = [processedSource, unprocessedSource]
        
        // When
        let processed = viewModel.processedSources
        
        // Then
        XCTAssertEqual(processed.count, 1)
        XCTAssertEqual(processed.first?.title, "Processed")
    }
    
    func testUnprocessedSources() {
        // Given
        let processedSource = TextSource(title: "Processed", content: "Content", processedDate: Date())
        let unprocessedSource = TextSource(title: "Unprocessed", content: "Content")
        viewModel.textSources = [processedSource, unprocessedSource]
        
        // When
        let unprocessed = viewModel.unprocessedSources
        
        // Then
        XCTAssertEqual(unprocessed.count, 1)
        XCTAssertEqual(unprocessed.first?.title, "Unprocessed")
    }
    
    func testIsUploading() {
        // Given - idle state
        XCTAssertFalse(viewModel.isUploading)
        
        // When - uploading state
        viewModel.uploadState = .uploading
        XCTAssertTrue(viewModel.isUploading)
        
        // When - processing state
        viewModel.uploadState = .processing
        XCTAssertTrue(viewModel.isUploading)
        
        // When - completed state
        viewModel.uploadState = .completed
        XCTAssertFalse(viewModel.isUploading)
    }
    
    func testUploadStatusMessage() {
        // Test different upload states
        viewModel.uploadState = .idle
        XCTAssertEqual(viewModel.uploadStatusMessage, "")
        
        viewModel.uploadState = .uploading
        XCTAssertEqual(viewModel.uploadStatusMessage, "Uploading text source...")
        
        viewModel.uploadState = .processing
        XCTAssertEqual(viewModel.uploadStatusMessage, "Processing text for vocabulary extraction...")
        
        viewModel.uploadState = .completed
        XCTAssertEqual(viewModel.uploadStatusMessage, "Text source uploaded successfully!")
        
        viewModel.uploadState = .failed("Test error")
        XCTAssertEqual(viewModel.uploadStatusMessage, "Test error")
    }
    
    func testGetSourceStatistics() {
        // Given
        let processedSource = TextSource(
            title: "Test",
            content: "Test content",
            wordCount: 100,
            processedDate: Date()
        )
        let unprocessedSource = TextSource(
            title: "Test",
            content: "Test content",
            wordCount: 50
        )
        
        // When
        let processedStats = viewModel.getSourceStatistics(processedSource)
        let unprocessedStats = viewModel.getSourceStatistics(unprocessedSource)
        
        // Then
        XCTAssertTrue(processedStats.contains("100 words"))
        XCTAssertTrue(processedStats.contains("Processed"))
        XCTAssertTrue(unprocessedStats.contains("50 words"))
        XCTAssertTrue(unprocessedStats.contains("Processing..."))
    }
}

// MARK: - TextSourceUploadState Tests

final class TextSourceUploadStateTests: XCTestCase {
    
    func testUploadStateEquality() {
        XCTAssertEqual(TextSourceUploadState.idle, TextSourceUploadState.idle)
        XCTAssertEqual(TextSourceUploadState.uploading, TextSourceUploadState.uploading)
        XCTAssertEqual(TextSourceUploadState.processing, TextSourceUploadState.processing)
        XCTAssertEqual(TextSourceUploadState.completed, TextSourceUploadState.completed)
        
        // Note: .failed cases with different messages are not equal
        XCTAssertNotEqual(TextSourceUploadState.failed("Error 1"), TextSourceUploadState.failed("Error 2"))
    }
}
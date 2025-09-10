import XCTest
@testable import VocabularyApp

@MainActor
final class MainViewModelTests: XCTestCase {
    
    var viewModel: MainViewModel!
    var mockStorageService: MockStorageService!
    var mockAPIService: MockAPIService!
    var mockProgressService: MockProgressTrackingService!
    
    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        mockAPIService = MockAPIService()
        mockProgressService = MockProgressTrackingService()
        
        viewModel = MainViewModel(
            storageService: mockStorageService,
            apiService: mockAPIService,
            progressTrackingService: mockProgressService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockStorageService = nil
        mockAPIService = nil
        mockProgressService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(viewModel.selectedTab, .home)
        XCTAssertFalse(viewModel.isSessionActive)
        XCTAssertNil(viewModel.currentSessionSourceId)
        XCTAssertFalse(viewModel.showingAlert)
    }
    
    func testAppInitialization() async {
        // Given
        mockAPIService.shouldSucceed = true
        
        // When
        await viewModel.initializeApp()
        
        // Then
        XCTAssertEqual(viewModel.appState, .ready)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasError)
    }
    
    func testAppInitializationFailure() async {
        // Given
        mockAPIService.shouldSucceed = false
        mockAPIService.error = APIError.networkError
        
        // When
        await viewModel.initializeApp()
        
        // Then
        XCTAssertTrue(viewModel.hasError)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Navigation Tests
    
    func testTabSelection() {
        // When
        viewModel.selectTab(.study)
        
        // Then
        XCTAssertEqual(viewModel.selectedTab, .study)
    }
    
    func testNavigateToStudy() {
        // Given
        let sourceId = UUID()
        
        // When
        viewModel.navigateToStudy(sourceId: sourceId)
        
        // Then
        XCTAssertEqual(viewModel.selectedTab, .study)
        XCTAssertEqual(viewModel.currentSessionSourceId, sourceId)
    }
    
    func testNavigateToProgress() {
        // When
        viewModel.navigateToProgress()
        
        // Then
        XCTAssertEqual(viewModel.selectedTab, .progress)
    }
    
    func testResetNavigation() {
        // Given
        viewModel.navigationPath.append("test")
        
        // When
        viewModel.resetNavigation()
        
        // Then
        XCTAssertTrue(viewModel.navigationPath.isEmpty)
    }
    
    // MARK: - Session Management Tests
    
    func testStartSession() {
        // Given
        let sourceId = UUID()
        
        // When
        viewModel.startSession(sourceId: sourceId)
        
        // Then
        XCTAssertTrue(viewModel.isSessionActive)
        XCTAssertEqual(viewModel.currentSessionSourceId, sourceId)
    }
    
    func testEndSession() {
        // Given
        let sourceId = UUID()
        viewModel.startSession(sourceId: sourceId)
        
        // When
        viewModel.endSession()
        
        // Then
        XCTAssertFalse(viewModel.isSessionActive)
        XCTAssertNil(viewModel.currentSessionSourceId)
    }
    
    func testResumeSessionWhenNoSessionExists() async {
        // When
        let hasSession = await viewModel.resumeSession()
        
        // Then
        XCTAssertFalse(hasSession)
    }
    
    // MARK: - Error Handling Tests
    
    func testShowError() {
        // Given
        let errorMessage = "Test error message"
        
        // When
        viewModel.showError(errorMessage)
        
        // Then
        XCTAssertTrue(viewModel.showingAlert)
        XCTAssertEqual(viewModel.alertMessage, errorMessage)
        XCTAssertTrue(viewModel.hasError)
        XCTAssertEqual(viewModel.errorMessage, errorMessage)
    }
    
    func testClearError() {
        // Given
        viewModel.showError("Test error")
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertFalse(viewModel.showingAlert)
        XCTAssertEqual(viewModel.alertMessage, "")
        XCTAssertFalse(viewModel.hasError)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testHandleError() {
        // Given
        let error = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When
        viewModel.handleError(error)
        
        // Then
        XCTAssertTrue(viewModel.showingAlert)
        XCTAssertEqual(viewModel.alertMessage, "Test error")
        XCTAssertTrue(viewModel.hasError)
    }
    
    // MARK: - Network Management Tests
    
    func testNetworkConnectivityCheck() async {
        // Given
        mockAPIService.shouldSucceed = true
        
        // When
        await viewModel.retryNetworkOperation()
        
        // Then
        XCTAssertTrue(viewModel.isNetworkAvailable)
    }
    
    func testNetworkConnectivityFailure() async {
        // Given
        mockAPIService.shouldSucceed = false
        mockAPIService.error = APIError.networkError
        
        // When
        await viewModel.retryNetworkOperation()
        
        // Then
        XCTAssertFalse(viewModel.isNetworkAvailable)
    }
    
    // MARK: - App Lifecycle Tests
    
    func testHandleAppDidBecomeActive() async {
        // Given
        mockAPIService.shouldSucceed = true
        
        // When
        viewModel.handleAppDidBecomeActive()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(viewModel.isNetworkAvailable)
    }
    
    func testHandleAppWillResignActive() async {
        // Given
        let sourceId = UUID()
        viewModel.startSession(sourceId: sourceId)
        
        // When
        viewModel.handleAppWillResignActive()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - session should still be active (saved, not ended)
        XCTAssertTrue(viewModel.isSessionActive)
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsLoadingWhenAppStateIsLoading() {
        // Given
        viewModel.appState = .loading
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testIsLoadingWhenAppStateIsReady() {
        // Given
        viewModel.appState = .ready
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHasErrorWhenAppStateIsError() {
        // Given
        viewModel.appState = .error("Test error")
        
        // Then
        XCTAssertTrue(viewModel.hasError)
        XCTAssertEqual(viewModel.errorMessage, "Test error")
    }
    
    func testHasErrorWhenAppStateIsReady() {
        // Given
        viewModel.appState = .ready
        
        // Then
        XCTAssertFalse(viewModel.hasError)
        XCTAssertNil(viewModel.errorMessage)
    }
}

// MARK: - AppTab Tests

final class AppTabTests: XCTestCase {
    
    func testAppTabTitles() {
        XCTAssertEqual(AppTab.home.title, "Home")
        XCTAssertEqual(AppTab.study.title, "Study")
        XCTAssertEqual(AppTab.progress.title, "Progress")
    }
    
    func testAppTabSystemImages() {
        XCTAssertEqual(AppTab.home.systemImage, "house")
        XCTAssertEqual(AppTab.study.systemImage, "book")
        XCTAssertEqual(AppTab.progress.systemImage, "chart.bar")
    }
    
    func testAppTabRawValues() {
        XCTAssertEqual(AppTab.home.rawValue, 0)
        XCTAssertEqual(AppTab.study.rawValue, 1)
        XCTAssertEqual(AppTab.progress.rawValue, 2)
    }
    
    func testAppTabCaseIterable() {
        let allTabs = AppTab.allCases
        XCTAssertEqual(allTabs.count, 3)
        XCTAssertTrue(allTabs.contains(.home))
        XCTAssertTrue(allTabs.contains(.study))
        XCTAssertTrue(allTabs.contains(.progress))
    }
}
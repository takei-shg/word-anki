import XCTest
@testable import VocabularyApp

class APIServiceIntegrationTests: XCTestCase {
    
    var apiService: APIService!
    
    override func setUp() {
        super.setUp()
        
        // Use development configuration for integration tests
        let config = APIConfiguration.development
        apiService = APIService(configuration: config)
    }
    
    override func tearDown() {
        apiService = nil
        super.tearDown()
    }
    
    // MARK: - Integration Tests with Mock API
    
    func testIntegrationWithMockAPI() async throws {
        // This test requires the mock API server to be running
        // Run: npm start in the mock-api directory
        
        // Test network connectivity first
        let isConnected = await apiService.checkNetworkConnectivity()
        
        if !isConnected {
            throw XCTSkip("Mock API server is not running. Start with 'npm start' in mock-api directory.")
        }
        
        // Test fetching text sources
        let textSources = try await apiService.fetchTextSources()
        XCTAssertGreaterThan(textSources.count, 0, "Should have at least one text source from mock data")
        
        // Test fetching word tests for the first source
        if let firstSource = textSources.first {
            let wordTests = try await apiService.fetchWordTests(for: firstSource.id, difficulty: nil)
            XCTAssertGreaterThan(wordTests.count, 0, "Should have word tests for the first source")
            
            // Test fetching word tests with difficulty filter
            let beginnerWords = try await apiService.fetchWordTests(for: firstSource.id, difficulty: .beginner)
            let intermediateWords = try await apiService.fetchWordTests(for: firstSource.id, difficulty: .intermediate)
            let advancedWords = try await apiService.fetchWordTests(for: firstSource.id, difficulty: .advanced)
            
            XCTAssertTrue(beginnerWords.allSatisfy { $0.difficultyLevel == .beginner }, "All beginner words should have beginner difficulty")
            XCTAssertTrue(intermediateWords.allSatisfy { $0.difficultyLevel == .intermediate }, "All intermediate words should have intermediate difficulty")
            XCTAssertTrue(advancedWords.allSatisfy { $0.difficultyLevel == .advanced }, "All advanced words should have advanced difficulty")
        }
    }
    
    func testUploadTextSourceIntegration() async throws {
        // This test requires the mock API server to be running
        let isConnected = await apiService.checkNetworkConnectivity()
        
        if !isConnected {
            throw XCTSkip("Mock API server is not running. Start with 'npm start' in mock-api directory.")
        }
        
        // Create a test text source
        let testSource = TextSource(
            title: "Integration Test Source",
            content: "This is a test content for integration testing. It contains various words that should be processed by the backend system for vocabulary learning purposes."
        )
        
        // Upload the text source
        let uploadedSource = try await apiService.uploadTextSource(testSource)
        
        // Verify the response
        XCTAssertEqual(uploadedSource.title, testSource.title)
        XCTAssertEqual(uploadedSource.content, testSource.content)
        XCTAssertNotNil(uploadedSource.id)
        
        // Clean up - delete the uploaded source
        try await apiService.deleteTextSource(id: uploadedSource.id)
    }
    
    func testProgressSyncIntegration() async throws {
        // This test requires the mock API server to be running
        let isConnected = await apiService.checkNetworkConnectivity()
        
        if !isConnected {
            throw XCTSkip("Mock API server is not running. Start with 'npm start' in mock-api directory.")
        }
        
        // Create test progress data
        let testProgress = [
            UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1),
            UserProgress(wordId: UUID(), isMemorized: false, reviewCount: 2),
            UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 3)
        ]
        
        // Sync progress
        try await apiService.syncProgress(testProgress)
        
        // If we reach here without throwing, the sync was successful
        XCTAssertTrue(true, "Progress sync completed successfully")
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testNetworkErrorHandling() async {
        // Test with invalid configuration to simulate network errors
        let invalidConfig = APIConfiguration(
            baseURL: URL(string: "http://invalid-url-that-does-not-exist.com/api")!,
            timeout: 5.0,
            maxRetryAttempts: 2,
            retryDelay: 0.1
        )
        
        let invalidAPIService = APIService(configuration: invalidConfig)
        
        do {
            _ = try await invalidAPIService.fetchTextSources()
            XCTFail("Expected network error to be thrown")
        } catch {
            // Expected to fail with network error
            XCTAssertTrue(error is URLError || error is APIServiceError)
        }
    }
    
    func testTimeoutHandling() async {
        // Test with very short timeout
        let timeoutConfig = APIConfiguration(
            baseURL: URL(string: "http://httpbin.org/delay/10")!, // This will delay for 10 seconds
            timeout: 1.0, // But we timeout after 1 second
            maxRetryAttempts: 1,
            retryDelay: 0.1
        )
        
        let timeoutAPIService = APIService(configuration: timeoutConfig)
        
        do {
            _ = try await timeoutAPIService.fetchTextSources()
            XCTFail("Expected timeout error to be thrown")
        } catch {
            // Expected to fail with timeout error
            XCTAssertTrue(error is URLError)
            if let urlError = error as? URLError {
                XCTAssertEqual(urlError.code, .timedOut)
            }
        }
    }
}

// MARK: - Performance Tests

extension APIServiceIntegrationTests {
    
    func testAPIPerformance() throws {
        // This test requires the mock API server to be running
        let expectation = XCTestExpectation(description: "API performance test")
        
        Task {
            let isConnected = await apiService.checkNetworkConnectivity()
            
            if !isConnected {
                expectation.fulfill()
                return
            }
            
            // Measure performance of fetching text sources
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                _ = try await apiService.fetchTextSources()
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                // API call should complete within reasonable time (2 seconds for local mock API)
                XCTAssertLessThan(timeElapsed, 2.0, "API call took too long: \(timeElapsed) seconds")
                
            } catch {
                XCTFail("API call failed: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
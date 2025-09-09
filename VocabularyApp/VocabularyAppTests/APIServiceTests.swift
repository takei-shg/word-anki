import XCTest
@testable import VocabularyApp

class APIServiceTests: XCTestCase {
    
    var apiService: APIService!
    var mockSession: MockURLSession!
    var testConfiguration: APIConfiguration!
    
    override func setUp() {
        super.setUp()
        
        testConfiguration = APIConfiguration(
            baseURL: URL(string: "http://localhost:3000/api")!,
            timeout: 10.0,
            maxRetryAttempts: 2,
            retryDelay: 0.1
        )
        
        mockSession = MockURLSession()
        apiService = APIService(configuration: testConfiguration, session: mockSession)
    }
    
    override func tearDown() {
        apiService = nil
        mockSession = nil
        testConfiguration = nil
        super.tearDown()
    }
    
    // MARK: - Upload Text Source Tests
    
    func testUploadTextSourceSuccess() async throws {
        // Given
        let textSource = TextSource(
            id: UUID(),
            title: "Test Source",
            content: "This is test content for vocabulary learning.",
            uploadDate: Date(),
            wordCount: 8
        )
        
        let expectedResponse = textSource
        let responseData = try JSONEncoder().encode(expectedResponse)
        
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await apiService.uploadTextSource(textSource)
        
        // Then
        XCTAssertEqual(result.id, textSource.id)
        XCTAssertEqual(result.title, textSource.title)
        XCTAssertEqual(result.content, textSource.content)
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertTrue(mockSession.lastRequest?.url?.absoluteString.contains("/text-sources") ?? false)
    }
    
    func testUploadTextSourceNetworkError() async {
        // Given
        let textSource = TextSource(
            title: "Test Source",
            content: "Test content"
        )
        
        mockSession.mockError = URLError(.notConnectedToInternet)
        
        // When/Then
        do {
            _ = try await apiService.uploadTextSource(textSource)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testUploadTextSourceHTTPError() async {
        // Given
        let textSource = TextSource(
            title: "Test Source",
            content: "Test content"
        )
        
        let apiError = APIError(
            code: "INVALID_CONTENT",
            message: "Content is too short",
            details: ["minimum_length": "10"]
        )
        
        let errorData = try! JSONEncoder().encode(apiError)
        
        mockSession.mockData = errorData
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        do {
            _ = try await apiService.uploadTextSource(textSource)
            XCTFail("Expected error to be thrown")
        } catch APIServiceError.httpError(let statusCode, let error) {
            XCTAssertEqual(statusCode, 400)
            XCTAssertEqual(error?.code, "INVALID_CONTENT")
            XCTAssertEqual(error?.message, "Content is too short")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Fetch Word Tests Tests
    
    func testFetchWordTestsSuccess() async throws {
        // Given
        let sourceId = UUID()
        let wordTests = [
            WordTest(
                id: UUID(),
                word: "test",
                sentence: "This is a test sentence.",
                meaning: "A procedure to assess something",
                difficultyLevel: .beginner,
                sourceId: sourceId
            ),
            WordTest(
                id: UUID(),
                word: "vocabulary",
                sentence: "Building vocabulary is important.",
                meaning: "A body of words used in a language",
                difficultyLevel: .intermediate,
                sourceId: sourceId
            )
        ]
        
        let responseData = try JSONEncoder().encode(wordTests)
        
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await apiService.fetchWordTests(for: sourceId, difficulty: nil)
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].word, "test")
        XCTAssertEqual(result[1].word, "vocabulary")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "GET")
        XCTAssertTrue(mockSession.lastRequest?.url?.absoluteString.contains(sourceId.uuidString) ?? false)
    }
    
    func testFetchWordTestsWithDifficulty() async throws {
        // Given
        let sourceId = UUID()
        let difficulty = DifficultyLevel.intermediate
        let wordTests = [
            WordTest(
                id: UUID(),
                word: "vocabulary",
                sentence: "Building vocabulary is important.",
                meaning: "A body of words used in a language",
                difficultyLevel: .intermediate,
                sourceId: sourceId
            )
        ]
        
        let responseData = try JSONEncoder().encode(wordTests)
        
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await apiService.fetchWordTests(for: sourceId, difficulty: difficulty)
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].difficultyLevel, .intermediate)
        XCTAssertTrue(mockSession.lastRequest?.url?.absoluteString.contains("intermediate") ?? false)
    }
    
    func testFetchWordTestsEmptyResponse() async throws {
        // Given
        let sourceId = UUID()
        let emptyWordTests: [WordTest] = []
        
        let responseData = try JSONEncoder().encode(emptyWordTests)
        
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await apiService.fetchWordTests(for: sourceId, difficulty: nil)
        
        // Then
        XCTAssertEqual(result.count, 0)
    }
    
    // MARK: - Sync Progress Tests
    
    func testSyncProgressSuccess() async throws {
        // Given
        let progress = [
            UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1),
            UserProgress(wordId: UUID(), isMemorized: false, reviewCount: 2)
        ]
        
        let syncResponse = SyncProgressResponse(
            syncedCount: 2,
            failedCount: 0,
            conflicts: nil
        )
        
        let responseData = try JSONEncoder().encode(syncResponse)
        
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        try await apiService.syncProgress(progress)
        
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertTrue(mockSession.lastRequest?.url?.absoluteString.contains("/sync/progress") ?? false)
    }
    
    func testSyncProgressWithConflicts() async throws {
        // Given
        let progress = [
            UserProgress(wordId: UUID(), isMemorized: true, reviewCount: 1)
        ]
        
        let conflict = SyncProgressResponse.ProgressConflict(
            wordId: progress[0].wordId,
            localProgress: progress[0],
            serverProgress: UserProgress(wordId: progress[0].wordId, isMemorized: false, reviewCount: 3),
            recommendedResolution: .useServer
        )
        
        let syncResponse = SyncProgressResponse(
            syncedCount: 0,
            failedCount: 1,
            conflicts: [conflict]
        )
        
        let responseData = try JSONEncoder().encode(syncResponse)
        
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then
        try await apiService.syncProgress(progress)
        
        // The method should complete successfully even with conflicts
        // Conflict resolution would be handled by the calling code
    }
    
    // MARK: - Retry Logic Tests
    
    func testRetryOnServerError() async {
        // Given
        let textSource = TextSource(title: "Test", content: "Test content")
        
        // First attempt fails with 500
        mockSession.mockResponses = [
            HTTPURLResponse(
                url: testConfiguration.baseURL,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!,
            HTTPURLResponse(
                url: testConfiguration.baseURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        ]
        
        let successData = try! JSONEncoder().encode(textSource)
        mockSession.mockDataResponses = [Data(), successData]
        
        // When
        let result = try! await apiService.uploadTextSource(textSource)
        
        // Then
        XCTAssertEqual(result.title, textSource.title)
        XCTAssertEqual(mockSession.requestCount, 2) // Should have retried once
    }
    
    func testNoRetryOnClientError() async {
        // Given
        let textSource = TextSource(title: "Test", content: "Test content")
        
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )
        
        let apiError = APIError(code: "BAD_REQUEST", message: "Invalid request", details: nil)
        mockSession.mockData = try! JSONEncoder().encode(apiError)
        
        // When/Then
        do {
            _ = try await apiService.uploadTextSource(textSource)
            XCTFail("Expected error to be thrown")
        } catch APIServiceError.httpError(let statusCode, _) {
            XCTAssertEqual(statusCode, 400)
            XCTAssertEqual(mockSession.requestCount, 1) // Should not have retried
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Network Connectivity Tests
    
    func testCheckNetworkConnectivitySuccess() async {
        // Given
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL.appendingPathComponent("/health"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockData = Data()
        
        // When
        let isConnected = await apiService.checkNetworkConnectivity()
        
        // Then
        XCTAssertTrue(isConnected)
    }
    
    func testCheckNetworkConnectivityFailure() async {
        // Given
        mockSession.mockError = URLError(.notConnectedToInternet)
        
        // When
        let isConnected = await apiService.checkNetworkConnectivity()
        
        // Then
        XCTAssertFalse(isConnected)
    }
    
    // MARK: - Additional API Methods Tests
    
    func testFetchTextSourcesSuccess() async throws {
        // Given
        let textSources = [
            TextSource(title: "Source 1", content: "Content 1"),
            TextSource(title: "Source 2", content: "Content 2")
        ]
        
        let responseData = try JSONEncoder().encode(textSources)
        
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result = try await apiService.fetchTextSources()
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].title, "Source 1")
        XCTAssertEqual(result[1].title, "Source 2")
    }
    
    func testDeleteTextSourceSuccess() async throws {
        // Given
        let sourceId = UUID()
        
        mockSession.mockResponse = HTTPURLResponse(
            url: testConfiguration.baseURL,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockData = Data()
        
        // When/Then
        try await apiService.deleteTextSource(id: sourceId)
        
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "DELETE")
        XCTAssertTrue(mockSession.lastRequest?.url?.absoluteString.contains(sourceId.uuidString) ?? false)
    }
}

// MARK: - Mock URL Session

class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var mockDataResponses: [Data] = []
    var mockResponses: [HTTPURLResponse] = []
    var requestCount = 0
    var lastRequest: URLRequest?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        requestCount += 1
        
        if let error = mockError {
            throw error
        }
        
        let data: Data
        let response: URLResponse
        
        if !mockDataResponses.isEmpty && !mockResponses.isEmpty {
            // Use sequential responses for retry testing
            let index = min(requestCount - 1, mockDataResponses.count - 1)
            data = mockDataResponses[index]
            response = mockResponses[index]
        } else {
            data = mockData ?? Data()
            response = mockResponse ?? HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        }
        
        return (data, response)
    }
}
import XCTest
import CoreData
@testable import VocabularyApp

class PersistenceControllerTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        persistenceController = PersistenceController(inMemory: true)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        try super.tearDownWithError()
    }
    
    func testInMemoryPersistenceController() throws {
        // Test that the in-memory persistence controller is properly initialized
        XCTAssertNotNil(persistenceController.container)
        XCTAssertNotNil(persistenceController.viewContext)
        XCTAssertNotNil(persistenceController.backgroundContext)
        
        // Test that view context and background context are different
        XCTAssertNotEqual(persistenceController.viewContext, persistenceController.backgroundContext)
    }
    
    func testSaveOperation() throws {
        let context = persistenceController.viewContext
        
        // Create a test entity
        let textSource = TextSourceEntity(context: context)
        textSource.id = UUID()
        textSource.title = "Test Save"
        textSource.content = "Test content for save operation"
        textSource.uploadDate = Date()
        textSource.wordCount = 5
        textSource.isProcessed = false
        
        // Test save operation
        XCTAssertNoThrow(try persistenceController.save())
        
        // Verify the entity was saved
        let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
        let results = try context.fetch(request)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Test Save")
    }
    
    func testBackgroundContextSave() async throws {
        let expectation = XCTestExpectation(description: "Background save completed")
        
        try await persistenceController.performBackgroundTask { context in
            let textSource = TextSourceEntity(context: context)
            textSource.id = UUID()
            textSource.title = "Background Test"
            textSource.content = "Test content for background save"
            textSource.uploadDate = Date()
            textSource.wordCount = 3
            textSource.isProcessed = false
            
            try self.persistenceController.saveBackground(context)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Verify the entity was saved by checking in view context
        let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
        let results = try persistenceController.viewContext.fetch(request)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Background Test")
    }
    
    func testEntityRelationships() throws {
        let context = persistenceController.viewContext
        
        // Create a text source
        let textSource = TextSourceEntity(context: context)
        textSource.id = UUID()
        textSource.title = "Relationship Test"
        textSource.content = "Test content for relationships"
        textSource.uploadDate = Date()
        textSource.wordCount = 1
        textSource.isProcessed = true
        
        // Create a word test related to the text source
        let wordTest = WordTestEntity(context: context)
        wordTest.id = UUID()
        wordTest.word = "relationship"
        wordTest.sentence = "This tests the relationship."
        wordTest.meaning = "A connection between entities"
        wordTest.difficultyLevel = DifficultyLevel.intermediate.rawValue
        wordTest.sourceId = textSource.id
        wordTest.source = textSource
        wordTest.createdDate = Date()
        wordTest.isDownloaded = true
        
        try persistenceController.save()
        
        // Verify the relationship
        XCTAssertEqual(textSource.wordTests?.count, 1)
        XCTAssertEqual(wordTest.source, textSource)
        
        // Test cascade delete
        context.delete(textSource)
        try persistenceController.save()
        
        // Verify cascade delete worked
        let wordTestRequest: NSFetchRequest<WordTestEntity> = WordTestEntity.fetchRequest()
        let remainingWordTests = try context.fetch(wordTestRequest)
        XCTAssertEqual(remainingWordTests.count, 0)
    }
    
    func testCoreDataModelValidation() throws {
        let context = persistenceController.viewContext
        
        // Test TextSourceEntity validation
        let textSource = TextSourceEntity(context: context)
        textSource.id = UUID()
        textSource.title = "Validation Test"
        textSource.content = "Test content"
        textSource.uploadDate = Date()
        textSource.wordCount = 1
        textSource.isProcessed = false
        
        XCTAssertNoThrow(try context.save())
        
        // Test WordTestEntity validation
        let wordTest = WordTestEntity(context: context)
        wordTest.id = UUID()
        wordTest.word = "validate"
        wordTest.sentence = "This validates the model."
        wordTest.meaning = "To check for correctness"
        wordTest.difficultyLevel = DifficultyLevel.beginner.rawValue
        wordTest.sourceId = textSource.id
        wordTest.source = textSource
        wordTest.createdDate = Date()
        wordTest.isDownloaded = true
        
        XCTAssertNoThrow(try context.save())
        
        // Test UserProgressEntity validation
        let userProgress = UserProgressEntity(context: context)
        userProgress.id = UUID()
        userProgress.wordId = wordTest.id
        userProgress.isMemorized = false
        userProgress.reviewCount = 1
        userProgress.lastReviewed = Date()
        userProgress.isSynced = false
        
        XCTAssertNoThrow(try context.save())
    }
    
    func testPreviewPersistenceController() throws {
        let previewController = PersistenceController.preview
        
        XCTAssertNotNil(previewController.container)
        XCTAssertNotNil(previewController.viewContext)
        
        // Verify sample data exists
        let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
        let results = try previewController.viewContext.fetch(request)
        
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertEqual(results.first?.title, "Sample Text")
    }
    
    func testMigrationCheck() throws {
        // Test migration requirement check
        let requiresMigration = persistenceController.requiresMigration()
        
        // For in-memory store, this should return false
        XCTAssertFalse(requiresMigration)
    }
    
    func testConcurrentAccess() async throws {
        let expectation1 = XCTestExpectation(description: "First concurrent operation")
        let expectation2 = XCTestExpectation(description: "Second concurrent operation")
        
        // Perform concurrent operations
        Task {
            try await persistenceController.performBackgroundTask { context in
                let textSource = TextSourceEntity(context: context)
                textSource.id = UUID()
                textSource.title = "Concurrent Test 1"
                textSource.content = "First concurrent operation"
                textSource.uploadDate = Date()
                textSource.wordCount = 1
                textSource.isProcessed = false
                
                try self.persistenceController.saveBackground(context)
                expectation1.fulfill()
            }
        }
        
        Task {
            try await persistenceController.performBackgroundTask { context in
                let textSource = TextSourceEntity(context: context)
                textSource.id = UUID()
                textSource.title = "Concurrent Test 2"
                textSource.content = "Second concurrent operation"
                textSource.uploadDate = Date()
                textSource.wordCount = 1
                textSource.isProcessed = false
                
                try self.persistenceController.saveBackground(context)
                expectation2.fulfill()
            }
        }
        
        await fulfillment(of: [expectation1, expectation2], timeout: 10.0)
        
        // Verify both operations completed successfully
        let request: NSFetchRequest<TextSourceEntity> = TextSourceEntity.fetchRequest()
        let results = try persistenceController.viewContext.fetch(request)
        
        XCTAssertEqual(results.count, 2)
        
        let titles = results.compactMap { $0.title }
        XCTAssertTrue(titles.contains("Concurrent Test 1"))
        XCTAssertTrue(titles.contains("Concurrent Test 2"))
    }
}
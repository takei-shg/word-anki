import CoreData
import os.log

enum PersistenceError: Error, LocalizedError {
    case failedToLoadStore(Error)
    case failedToSave(Error)
    case entityNotFound
    case invalidData
    case migrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadStore(let error):
            return "Failed to load persistent store: \(error.localizedDescription)"
        case .failedToSave(let error):
            return "Failed to save context: \(error.localizedDescription)"
        case .entityNotFound:
            return "Entity not found"
        case .invalidData:
            return "Invalid data provided"
        case .migrationFailed(let error):
            return "Data migration failed: \(error.localizedDescription)"
        }
    }
}

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    static let inMemory: PersistenceController = {
        return PersistenceController(inMemory: true)
    }()
    
    private let logger = Logger(subsystem: "com.vocabularyapp", category: "persistence")

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleSource = TextSourceEntity(context: viewContext)
        sampleSource.id = UUID()
        sampleSource.title = "Sample Text"
        sampleSource.content = "This is a sample text for vocabulary learning."
        sampleSource.uploadDate = Date()
        sampleSource.wordCount = 10
        sampleSource.isProcessed = true
        sampleSource.processedDate = Date()
        
        let sampleWord = WordTestEntity(context: viewContext)
        sampleWord.id = UUID()
        sampleWord.word = "sample"
        sampleWord.sentence = "This is a sample sentence."
        sampleWord.meaning = "An example or specimen"
        sampleWord.difficultyLevel = DifficultyLevel.beginner.rawValue
        sampleWord.sourceId = sampleSource.id
        sampleWord.source = sampleSource
        sampleWord.createdDate = Date()
        sampleWord.isDownloaded = true
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "VocabularyApp")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure persistent store for production
            guard let storeDescription = container.persistentStoreDescriptions.first else {
                fatalError("No store description found")
            }
            
            // Enable automatic lightweight migration
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            
            // Enable persistent history tracking
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error {
                self?.logger.error("Failed to load store: \(error.localizedDescription)")
                // In production, you might want to handle this more gracefully
                fatalError("Unresolved error \(error)")
            }
            
            self?.logger.info("Successfully loaded persistent store: \(storeDescription.url?.absoluteString ?? "unknown")")
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up remote change notifications
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            self?.logger.info("Remote store change detected")
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Save Operations
    
    func save() throws {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                logger.info("Successfully saved view context")
            } catch {
                logger.error("Failed to save view context: \(error.localizedDescription)")
                throw PersistenceError.failedToSave(error)
            }
        }
    }
    
    func saveBackground(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            do {
                try context.save()
                logger.info("Successfully saved background context")
            } catch {
                logger.error("Failed to save background context: \(error.localizedDescription)")
                throw PersistenceError.failedToSave(error)
            }
        }
    }
    
    // MARK: - Batch Operations
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Migration Support
    
    func requiresMigration() -> Bool {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            return !container.managedObjectModel.isConfiguration(
                withName: nil,
                compatibleWithStoreMetadata: metadata
            )
        } catch {
            logger.error("Failed to check migration requirement: \(error.localizedDescription)")
            return false
        }
    }
}
import Foundation
import CoreData

// MARK: - Model Validation Utilities

struct ModelValidator {
    
    static func validateTextSource(_ source: TextSource) -> ValidationResult {
        do {
            try source.validate()
            return .success
        } catch let error as ValidationError {
            return .failure(error)
        } catch {
            return .failure(ValidationError.emptyContent)
        }
    }
    
    static func validateWordTest(_ wordTest: WordTest) -> ValidationResult {
        do {
            try wordTest.validate()
            return .success
        } catch let error as ValidationError {
            return .failure(error)
        } catch {
            return .failure(ValidationError.emptyWord)
        }
    }
    
    static func validateUserProgress(_ progress: UserProgress) -> ValidationResult {
        do {
            try progress.validate()
            return .success
        } catch let error as ValidationError {
            return .failure(error)
        } catch {
            return .failure(ValidationError.invalidReviewCount)
        }
    }
    
    static func validateBatch<T>(_ items: [T], validator: (T) -> ValidationResult) -> BatchValidationResult {
        var validItems: [T] = []
        var errors: [(Int, ValidationError)] = []
        
        for (index, item) in items.enumerated() {
            switch validator(item) {
            case .success:
                validItems.append(item)
            case .failure(let error):
                errors.append((index, error))
            }
        }
        
        return BatchValidationResult(validItems: validItems, errors: errors)
    }
}

enum ValidationResult {
    case success
    case failure(ValidationError)
    
    var isValid: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var error: ValidationError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

struct BatchValidationResult {
    let validItems: [Any]
    let errors: [(Int, ValidationError)]
    
    var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    var errorCount: Int {
        return errors.count
    }
    
    var validCount: Int {
        return validItems.count
    }
}

// MARK: - Core Data Utilities

struct CoreDataUtilities {
    
    static func fetchRequest<T: NSManagedObject>(for entityType: T.Type) -> NSFetchRequest<T> {
        let entityName = String(describing: entityType)
        return NSFetchRequest<T>(entityName: entityName)
    }
    
    static func count<T: NSManagedObject>(for entityType: T.Type, in context: NSManagedObjectContext) throws -> Int {
        let request = fetchRequest(for: entityType)
        return try context.count(for: request)
    }
    
    static func deleteAll<T: NSManagedObject>(of entityType: T.Type, in context: NSManagedObjectContext) throws {
        let request = fetchRequest(for: entityType)
        let objects = try context.fetch(request)
        
        for object in objects {
            context.delete(object)
        }
    }
    
    static func batchDelete<T: NSManagedObject>(of entityType: T.Type, 
                                               predicate: NSPredicate? = nil, 
                                               in context: NSManagedObjectContext) throws {
        let request = fetchRequest(for: entityType)
        request.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
        
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
}

// MARK: - Model Factory

struct ModelFactory {
    
    static func createSampleTextSource(title: String = "Sample Text", 
                                     content: String = "This is a sample text with some vocabulary words to learn.") -> TextSource {
        return TextSource(
            title: title,
            content: content,
            wordCount: content.components(separatedBy: .whitespacesAndNewlines).count
        )
    }
    
    static func createSampleWordTest(word: String = "vocabulary", 
                                   sentence: String = "Learning vocabulary is important.", 
                                   meaning: String = "A collection of words", 
                                   difficulty: DifficultyLevel = .beginner,
                                   sourceId: UUID = UUID()) -> WordTest {
        return WordTest(
            word: word,
            sentence: sentence,
            meaning: meaning,
            difficultyLevel: difficulty,
            sourceId: sourceId
        )
    }
    
    static func createSampleUserProgress(wordId: UUID = UUID(), 
                                       isMemorized: Bool = false) -> UserProgress {
        return UserProgress(
            wordId: wordId,
            isMemorized: isMemorized
        )
    }
}

// MARK: - Model Statistics

struct ModelStatistics {
    
    static func calculateWordDistribution(from wordTests: [WordTest]) -> [DifficultyLevel: Int] {
        var distribution: [DifficultyLevel: Int] = [:]
        
        for difficulty in DifficultyLevel.allCases {
            distribution[difficulty] = 0
        }
        
        for wordTest in wordTests {
            distribution[wordTest.difficultyLevel, default: 0] += 1
        }
        
        return distribution
    }
    
    static func calculateProgressStatistics(from progress: [UserProgress]) -> ProgressStatistics {
        let totalWords = progress.count
        let memorizedWords = progress.filter { $0.isMemorized }.count
        let averageReviewCount = progress.isEmpty ? 0.0 : Double(progress.map { $0.reviewCount }.reduce(0, +)) / Double(totalWords)
        
        return ProgressStatistics(
            totalWords: totalWords,
            memorizedWords: memorizedWords,
            notMemorizedWords: totalWords - memorizedWords,
            memorizationRate: totalWords > 0 ? Double(memorizedWords) / Double(totalWords) : 0.0,
            averageReviewCount: averageReviewCount
        )
    }
}

struct ProgressStatistics {
    let totalWords: Int
    let memorizedWords: Int
    let notMemorizedWords: Int
    let memorizationRate: Double
    let averageReviewCount: Double
    
    var memorizationPercentage: Double {
        return memorizationRate * 100.0
    }
}
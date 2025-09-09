import Foundation
import CoreData

protocol RepositoryProtocol {
    associatedtype Entity: NSManagedObject
    associatedtype Model
    
    var persistenceController: PersistenceController { get }
    
    func create(_ model: Model) async throws -> Model
    func fetch(by id: UUID) async throws -> Model?
    func fetchAll() async throws -> [Model]
    func update(_ model: Model) async throws -> Model
    func delete(by id: UUID) async throws
    func deleteAll() async throws
}

extension RepositoryProtocol {
    var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        persistenceController.backgroundContext
    }
}
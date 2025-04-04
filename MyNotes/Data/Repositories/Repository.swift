import Foundation
import CoreData

/// Base protocol for all repositories
protocol Repository {
    associatedtype T
    
    /// The managed object context to use for operations
    var context: NSManagedObjectContext { get }
    
    /// Saves changes to the context
    func save() throws
    
    /// Performs a batch operation in the background
    func performBatchOperation(_ operation: @escaping (NSManagedObjectContext) -> Void)
}

/// Extension providing default implementations for common repository operations
extension Repository {
    func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }
    
    func performBatchOperation(_ operation: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = PersistenceController.shared.backgroundContext
        backgroundContext.perform {
            operation(backgroundContext)
            do {
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                }
            } catch {
                print("Error in batch operation: \(error)")
            }
        }
    }
}

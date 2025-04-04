import Foundation
import CoreData
import Combine

/// A protocol for operations that can be run in the background with CoreData
protocol CoreDataOperationProtocol {
    associatedtype Result
    
    /// The name of the operation for logging and tracking purposes
    var name: String { get }
    
    /// Execute the operation using the provided context
    func execute(in context: NSManagedObjectContext) throws -> Result
}

/// Utility for running CoreData operations in the background
final class CoreDataOperationRunner {
    private let persistence: PersistenceController
    private let taskManager: BackgroundTaskManager
    
    init(
        persistence: PersistenceController = .shared,
        taskManager: BackgroundTaskManager = .shared
    ) {
        self.persistence = persistence
        self.taskManager = taskManager
    }
    
    /// Run an operation in the background, tracking progress
    func runInBackground<T: CoreDataOperationProtocol>(
        operation: T,
        description: String = "CoreData background operation",
        category: String = "Data"
    ) -> AnyPublisher<T.Result, Error> {
        let subject = PassthroughSubject<T.Result, Error>()
        
        _ = taskManager.submitTask(
            name: operation.name,
            description: description,
            category: category
        ) { [weak self] in
            guard let self = self else {
                subject.send(completion: .failure(AppError.generalError("Operation manager released")))
                return
            }
            
            let backgroundContext = self.persistence.backgroundContext
            
            do {
                // Report starting progress
                self.taskManager.updateTaskProgress(operation.id, progress: 0.1)
                
                // Execute operation
                let result = try backgroundContext.performAndWait {
                    try operation.execute(in: backgroundContext)
                }
                
                // Report progress
                self.taskManager.updateTaskProgress(operation.id, progress: 0.9)
                
                // Save the context if it has changes
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                }
                
                // Send the result
                subject.send(result)
                subject.send(completion: .finished)
                
                // Final progress update
                self.taskManager.updateTaskProgress(operation.id, progress: 1.0)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    /// Run an operation sync in foreground for simpler operations
    func runInForeground<T: CoreDataOperationProtocol>(operation: T) throws -> T.Result {
        let viewContext = persistence.container.viewContext
        
        return try viewContext.performAndWait {
            let result = try operation.execute(in: viewContext)
            
            if viewContext.hasChanges {
                try viewContext.save()
            }
            
            return result
        }
    }
}

/// Example CoreData operations
struct FetchNotesOperation: CoreDataOperationProtocol {
    let name = "Fetch Notes"
    let predicate: NSPredicate?
    let sortDescriptors: [NSSortDescriptor]
    let fetchLimit: Int?
    
    init(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(keyPath: \CDNote.date, ascending: false)],
        fetchLimit: Int? = nil
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
    }
    
    func execute(in context: NSManagedObjectContext) throws -> [Note] {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        if let fetchLimit = fetchLimit {
            request.fetchLimit = fetchLimit
        }
        
        let cdNotes = try context.fetch(request)
        return cdNotes.map { $0.toDomainModel() }
    }
}

struct BatchDeleteNotesOperation: CoreDataOperationProtocol {
    let name = "Batch Delete Notes"
    let noteIDs: [UUID]
    
    func execute(in context: NSManagedObjectContext) throws -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDNote")
        request.predicate = NSPredicate(format: "id IN %@", noteIDs.map { $0.uuidString })
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
        let objectIDs = result?.result as? [NSManagedObjectID] ?? []
        
        let changes = [NSDeletedObjectsKey: objectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        
        return objectIDs.count
    }
}

struct ImportNotesOperation: CoreDataOperationProtocol {
    let name = "Import Notes"
    let notes: [Note]
    
    func execute(in context: NSManagedObjectContext) throws -> Int {
        var count = 0
        
        for note in notes {
            _ = CDNote.fromDomainModel(note, in: context)
            count += 1
            
            // Periodically save to avoid large transactions
            if count % 100 == 0 {
                try context.save()
            }
        }
        
        return count
    }
}

// Extension to CoreDataOperationProtocol for operation IDs
extension CoreDataOperationProtocol {
    var id: UUID {
        // Generate a deterministic UUID based on the operation name
        let uniqueString = "\(name)-\(Date().timeIntervalSince1970)"
        return UUID()  // Use random UUID to avoid MD5 dependency for now
    }
}

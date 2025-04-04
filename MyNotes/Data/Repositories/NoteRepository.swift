import Foundation
import CoreData

/// Protocol defining note-related operations
protocol NoteRepository: Repository {
    associatedtype T = Note
    
    /// Fetches all notes
    func fetchAll() throws -> [Note]
    
    /// Fetches notes with specific IDs
    func fetch(byIDs ids: [UUID]) throws -> [Note]
    
    /// Creates a new note
    func create(_ note: Note) throws
    
    /// Updates an existing note
    func update(_ note: Note) throws
    
    /// Deletes notes by their IDs
    func delete(byIDs ids: [UUID]) throws
    
    /// Deletes a single note
    func delete(_ note: Note) throws
    
    /// Performs a batch delete operation
    func batchDelete(byIDs ids: [UUID]) throws
    
    /// Fetches notes with pagination
    func fetchPaged(limit: Int, offset: Int) throws -> [Note]
    
    /// Counts total number of notes
    func count() throws -> Int
}

/// Implementation of NoteRepository using CoreData
final class CoreDataNoteRepository: NoteRepository {
    typealias T = Note
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchAll() throws -> [Note] {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDNote.date, ascending: false)]
        
        let cdNotes = try context.fetch(request)
        return cdNotes.map { $0.toDomainModel() }
    }
    
    func fetch(byIDs ids: [UUID]) throws -> [Note] {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids.map { $0.uuidString })
        
        let cdNotes = try context.fetch(request)
        return cdNotes.map { $0.toDomainModel() }
    }
    
    func create(_ note: Note) throws {
        _ = CDNote.fromDomainModel(note, in: context)
        try save()
    }
    
    func update(_ note: Note) throws {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id.uuidString)
        
        if let cdNote = try context.fetch(request).first {
            _ = CDNote.fromDomainModel(note, in: context)
            try save()
        }
    }
    
    func delete(byIDs ids: [UUID]) throws {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids.map { $0.uuidString })
        
        let cdNotes = try context.fetch(request)
        cdNotes.forEach { context.delete($0) }
        try save()
    }
    
    func delete(_ note: Note) throws {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id.uuidString)
        
        if let cdNote = try context.fetch(request).first {
            context.delete(cdNote)
            try save()
        }
    }
    
    func batchDelete(byIDs ids: [UUID]) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDNote")
        request.predicate = NSPredicate(format: "id IN %@", ids.map { $0.uuidString })
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
        let objectIDs = result?.result as? [NSManagedObjectID] ?? []
        
        let changes = [NSDeletedObjectsKey: objectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
    
    func fetchPaged(limit: Int, offset: Int) throws -> [Note] {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDNote.date, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        
        let cdNotes = try context.fetch(request)
        return cdNotes.map { $0.toDomainModel() }
    }
    
    func count() throws -> Int {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        return try context.count(for: request)
    }
}

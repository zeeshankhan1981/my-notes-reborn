import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    // Background context for heavy operations
    var backgroundContext: NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MyNotesModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure store for better performance
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error loading Core Data: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Reduce CPU usage by avoiding unnecessary processing
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        // Optimize for UI responsiveness
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // For saving context when needed
    func save(_ context: NSManagedObjectContext? = nil) {
        let context = context ?? container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
                #if DEBUG
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                #endif
            }
        }
    }
    
    // Perform work in background and sync with main context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = backgroundContext
        context.perform {
            block(context)
            if context.hasChanges {
                try? context.save()
            }
        }
    }
    
    // For unit testing and previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
}

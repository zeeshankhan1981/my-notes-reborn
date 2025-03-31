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
            
            // Performance optimizations
            // Use SQLite WAL mode for better concurrency
            let pragmaOptions: [String: String] = ["journal_mode": "WAL"]
            description.setOption(pragmaOptions as NSDictionary, forKey: "NSPragmaOptions")
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
        
        // Add performance tuning for batch fetches
        container.viewContext.stalenessInterval = 0.5
    }
    
    // MARK: - Core Data Persistence
    
    func save() {
        // Only save if there are changes
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("PersistenceController: Context saved successfully")
            } catch {
                print("PersistenceController: Error saving context: \(error)")
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

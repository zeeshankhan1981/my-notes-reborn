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
        
        // Only attempt to save if there are actual changes
        guard context.hasChanges else {
            print("PersistenceController: No changes to save")
            return
        }
        
        // Ensure we're on the right thread for this context
        if context === container.viewContext && !Thread.isMainThread {
            DispatchQueue.main.sync {
                self.save(context)
            }
            return
        }
        
        do {
            try context.save()
            print("PersistenceController: Successfully saved context changes")
        } catch {
            let nsError = error as NSError
            print("PersistenceController: Failed to save context - \(nsError), \(nsError.userInfo)")
            
            // Provide more detailed error information
            if let detailedErrors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                for detailedError in detailedErrors {
                    print("PersistenceController: Detailed error - \(detailedError.localizedDescription)")
                    print("PersistenceController: Error domain - \(detailedError.domain)")
                    print("PersistenceController: Error user info - \(detailedError.userInfo)")
                }
            }
            
            #if DEBUG
            assertionFailure("Unresolved error \(nsError), \(nsError.userInfo)")
            #endif
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

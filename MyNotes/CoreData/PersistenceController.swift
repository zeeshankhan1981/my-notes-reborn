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
        
        // Configure persistent store
        if let description = container.persistentStoreDescriptions.first {
            // Enable persistent history tracking
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // Enable remote change notifications
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
                description.type = NSInMemoryStoreType
            }
        }
        
        // Keep container reference for recovery needs
        let storeContainer = container
        
        // Load the persistent stores
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Instead of crashing, log the error and attempt recovery
                print("Error loading Core Data: \(error.localizedDescription)")
                print("Detail: \(error.userInfo)")
                
                // Attempt recovery for common errors
                if error.domain == NSCocoaErrorDomain && error.code == 512 {
                    // Store might be corrupted, attempt to recreate
                    print("Attempting to recover from possible store corruption...")
                    PersistenceController.attemptStoreRecovery(for: storeContainer)
                }
            }
        }
        
        // Configure main context
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Reduce CPU usage by avoiding unnecessary processing
        container.viewContext.shouldDeleteInaccessibleFaults = true
    }
    
    // For saving context when needed
    func save(_ context: NSManagedObjectContext? = nil) {
        let contextToSave = context ?? container.viewContext
        
        guard contextToSave.hasChanges else { return }
        
        do {
            try contextToSave.save()
            print("Context saved successfully")
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError.localizedDescription)")
            print("Detail: \(nsError.userInfo)")
            
            // Attempt basic recovery
            if nsError.domain == NSCocoaErrorDomain {
                if nsError.code == 133 { // Can't modify immutable object
                    print("Attempting to resolve immutable object error...")
                    contextToSave.reset() // Reset the context to clear the error
                } else if nsError.code == 134 { // Missing relationship
                    print("Attempting to resolve missing relationship error...")
                    contextToSave.reset()
                }
            }
            
            #if DEBUG
            // In debug mode, we want to know about this but not crash the app
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
            #endif
        }
    }
    
    // Attempt store recovery when there are issues
    // Static method to avoid self capture issue
    private static func attemptStoreRecovery(for container: NSPersistentContainer) {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        
        let fileManager = FileManager.default
        let storeName = storeURL.lastPathComponent
        
        do {
            // Create backup file
            if fileManager.fileExists(atPath: storeURL.path) {
                let backupURL = storeURL.deletingLastPathComponent().appendingPathComponent("backup_\(storeName)")
                try? fileManager.removeItem(at: backupURL) // Remove any existing backup
                try fileManager.copyItem(at: storeURL, to: backupURL)
                print("Created backup at: \(backupURL.path)")
            }
            
            // Remove the corrupted store
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
            print("Removed corrupted store")
            
            // Recreate the store
            try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: [
                NSPersistentHistoryTrackingKey: true,
                NSPersistentStoreRemoteChangeNotificationPostOptionKey: true
            ])
            print("Successfully recovered store")
        } catch {
            print("Recovery failed: \(error.localizedDescription)")
        }
    }
    
    // Helper function to call the static method from init
    private func attemptStoreRecovery() {
        PersistenceController.attemptStoreRecovery(for: container)
    }
    
    // Perform work in background and sync with main context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = backgroundContext
        context.perform {
            block(context)
            if context.hasChanges {
                do {
                    try context.save()
                    print("Background context saved successfully")
                } catch {
                    print("Error saving background context: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Delete an object safely
    func safeDelete(object: NSManagedObject, in context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? container.viewContext
        
        contextToUse.perform {
            // Ensure the object is associated with this context
            let objectID = object.objectID
            let localObject = contextToUse.object(with: objectID)
            
            contextToUse.delete(localObject)
            
            // Save the context
            self.save(contextToUse)
            
            print("Object deleted successfully: \(objectID)")
        }
    }
    
    // Batch delete for efficiency with large sets
    func batchDelete<T: NSManagedObject>(entityType: T.Type, predicate: NSPredicate, in context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? backgroundContext
        
        contextToUse.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
            fetchRequest.predicate = predicate
            
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                let result = try contextToUse.execute(batchDeleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.container.viewContext])
                    print("Batch delete successful for \(objectIDs.count) objects")
                }
            } catch {
                print("Error performing batch delete: \(error.localizedDescription)")
            }
        }
    }
    
    // For unit testing and previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
}

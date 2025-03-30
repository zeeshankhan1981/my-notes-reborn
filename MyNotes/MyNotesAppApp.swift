import SwiftUI

@main
struct MyNotesAppApp: App {
    // Initialize stores with StateObject for proper lifecycle management
    @StateObject private var noteStore = NoteStore()
    @StateObject private var checklistStore = ChecklistStore()
    @StateObject private var folderStore = FolderStore()
    
    // Initialize the persistence controller
    let persistenceController = PersistenceController.shared
    
    init() {
        print("MyNotesApp: Application initializing")
        
        // Set up enhanced debug logging
        setupDebugLogging()
        
        print("MyNotesApp: Persistence controller initialized with container state: \(persistenceController.container.viewContext.hasChanges ? "has changes" : "no changes")")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(noteStore)
                .environmentObject(checklistStore)
                .environmentObject(folderStore)
                // Make Core Data container available to SwiftUI previews
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    print("MyNotesApp: Main view appeared")
                    validateEnvironment()
                }
        }
    }
    
    private func setupDebugLogging() {
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        #endif
    }
    
    private func validateEnvironment() {
        // Verify Core Data and stores are properly initialized
        print("MyNotesApp: Environment validation")
        print("- Note store contains \(noteStore.notes.count) notes")
        print("- Checklist store contains \(checklistStore.checklists.count) checklists")
        print("- Core Data context: \(persistenceController.container.viewContext)")
    }
}
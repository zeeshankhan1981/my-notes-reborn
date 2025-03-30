import SwiftUI

@main
struct MyNotesAppApp: App {
    @StateObject private var noteStore = NoteStore()
    @StateObject private var checklistStore = ChecklistStore()
    @StateObject private var folderStore = FolderStore()
    
    // Initialize the persistence controller
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(noteStore)
                .environmentObject(checklistStore)
                .environmentObject(folderStore)
                // Make Core Data container available to SwiftUI previews
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
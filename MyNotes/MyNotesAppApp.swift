import SwiftUI

@main
struct MyNotesAppApp: App {
    @StateObject private var noteStore = NoteStore()
    @StateObject private var checklistStore = ChecklistStore()
    @StateObject private var folderStore = FolderStore()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(noteStore)
                .environmentObject(checklistStore)
                .environmentObject(folderStore)
        }
    }
}
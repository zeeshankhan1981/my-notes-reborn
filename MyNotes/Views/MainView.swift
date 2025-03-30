import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            NoteListView()
                .tabItem { Label("Notes", systemImage: "note.text") }
            ChecklistListView()
                .tabItem { Label("Checklists", systemImage: "checklist") }
            FolderManagerView()
                .tabItem { Label("Folders", systemImage: "folder") }
        }
    }
}
import SwiftUI

struct MainView: View {
    init() {
        print("MainView initialized")
    }
    
    var body: some View {
        TabView {
            NoteListView()
                .tabItem { Label("Notes", systemImage: "note.text") }
                .onAppear { print("NoteListView appeared") }
            
            ChecklistListView()
                .tabItem { Label("Checklists", systemImage: "checklist") }
                .onAppear { print("ChecklistListView appeared") }
            
            FolderManagerView()
                .tabItem { Label("Folders", systemImage: "folder") }
                .onAppear { print("FolderManagerView appeared") }
        }
        .onAppear {
            print("TabView appeared")
            
            // Debug color assets
            print("Color assets check:")
            print("- AppPrimaryColor: \(AppTheme.Colors.primary)")
            print("- AppSecondaryColor: \(AppTheme.Colors.secondary)")
            print("- SecondaryBackground: \(AppTheme.Colors.secondaryBackground)")
        }
    }
}
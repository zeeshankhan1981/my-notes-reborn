import SwiftUI

struct MainView: View {
    @StateObject private var noteStore = NoteStore()
    @StateObject private var checklistStore = ChecklistStore()
    @StateObject private var folderStore = FolderStore()
    @StateObject private var tagStore = TagStore()
    @State private var showingGlobalSearch = false
    
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
        .environmentObject(noteStore)
        .environmentObject(checklistStore)
        .environmentObject(folderStore)
        .environmentObject(tagStore)
        .sheet(isPresented: $showingGlobalSearch) {
            GlobalSearchView()
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
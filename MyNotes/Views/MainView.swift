// MARK: - Main Application View
/// The main view of the application that contains the tab-based navigation
/// This view manages the top-level navigation between Notes, Checklists, and Folders tabs
/// and provides access to global settings and search functionality
struct MainView: View {
    /// Stores for managing application state
    @StateObject private var noteStore = NoteStore()
    @StateObject private var checklistStore = ChecklistStore()
    @StateObject private var folderStore = FolderStore()
    @StateObject private var tagStore = TagStore()
    
    /// State variables for UI elements
    @State private var showingGlobalSearch = false
    @State private var showingSettings = false
    @State private var showingNewNote = false
    @State private var showingNewChecklist = false
    
    /// Tab selection state
    @State private var selectedTab = 0
    
    /// The main content of the view
    var body: some View {
        TabView(selection: $selectedTab) {
            // NOTES TAB
            NavigationStack {
                NoteListView()
                    .navigationTitle("Notes")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingNewNote = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tabItem { 
                Label("Notes", systemImage: "note.text") 
            }
            .tag(0)
            
            // CHECKLISTS TAB
            NavigationStack {
                ChecklistListView()
                    .navigationTitle("Checklists")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingNewChecklist = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tabItem { 
                Label("Checklists", systemImage: "checklist") 
            }
            .tag(1)
            
            // FOLDERS TAB
            NavigationStack {
                FolderManagerView()
                    .navigationTitle("Folders")
            }
            .tabItem { 
                Label("Folders", systemImage: "folder") 
            }
            .tag(2)
        }
        .tint(Color("AppPrimaryColor"))
        .environmentObject(noteStore)
        .environmentObject(checklistStore)
        .environmentObject(folderStore)
        .environmentObject(tagStore)
        .sheet(isPresented: $showingGlobalSearch) {
            NavigationStack {
                GlobalSearchView()
                    .navigationTitle("Search")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NavigationStack {
                NoteEditorView(mode: .new, existingNote: nil, showsToolbarItems: false)
                    .navigationTitle("New Note")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingNewNote = false
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                // Save functionality is handled within NoteEditorView
                                showingNewNote = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingNewChecklist) {
            NavigationStack {
                ChecklistEditorView(mode: .new, existingChecklist: nil)
                    .navigationTitle("New Checklist")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

/// Preview provider for MainView
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
import SwiftUI

struct MainView: View {
    @StateObject private var noteStore = NoteStore()
    @StateObject private var checklistStore = ChecklistStore()
    @StateObject private var folderStore = FolderStore()
    @StateObject private var tagStore = TagStore()
    @State private var showingGlobalSearch = false
    @State private var showingSettings = false
    @State private var showingNewNote = false
    @State private var showingNewChecklist = false
    
    // Theme settings
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("useCustomFont") private var useCustomFont = false
    @AppStorage("fontSize") private var fontSize = 16.0
    
    // Tab selection
    @State private var selectedTab = 0
    
    // Force refresh for theme changes
    @State private var themeChangeCount = 0
    
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
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .accessibilityLabel("Settings")
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingNewNote = true
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .accessibilityLabel("New Note")
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
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .accessibilityLabel("Settings")
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
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .accessibilityLabel("Settings")
                            }
                        }
                    }
            }
            .tabItem { 
                Label("Folders", systemImage: "folder") 
            }
            .tag(2)
        }
        .tint(AppTheme.Colors.primary)
        .preferredColorScheme(getPreferredColorScheme())
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
                NoteEditorView(mode: .new, existingNote: nil, presentationMode: .embedded)
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
                                // Post notification to save the note
                                NotificationCenter.default.post(
                                    name: Notification.Name("SaveNoteFromParent"),
                                    object: nil
                                )
                                
                                // Use a separate action to dismiss the sheet after a delay
                                // This prevents modifying state during view update
                                let dismissAction = {
                                    self.showingNewNote = false
                                }
                                
                                // Schedule the dismiss action to run after saving is complete
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: dismissAction)
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
        .id(themeChangeCount) // Force refresh view hierarchy when theme changes
        .onAppear {
            setupThemeObserver()
        }
    }
    
    private func setupThemeObserver() {
        // Add theme change observer
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppThemeChanged"),
            object: nil,
            queue: .main
        ) { _ in
            // Force refresh the view to apply new theme
            themeChangeCount += 1
        }
    }
    
    private func getPreferredColorScheme() -> ColorScheme? {
        switch appTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
}
import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var showingAdd = false
    @State private var selectedNote: Note?
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var isShowingSearch = false
    
    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return noteStore.notes
        } else {
            return noteStore.notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) || 
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var pinnedNotes: [Note] {
        filteredNotes.filter { $0.isPinned }
    }
    
    private var unpinnedNotes: [Note] {
        filteredNotes.filter { !$0.isPinned }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Dimensions.spacing) {
                        // Search bar
                        if isShowingSearch {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                TextField("Search notes...", text: $searchText)
                                    .font(AppTheme.Typography.body)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppTheme.Colors.textTertiary)
                                    }
                                }
                            }
                            .padding(AppTheme.Dimensions.smallSpacing)
                            .background(AppTheme.Colors.secondaryBackground)
                            .cornerRadius(AppTheme.Dimensions.smallCornerRadius)
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Pinned notes section
                        if !pinnedNotes.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                                HStack {
                                    Text("Pinned")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    
                                    Image(systemName: "pin.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: AppTheme.Dimensions.spacing)], spacing: AppTheme.Dimensions.spacing) {
                                    ForEach(pinnedNotes) { note in
                                        NoteCardView(note: note) {
                                            selectedNote = note
                                            isEditing = true
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                        .contextMenu {
                                            Button {
                                                noteStore.togglePin(note: note)
                                            } label: {
                                                Label("Unpin", systemImage: "pin.slash")
                                            }
                                            
                                            Button(role: .destructive) {
                                                noteStore.delete(note: note)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Divider()
                                .padding(.horizontal)
                        }
                        
                        // Unpinned notes
                        if !unpinnedNotes.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                                if !pinnedNotes.isEmpty {
                                    Text("Notes")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .padding(.horizontal)
                                }
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: AppTheme.Dimensions.spacing)], spacing: AppTheme.Dimensions.spacing) {
                                    ForEach(unpinnedNotes) { note in
                                        NoteCardView(note: note) {
                                            selectedNote = note
                                            isEditing = true
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                        .contextMenu {
                                            Button {
                                                noteStore.togglePin(note: note)
                                            } label: {
                                                Label("Pin", systemImage: "pin")
                                            }
                                            
                                            Button(role: .destructive) {
                                                noteStore.delete(note: note)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Empty state
                        if filteredNotes.isEmpty {
                            VStack(spacing: AppTheme.Dimensions.spacing) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                
                                Text(searchText.isEmpty ? "No notes yet" : "No notes match your search")
                                    .font(AppTheme.Typography.title)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                if searchText.isEmpty {
                                    Button(action: {
                                        selectedNote = nil
                                        showingAdd = true
                                    }) {
                                        Text("Create your first note")
                                            .primaryButtonStyle()
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        }
                    }
                    .padding(.top)
                    .animation(AppTheme.Animation.standard, value: pinnedNotes)
                    .animation(AppTheme.Animation.standard, value: unpinnedNotes)
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            isShowingSearch.toggle()
                            if !isShowingSearch {
                                searchText = ""
                            }
                        }
                    }) {
                        Image(systemName: isShowingSearch ? "xmark" : "magnifyingglass")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedNote = nil
                        showingAdd = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                NoteEditorView(mode: .new, existingNote: nil)
            }
            .sheet(isPresented: $isEditing) {
                if let note = selectedNote {
                    NoteEditorView(mode: .edit, existingNote: note)
                }
            }
        }
    }
}
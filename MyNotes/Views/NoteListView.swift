import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var showingAdd = false
    @State private var selectedNote: Note?
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var isShowingSearch = false
    @State private var isEditMode = false
    @State private var selectedNotes = Set<UUID>()
    @State private var isShowingDeleteConfirmation = false
    
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
                
                VStack(spacing: 0) {
                    // Bulk delete toolbar
                    if isEditMode {
                        VStack(spacing: 0) {
                            HStack {
                                Button("Cancel") {
                                    withAnimation {
                                        isEditMode = false
                                        selectedNotes.removeAll()
                                    }
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                                
                                Spacer()
                                
                                Text("\(selectedNotes.count) selected")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                Button("Select All") {
                                    withAnimation {
                                        selectedNotes = Set(filteredNotes.map { $0.id })
                                    }
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            
                            if !selectedNotes.isEmpty {
                                Button(action: {
                                    isShowingDeleteConfirmation = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete Selected")
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .background(AppTheme.Colors.secondaryBackground)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                
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
                                            ZStack {
                                                NoteCardView(note: note, 
                                                    onTap: {
                                                        if isEditMode {
                                                            toggleSelection(for: note)
                                                        } else {
                                                            selectedNote = note
                                                            isEditing = true
                                                        }
                                                    },
                                                    onDelete: {
                                                        noteStore.delete(note: note)
                                                    }
                                                )
                                                
                                                // Selection overlay
                                                if isEditMode {
                                                    selectionOverlay(for: note)
                                                }
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
                                            ZStack {
                                                NoteCardView(note: note, 
                                                    onTap: {
                                                        if isEditMode {
                                                            toggleSelection(for: note)
                                                        } else {
                                                            selectedNote = note
                                                            isEditing = true
                                                        }
                                                    },
                                                    onDelete: {
                                                        noteStore.delete(note: note)
                                                    }
                                                )
                                                
                                                // Selection overlay
                                                if isEditMode {
                                                    selectionOverlay(for: note)
                                                }
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
                .animation(AppTheme.Animation.standard, value: isEditMode)
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isEditMode {
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isEditMode {
                        Menu {
                            Button(action: {
                                selectedNote = nil
                                showingAdd = true
                            }) {
                                Label("Add Note", systemImage: "plus")
                            }
                            
                            Button(action: {
                                withAnimation {
                                    isEditMode = true
                                }
                            }) {
                                Label("Select Notes", systemImage: "checkmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
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
            .alert(isPresented: $isShowingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Selected Notes"),
                    message: Text("Are you sure you want to delete \(selectedNotes.count) notes? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteSelectedNotes()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func toggleSelection(for note: Note) {
        if selectedNotes.contains(note.id) {
            selectedNotes.remove(note.id)
        } else {
            selectedNotes.insert(note.id)
        }
    }
    
    private func deleteSelectedNotes() {
        for id in selectedNotes {
            if let note = filteredNotes.first(where: { $0.id == id }) {
                noteStore.delete(note: note)
            }
        }
        
        selectedNotes.removeAll()
        withAnimation {
            isEditMode = false
        }
    }
    
    @ViewBuilder
    private func selectionOverlay(for note: Note) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.0001)) // Invisible touch layer
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                HStack {
                    Circle()
                        .strokeBorder(selectedNotes.contains(note.id) ? AppTheme.Colors.primary : Color.gray, lineWidth: 2)
                        .background(
                            Circle()
                                .fill(selectedNotes.contains(note.id) ? AppTheme.Colors.primary : Color.clear)
                        )
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                                .opacity(selectedNotes.contains(note.id) ? 1 : 0)
                        )
                        .padding(10)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}
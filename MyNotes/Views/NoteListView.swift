import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var tagStore: TagStore
    @State private var showingAdd = false
    @State private var selectedNote: Note?
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var isShowingSearch = false
    @State private var isSelectionMode = false
    @State private var selectedNotes = Set<UUID>()
    @State private var isShowingDeleteConfirmation = false
    @State private var selectedTagIDs = Set<UUID>()
    @State private var showingTagFilter = false
    
    private var filteredNotes: [Note] {
        var notes = noteStore.notes
        
        // Filter by search text
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) || 
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by selected tags
        if !selectedTagIDs.isEmpty {
            notes = notes.filter { note in
                // A note matches if it has at least one of the selected tags
                !Set(note.tagIDs).isDisjoint(with: selectedTagIDs)
            }
        }
        
        return notes
    }
    
    private var pinnedNotes: [Note] {
        filteredNotes.filter { $0.isPinned }
    }
    
    private var unpinnedNotes: [Note] {
        filteredNotes.filter { !$0.isPinned }
    }

    var body: some View {
        NavigationView {
            mainContentView
                .navigationTitle("Notes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        leadingToolbarContent
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        trailingToolbarContent
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    newNoteSheet
                }
                .sheet(item: $selectedNote) { note in
                    editNoteSheet(note)
                }
                .alert("Delete Notes", isPresented: $isShowingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        deleteSelectedNotes()
                    }
                } message: {
                    Text("Are you sure you want to delete \(selectedNotes.count) note\(selectedNotes.count == 1 ? "" : "s")? This cannot be undone.")
                }
                .onChange(of: isEditing) { _, newValue in
                    if !newValue {
                        selectedNote = nil
                    }
                }
        }
    }
    
    // MARK: - View Components
    
    private var mainContentView: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            if isSelectionMode {
                selectionToolbar
            }
            
            VStack(spacing: 0) {
                if isShowingSearch {
                    searchBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if showingTagFilter {
                    TagFilterView(selectedTagIds: $selectedTagIDs)
                        .padding(.horizontal)
                        .padding(.top, showingTagFilter ? 8 : 0)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Pinned notes
                            if !pinnedNotes.isEmpty {
                                pinnedNotesSection
                            }
                            
                            // Unpinned notes
                            if !unpinnedNotes.isEmpty {
                                unpinnedNotesSection
                            }
                        }
                        .padding(.top, 8)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 0)
                    }
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete these notes?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                for id in selectedNotes {
                    if let noteToDelete = noteStore.notes.first(where: { $0.id == id }) {
                        noteStore.delete(note: noteToDelete)
                    }
                }
                selectedNotes.removeAll()
                isSelectionMode = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var selectionToolbar: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    withAnimation {
                        isSelectionMode = false
                        selectedNotes.removeAll()
                    }
                }
                .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
                
                Text("\(selectedNotes.count) selected")
                    .font(AppTheme.Typography.body())
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
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.textTertiary)
            TextField("Search notes...", text: $searchText)
                .font(AppTheme.Typography.body())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(8)
        .background(AppTheme.Colors.cardSurface)
        .cornerRadius(8)
    }
    
    private var pinnedNotesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
            HStack {
                Text("Pinned")
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            noteGrid(items: pinnedNotes)
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    private var unpinnedNotesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
            if !pinnedNotes.isEmpty {
                Text("Notes")
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal)
            }
            
            noteGrid(items: unpinnedNotes)
        }
    }
    
    private func noteGrid(items: [Note]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 300), spacing: AppTheme.Dimensions.spacing)],
            spacing: AppTheme.Dimensions.spacing
        ) {
            ForEach(items) { note in
                noteCardView(for: note)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Dimensions.spacing) {
            Image(systemName: "note.text")
                .font(.largeTitle)
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text(searchText.isEmpty ? "No Notes" : "No Results")
                .font(AppTheme.Typography.title())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(searchText.isEmpty ? "Tap + to create a new note" : "Try a different search")
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var leadingToolbarContent: some View {
        Group {
            if isSelectionMode {
                Button("Cancel") {
                    withAnimation {
                        isSelectionMode = false
                        selectedNotes.removeAll()
                    }
                }
            } else {
                Menu {
                    Button {
                        withAnimation {
                            isShowingSearch.toggle()
                            if isShowingSearch == false {
                                searchText = ""
                            }
                        }
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    
                    Button {
                        withAnimation {
                            showingTagFilter.toggle()
                            if showingTagFilter == false {
                                selectedTagIDs.removeAll()
                            }
                        }
                    } label: {
                        Label("Filter by Tags", systemImage: "tag")
                    }
                    
                    Button {
                        withAnimation {
                            isSelectionMode = true
                        }
                    } label: {
                        Label("Select Notes", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private var trailingToolbarContent: some View {
        Group {
            if isSelectionMode {
                // Already showing selection toolbar at the top
                EmptyView()
            } else {
                HStack(spacing: 16) {
                    // Direct Add button
                    Button(action: {
                        selectedNote = nil
                        showingAdd = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel("Add Note")
                    
                    // Select button
                    Button(action: {
                        withAnimation {
                            isSelectionMode = true
                        }
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel("Select Notes")
                }
            }
        }
    }
    
    private var newNoteSheet: some View {
        NavigationView {
            NoteEditorView(mode: .new, existingNote: nil)
                .navigationTitle("New Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAdd = false
                        }
                    }
                }
        }
    }
    
    private func editNoteSheet(_ note: Note) -> some View {
        NavigationView {
            NoteEditorView(mode: .edit, existingNote: note)
                .navigationTitle("Edit Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            isEditing = false
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private func noteCardView(for note: Note) -> some View {
        NoteCardView(
            note: note,
            onTap: {
                if !isSelectionMode {
                    selectedNote = note
                    isEditing = true
                }
            },
            onDelete: {
                noteStore.delete(note: note)
            },
            onLongPress: {
                handleLongPress(for: note)
            },
            isInSelectionMode: isSelectionMode,
            isSelected: selectedNotes.contains(note.id)
        )
        .contentShape(Rectangle())
        .contextMenu {
            if note.isPinned {
                Button {
                    noteStore.togglePin(note: note)
                } label: {
                    Label("Unpin", systemImage: "pin.slash")
                }
            } else {
                Button {
                    noteStore.togglePin(note: note)
                } label: {
                    Label("Pin", systemImage: "pin")
                }
            }
            
            Button(role: .destructive) {
                noteStore.delete(note: note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleLongPress(for note: Note) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation {
            if isSelectionMode {
                // Already in selection mode, toggle this note
                toggleSelection(for: note)
            } else {
                // Enter selection mode and select this note
                isSelectionMode = true
                selectedNotes.insert(note.id)
            }
        }
    }
    
    private func toggleSelection(for note: Note) {
        if selectedNotes.contains(note.id) {
            selectedNotes.remove(note.id)
            
            // If no items are selected, exit selection mode
            if selectedNotes.isEmpty {
                withAnimation {
                    isSelectionMode = false
                }
            }
        } else {
            selectedNotes.insert(note.id)
        }
    }
    
    private func deleteSelectedNotes() {
        // Create a temporary copy to avoid modification during iteration
        let notesToDelete = selectedNotes
        
        // Delete the notes
        for id in notesToDelete {
            if let noteToDelete = noteStore.notes.first(where: { $0.id == id }) {
                noteStore.delete(note: noteToDelete)
            }
        }
        
        // Clear selection and exit selection mode
        selectedNotes.removeAll()
        withAnimation {
            isSelectionMode = false
        }
    }
}

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
        mainContentView
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Only keep filter button if needed
                    if !filteredNotes.isEmpty && !isSelectionMode {
                        Button {
                            showingTagFilter.toggle()
                        } label: {
                            Image(systemName: "tag")
                                .foregroundColor(selectedTagIDs.isEmpty ? Color.primary : AppTheme.Colors.primary)
                        }
                        .accessibilityLabel("Filter by tags")
                        .popover(isPresented: $showingTagFilter) {
                            TagFilterView(selectedTagIds: $selectedTagIDs)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbarContent
                }
            }
            .sheet(isPresented: $showingAdd) {
                newNoteSheet
            }
            .sheet(item: $selectedNote) { note in
                NavigationView {
                    NoteEditorView(mode: .edit, existingNote: note)
                        .navigationTitle("Edit Note")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    selectedNote = nil
                                }
                            }
                        }
                }
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
            .onAppear {
                // Add observer for pin toggle from swipe actions
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ToggleNotePin"), object: nil, queue: .main) { notification in
                    if let noteID = notification.object as? UUID,
                       let note = noteStore.notes.first(where: { $0.id == noteID }) {
                        noteStore.togglePin(note: note)
                    }
                }
            }
            .onDisappear {
                // Remove observer when view disappears
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ToggleNotePin"), object: nil)
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
                        LazyVStack(spacing: 12) {
                            // Pinned notes
                            if !pinnedNotes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Pinned")
                                        .font(AppTheme.Typography.headline())
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 16)
                                    
                                    ForEach(pinnedNotes) { note in
                                        noteCardView(for: note)
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            
                            // Unpinned notes
                            if !unpinnedNotes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    if !pinnedNotes.isEmpty {
                                        Text("Notes")
                                            .font(AppTheme.Typography.headline())
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 16)
                                    }
                                    
                                    ForEach(unpinnedNotes) { note in
                                        noteCardView(for: note)
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            
                            Spacer(minLength: 80)
                        }
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
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(AppTheme.Colors.cardSurface.opacity(0.9))
        .shadow(
            color: AppTheme.Colors.cardShadow.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var searchBar: some View {
        SearchBarView(
            searchText: $searchText,
            isSearching: $isShowingSearch,
            placeholder: "Search notes..."
        )
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
    
    @ViewBuilder
    private func noteCardView(for note: Note) -> some View {
        NoteCardView(
            note: note,
            onTap: {
                if isSelectionMode {
                    toggleSelection(for: note)
                } else {
                    selectedNote = note
                }
            },
            onDelete: {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                noteStore.delete(note: note)
            },
            onLongPress: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                if isSelectionMode {
                    toggleSelection(for: note)
                } else {
                    noteStore.togglePin(note: note)
                }
            },
            isInSelectionMode: isSelectionMode,
            isSelected: selectedNotes.contains(note.id)
        )
        .contextMenu {
            Button(action: {
                noteStore.togglePin(note: note)
            }) {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            
            Button(action: {
                // Share functionality
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                noteStore.delete(note: note)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < 0 {
                        // Swiped left - delete
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                        noteStore.delete(note: note)
                    } else if value.translation.width > 0 {
                        // Swiped right - toggle pin
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        noteStore.togglePin(note: note)
                    }
                }
        )
    }
    
    private var trailingToolbarContent: some View {
        Group {
            if isSelectionMode {
                // Already showing selection toolbar at the top
                EmptyView()
            } else {
                HStack(spacing: 16) {
                    // Search button
                    Button(action: {
                        withAnimation(AppTheme.Animations.standardCurve) {
                            isShowingSearch.toggle()
                            if isShowingSearch == false {
                                searchText = ""
                            }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("Search")
                    
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
    
    // MARK: - Helper Functions
    
    private func toggleSelection(for note: Note) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation {
            if selectedNotes.contains(note.id) {
                selectedNotes.remove(note.id)
            } else {
                selectedNotes.insert(note.id)
            }
        }
    }
    
    private func deleteSelectedNotes() {
        for id in selectedNotes {
            if let noteToDelete = noteStore.notes.first(where: { $0.id == id }) {
                noteStore.delete(note: noteToDelete)
            }
        }
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Reset selection state
        selectedNotes.removeAll()
        isSelectionMode = false
    }
}

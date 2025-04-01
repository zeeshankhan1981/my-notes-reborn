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
            .confirmationDialog("Are you sure you want to delete these notes?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteSelectedNotes()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
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
                
                // Add observer for share action from swipe actions
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ShareNote"), object: nil, queue: .main) { notification in
                    if let noteID = notification.object as? UUID,
                       let note = noteStore.notes.first(where: { $0.id == noteID }) {
                        // Share the note content
                        shareNote(note)
                    }
                }
            }
            .onDisappear {
                // Remove observers when view disappears
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ToggleNotePin"), object: nil)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ShareNote"), object: nil)
            }
    }
    
    // MARK: - View Components
    
    private var mainContentView: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isSelectionMode {
                    selectionToolbar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
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
            
            // Only show the delete button when there are selected notes
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
    }
    
    private var searchBar: some View {
        SearchBarView(
            searchText: $searchText,
            isSearching: $isShowingSearch,
            placeholder: "Search notes..."
        )
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            type: .notes,
            searchText: searchText,
            actionButtonTitle: "New Note") {
                showingAdd = true
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
    
    @ViewBuilder
    private func noteCardView(for note: Note) -> some View {
        NoteCardView(
            note: note,
            onTap: {
                selectedNote = note
            },
            onDelete: {
                noteStore.delete(note: note)
            },
            onLongPress: {
                if isSelectionMode {
                    toggleNoteSelection(note)
                } else {
                    withAnimation {
                        isSelectionMode = true
                        selectedNotes.insert(note.id)
                    }
                    // Add haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            },
            isInSelectionMode: isSelectionMode,
            isSelected: selectedNotes.contains(note.id)
        )
        .buttonStyle(PlainButtonStyle()) // Remove default button style
        .contentShape(Rectangle())
        .pressableStyle() // Add our custom pressable style
        .slideInAnimation(from: .bottom) // Add slide-in animation
    }
    
    private var addButton: some View {
        Button(action: {
            showingAdd = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 56, height: 56)
                .foregroundColor(.white)
                .background(AppTheme.Colors.primary)
                .clipShape(Circle())
                .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PrimaryButtonStyle()) // Use our custom button style
        .transition(.scale)
    }
    
    private var trailingToolbarContent: some View {
        Group {
            if isSelectionMode {
                // No additional content needed when in selection mode
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
    
    private func toggleNoteSelection(_ note: Note) {
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
        // Use haptic feedback for deletion
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        // Get notes to delete
        let notesToDelete = noteStore.notes.filter { selectedNotes.contains($0.id) }
        
        if !notesToDelete.isEmpty {
            // Use the more efficient batch deletion method
            noteStore.deleteMultiple(notes: notesToDelete)
            print("NoteListView: Deleted \(notesToDelete.count) notes")
        } else {
            print("NoteListView: No valid notes found to delete")
        }
        
        // Reset selection state
        selectedNotes.removeAll()
        isSelectionMode = false
    }
    
    private func shareNote(_ note: Note) {
        // Create text to share
        let shareText = """
        \(note.title)
        
        \(note.content)
        
        Shared from MyNotes app
        """
        
        // Create activity view controller
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

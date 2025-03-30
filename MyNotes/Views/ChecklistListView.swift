import SwiftUI

struct ChecklistListView: View {
    @EnvironmentObject var checklistStore: ChecklistStore
    @EnvironmentObject var tagStore: TagStore
    @State private var showingAdd = false
    @State private var selectedChecklist: ChecklistNote?
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var isShowingSearch = false
    @State private var isSelectionMode = false
    @State private var selectedChecklists = Set<UUID>()
    @State private var isShowingDeleteConfirmation = false
    @State private var selectedTagIDs = Set<UUID>()
    @State private var showingTagFilter = false
    
    private var filteredChecklists: [ChecklistNote] {
        var checklists = checklistStore.checklists
        
        // Filter by search text
        if !searchText.isEmpty {
            checklists = checklists.filter { checklist in
                checklist.title.localizedCaseInsensitiveContains(searchText) || 
                checklist.items.contains { item in
                    item.text.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Filter by selected tags
        if !selectedTagIDs.isEmpty {
            checklists = checklists.filter { checklist in
                // A checklist matches if it has at least one of the selected tags
                !Set(checklist.tagIDs).isDisjoint(with: selectedTagIDs)
            }
        }
        
        return checklists
    }
    
    private var pinnedChecklists: [ChecklistNote] {
        filteredChecklists.filter { $0.isPinned }
    }
    
    private var unpinnedChecklists: [ChecklistNote] {
        filteredChecklists.filter { !$0.isPinned }
    }

    var body: some View {
        NavigationView {
            mainContentView
                .navigationTitle("Checklists")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        leadingToolbarContent
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        trailingToolbarContent
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    newChecklistSheet
                }
                .sheet(item: $selectedChecklist) { checklist in
                    editChecklistSheet(checklist)
                }
                .alert("Delete Checklists", isPresented: $isShowingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        deleteSelectedChecklists()
                    }
                } message: {
                    Text("Are you sure you want to delete \(selectedChecklists.count) checklist\(selectedChecklists.count == 1 ? "" : "s")? This cannot be undone.")
                }
                .onChange(of: isEditing) { _, newValue in
                    if !newValue {
                        selectedChecklist = nil
                    }
                }
        }
    }
    
    // MARK: - View Components
    
    private var mainContentView: some View {
        ZStack {
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
                    TagFilterView(selectedTagIDs: $selectedTagIDs)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if filteredChecklists.isEmpty {
                    emptyStateView
                } else {
                    checklistContent
                }
            }
            .background(AppTheme.Colors.background)
        }
        .confirmationDialog("Are you sure you want to delete these checklists?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                for id in selectedChecklists {
                    if let checklistToDelete = checklistStore.checklists.first(where: { $0.id == id }) {
                        checklistStore.delete(checklist: checklistToDelete)
                    }
                }
                selectedChecklists.removeAll()
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
                        selectedChecklists.removeAll()
                    }
                }
                .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
                
                Text("\(selectedChecklists.count) selected")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Button("Select All") {
                    withAnimation {
                        selectedChecklists = Set(filteredChecklists.map { $0.id })
                    }
                }
                .foregroundColor(AppTheme.Colors.primary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            if !selectedChecklists.isEmpty {
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
            TextField("Search checklists...", text: $searchText)
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
    
    private var checklistContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Dimensions.spacing) {
                // Pinned checklists
                if !pinnedChecklists.isEmpty {
                    pinnedChecklistsSection
                }
                
                // Unpinned checklists
                if !unpinnedChecklists.isEmpty {
                    unpinnedChecklistsSection
                }
            }
            .padding(.top, AppTheme.Dimensions.smallSpacing)
        }
    }
    
    private var pinnedChecklistsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
            HStack {
                Text("Pinned")
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            checklistGrid(items: pinnedChecklists)
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    private var unpinnedChecklistsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
            if !pinnedChecklists.isEmpty {
                Text("Checklists")
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal)
            }
            
            checklistGrid(items: unpinnedChecklists)
        }
    }
    
    private func checklistGrid(items: [ChecklistNote]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 300), spacing: AppTheme.Dimensions.spacing)],
            spacing: AppTheme.Dimensions.spacing
        ) {
            ForEach(items) { checklist in
                checklistCardView(for: checklist)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Dimensions.spacing) {
            Image(systemName: "checklist")
                .font(.largeTitle)
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text(searchText.isEmpty ? "No Checklists" : "No Results")
                .font(AppTheme.Typography.title())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(searchText.isEmpty ? "Tap + to create a new checklist" : "Try a different search")
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
                        selectedChecklists.removeAll()
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
                        Label("Select Checklists", systemImage: "checkmark.circle")
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
                        selectedChecklist = nil
                        showingAdd = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel("Add Checklist")
                    
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
                    .accessibilityLabel("Select Checklists")
                }
            }
        }
    }
    
    private var newChecklistSheet: some View {
        NavigationView {
            ChecklistEditorView(mode: .new, existingChecklist: nil)
                .navigationTitle("New Checklist")
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
    
    private func editChecklistSheet(_ checklist: ChecklistNote) -> some View {
        NavigationView {
            ChecklistEditorView(mode: .edit, existingChecklist: checklist)
                .navigationTitle("Edit Checklist")
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
    private func checklistCardView(for checklist: ChecklistNote) -> some View {
        ChecklistCardView(
            checklist: checklist,
            onTap: {
                if !isSelectionMode {
                    selectedChecklist = checklist
                    isEditing = true
                }
            },
            onDelete: {
                checklistStore.delete(checklist: checklist)
            },
            onLongPress: {
                handleLongPress(for: checklist)
            },
            isInSelectionMode: isSelectionMode,
            isSelected: selectedChecklists.contains(checklist.id)
        )
        .contentShape(Rectangle())
        .contextMenu {
            if checklist.isPinned {
                Button {
                    checklistStore.togglePin(checklist: checklist)
                } label: {
                    Label("Unpin", systemImage: "pin.slash")
                }
            } else {
                Button {
                    checklistStore.togglePin(checklist: checklist)
                } label: {
                    Label("Pin", systemImage: "pin")
                }
            }
            
            Button(role: .destructive) {
                checklistStore.delete(checklist: checklist)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleLongPress(for checklist: ChecklistNote) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation {
            if isSelectionMode {
                // Already in selection mode, toggle this checklist
                toggleSelection(for: checklist)
            } else {
                // Enter selection mode and select this checklist
                isSelectionMode = true
                selectedChecklists.insert(checklist.id)
            }
        }
    }
    
    private func toggleSelection(for checklist: ChecklistNote) {
        if selectedChecklists.contains(checklist.id) {
            selectedChecklists.remove(checklist.id)
            
            // If no items are selected, exit selection mode
            if selectedChecklists.isEmpty {
                withAnimation {
                    isSelectionMode = false
                }
            }
        } else {
            selectedChecklists.insert(checklist.id)
        }
    }
    
    private func deleteSelectedChecklists() {
        // Create a temporary copy to avoid modification during iteration
        let checklistsToDelete = selectedChecklists
        
        // Delete the checklists
        for id in checklistsToDelete {
            if let checklistToDelete = checklistStore.checklists.first(where: { $0.id == id }) {
                checklistStore.delete(checklist: checklistToDelete)
            }
        }
        
        // Clear selection and exit selection mode
        selectedChecklists.removeAll()
        withAnimation {
            isSelectionMode = false
        }
    }
}
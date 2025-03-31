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
    @State private var animateListAppearance = false
    @Environment(\.colorScheme) private var colorScheme
    
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
                .onAppear {
                    // Trigger animation when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(AppTheme.Animations.standardCurve) {
                            animateListAppearance = true
                        }
                    }
                    
                    // Add observer for pin toggle from swipe actions
                    NotificationCenter.default.addObserver(forName: NSNotification.Name("ToggleChecklistPin"), object: nil, queue: .main) { notification in
                        if let checklistID = notification.object as? UUID,
                           let checklist = checklistStore.checklists.first(where: { $0.id == checklistID }) {
                            checklistStore.togglePin(checklist: checklist)
                        }
                    }
                    
                    // Add observer for complete all items from swipe actions
                    NotificationCenter.default.addObserver(forName: NSNotification.Name("CompleteAllChecklistItems"), object: nil, queue: .main) { notification in
                        if let checklistID = notification.object as? UUID,
                           let index = checklistStore.checklists.firstIndex(where: { $0.id == checklistID }) {
                            var updatedChecklist = checklistStore.checklists[index]
                            let allDone = updatedChecklist.items.allSatisfy { $0.isDone }
                            
                            for i in 0..<updatedChecklist.items.count {
                                updatedChecklist.items[i].isDone = !allDone
                            }
                            
                            checklistStore.updateChecklist(checklist: updatedChecklist)
                            
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    }
                }
                .onDisappear {
                    // Remove observers when view disappears
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ToggleChecklistPin"), object: nil)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name("CompleteAllChecklistItems"), object: nil)
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
                    TagFilterView(selectedTagIds: $selectedTagIDs)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if filteredChecklists.isEmpty {
                    emptyStateView
                        .transition(.opacity)
                } else {
                    checklistContent
                        .transition(.opacity)
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
                    withAnimation(AppTheme.Animations.standardCurve) {
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
                    withAnimation(AppTheme.Animations.standardCurve) {
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
                    .padding(.horizontal)
                    .background(AppTheme.Colors.error)
                    .cornerRadius(AppTheme.Dimensions.radiusM)
                    .padding(.horizontal)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .background(colorScheme == .dark ? 
            AppTheme.Colors.cardSurface.opacity(0.9) : 
            AppTheme.Colors.secondaryBackground.opacity(0.9))
        .shadow(
            color: AppTheme.Colors.cardShadow.opacity(0.1),
            radius: 3,
            x: 0,
            y: 2
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var searchBar: some View {
        SearchBarView(
            searchText: $searchText,
            isSearching: $isShowingSearch,
            placeholder: "Search checklists..."
        )
    }
    
    private var checklistContent: some View {
        List {
            // Pinned checklists
            if !pinnedChecklists.isEmpty {
                Section(header: 
                    Label("Pinned", systemImage: "pin.fill")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                ) {
                    ForEach(pinnedChecklists) { checklist in
                        checklistCardView(for: checklist)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.warning)
                                    checklistStore.delete(checklist: checklist)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    checklistStore.togglePin(checklist: checklist)
                                } label: {
                                    Label("Unpin", systemImage: "pin.slash")
                                }
                                .tint(AppTheme.Colors.primary)
                                
                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    if let index = checklistStore.checklists.firstIndex(where: { $0.id == checklist.id }) {
                                        var updatedChecklist = checklistStore.checklists[index]
                                        let allDone = updatedChecklist.items.allSatisfy { $0.isDone }
                                        
                                        for i in 0..<updatedChecklist.items.count {
                                            updatedChecklist.items[i].isDone = !allDone
                                        }
                                        
                                        checklistStore.updateChecklist(checklist: updatedChecklist)
                                        
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)
                                    }
                                } label: {
                                    Label("Complete All", systemImage: "checkmark.circle")
                                }
                                .tint(AppTheme.Colors.accent)
                            }
                    }
                }
            }
            
            // Unpinned checklists
            Section(header: 
                !pinnedChecklists.isEmpty ?
                    Text("Checklists")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                : nil
            ) {
                ForEach(unpinnedChecklists) { checklist in
                    checklistCardView(for: checklist)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.warning)
                                checklistStore.delete(checklist: checklist)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                checklistStore.togglePin(checklist: checklist)
                            } label: {
                                Label("Pin", systemImage: "pin.fill")
                            }
                            .tint(AppTheme.Colors.primary)
                            
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                if let index = checklistStore.checklists.firstIndex(where: { $0.id == checklist.id }) {
                                    var updatedChecklist = checklistStore.checklists[index]
                                    let allDone = updatedChecklist.items.allSatisfy { $0.isDone }
                                    
                                    for i in 0..<updatedChecklist.items.count {
                                        updatedChecklist.items[i].isDone = !allDone
                                    }
                                    
                                    checklistStore.updateChecklist(checklist: updatedChecklist)
                                    
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                }
                            } label: {
                                Label("Complete All", systemImage: "checkmark.circle")
                            }
                            .tint(AppTheme.Colors.accent)
                        }
                }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .opacity(animateListAppearance ? 1 : 0)
        .animation(.easeInOut, value: animateListAppearance)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Dimensions.spacingL) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? 
                          AppTheme.Colors.secondaryBackground : 
                          AppTheme.Colors.highlightBackground)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checklist")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            .padding(.bottom, AppTheme.Dimensions.spacing)
            
            VStack(spacing: AppTheme.Dimensions.spacingS) {
                Text(searchText.isEmpty ? "No Checklists" : "No Results")
                    .font(AppTheme.Typography.title())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(searchText.isEmpty ? "Create a checklist to track tasks and stay organized" : "Try different search terms or clear filters")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if searchText.isEmpty && selectedTagIDs.isEmpty {
                Button(action: {
                    selectedChecklist = nil
                    showingAdd = true
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create Checklist")
                    }
                    .font(AppTheme.Typography.button())
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.Dimensions.radiusM)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, AppTheme.Dimensions.spacing)
            } else {
                Button(action: {
                    withAnimation {
                        searchText = ""
                        selectedTagIDs.removeAll()
                        isShowingSearch = false
                        showingTagFilter = false
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Clear Filters")
                    }
                    .font(AppTheme.Typography.button())
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                            .stroke(AppTheme.Colors.primary, lineWidth: 1)
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, AppTheme.Dimensions.spacing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .opacity(animateListAppearance ? 1 : 0)
        .offset(y: animateListAppearance ? 0 : 20)
        .animation(AppTheme.Animations.standardCurve, value: animateListAppearance)
    }
    
    private var leadingToolbarContent: some View {
        Group {
            if isSelectionMode {
                Button("Cancel") {
                    withAnimation(AppTheme.Animations.standardCurve) {
                        isSelectionMode = false
                        selectedChecklists.removeAll()
                    }
                }
                .foregroundColor(AppTheme.Colors.primary)
            } else {
                Menu {
                    Button {
                        withAnimation(AppTheme.Animations.standardCurve) {
                            showingTagFilter.toggle()
                            if showingTagFilter == false {
                                selectedTagIDs.removeAll()
                            }
                        }
                    } label: {
                        Label("Filter by Tags", systemImage: "tag")
                    }
                    
                    Button {
                        withAnimation(AppTheme.Animations.standardCurve) {
                            isSelectionMode = true
                        }
                    } label: {
                        Label("Select Checklists", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }
    
    private var trailingToolbarContent: some View {
        Group {
            if isSelectionMode {
                Button("Select All") {
                    withAnimation(AppTheme.Animations.standardCurve) {
                        selectedChecklists = Set(filteredChecklists.map { $0.id })
                    }
                }
                .foregroundColor(AppTheme.Colors.primary)
            } else {
                HStack(spacing: 16) {
                    // Add button
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel("Add Checklist")
                    
                    // Search button - keep only this search entry point
                    Button {
                        withAnimation(AppTheme.Animations.standardCurve) {
                            isShowingSearch.toggle()
                            if isShowingSearch == false {
                                searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel("Search")
                    
                    // Select button
                    Button {
                        withAnimation(AppTheme.Animations.standardCurve) {
                            isSelectionMode = true
                        }
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18))
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
                        .buttonStyle(PressableButtonStyle())
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
                        .buttonStyle(PressableButtonStyle())
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
                withAnimation(AppTheme.Animations.standardCurve) {
                    checklistStore.delete(checklist: checklist)
                }
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
        
        withAnimation(AppTheme.Animations.standardCurve) {
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
                withAnimation(AppTheme.Animations.standardCurve) {
                    isSelectionMode = false
                }
            }
        } else {
            selectedChecklists.insert(checklist.id)
        }
    }
    
    private func deleteSelectedChecklists() {
        // Add haptic feedback for destructive action
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
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
        withAnimation(AppTheme.Animations.standardCurve) {
            isSelectionMode = false
        }
    }
}

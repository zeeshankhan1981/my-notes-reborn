import SwiftUI

struct ChecklistListView: View {
    @EnvironmentObject var checklistStore: ChecklistStore
    @State private var showingAdd = false
    @State private var selectedChecklist: ChecklistNote?
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var isShowingSearch = false
    @State private var isEditMode = false
    @State private var selectedChecklists = Set<UUID>()
    @State private var isShowingDeleteConfirmation = false
    
    private var filteredChecklists: [ChecklistNote] {
        if searchText.isEmpty {
            return checklistStore.checklists
        } else {
            return checklistStore.checklists.filter { checklist in
                checklist.title.localizedCaseInsensitiveContains(searchText) || 
                checklist.items.contains { item in
                    item.text.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    private var pinnedChecklists: [ChecklistNote] {
        filteredChecklists.filter { $0.isPinned }
    }
    
    private var unpinnedChecklists: [ChecklistNote] {
        filteredChecklists.filter { !$0.isPinned }
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
                                        selectedChecklists.removeAll()
                                    }
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                                
                                Spacer()
                                
                                Text("\(selectedChecklists.count) selected")
                                    .font(AppTheme.Typography.body)
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
                
                    ScrollView {
                        VStack(spacing: AppTheme.Dimensions.spacing) {
                            // Search bar
                            if isShowingSearch {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                    TextField("Search checklists...", text: $searchText)
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
                            
                            // Pinned checklists section
                            if !pinnedChecklists.isEmpty {
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
                                        ForEach(pinnedChecklists) { checklist in
                                            ZStack {
                                                ChecklistCardView(checklist: checklist, 
                                                    onTap: {
                                                        if isEditMode {
                                                            toggleSelection(for: checklist)
                                                        } else {
                                                            selectedChecklist = checklist
                                                            isEditing = true
                                                        }
                                                    },
                                                    onDelete: {
                                                        checklistStore.delete(note: checklist)
                                                    }
                                                )
                                                
                                                // Selection overlay
                                                if isEditMode {
                                                    selectionOverlay(for: checklist)
                                                }
                                            }
                                            .transition(.scale.combined(with: .opacity))
                                            .contextMenu {
                                                Button {
                                                    checklistStore.togglePin(note: checklist)
                                                } label: {
                                                    Label("Unpin", systemImage: "pin.slash")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    checklistStore.delete(note: checklist)
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
                            
                            // Unpinned checklists
                            if !unpinnedChecklists.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                                    if !pinnedChecklists.isEmpty {
                                        Text("Checklists")
                                            .font(AppTheme.Typography.headline)
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                            .padding(.horizontal)
                                    }
                                    
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: AppTheme.Dimensions.spacing)], spacing: AppTheme.Dimensions.spacing) {
                                        ForEach(unpinnedChecklists) { checklist in
                                            ZStack {
                                                ChecklistCardView(checklist: checklist, 
                                                    onTap: {
                                                        if isEditMode {
                                                            toggleSelection(for: checklist)
                                                        } else {
                                                            selectedChecklist = checklist
                                                            isEditing = true
                                                        }
                                                    },
                                                    onDelete: {
                                                        checklistStore.delete(note: checklist)
                                                    }
                                                )
                                                
                                                // Selection overlay
                                                if isEditMode {
                                                    selectionOverlay(for: checklist)
                                                }
                                            }
                                            .transition(.scale.combined(with: .opacity))
                                            .contextMenu {
                                                Button {
                                                    checklistStore.togglePin(note: checklist)
                                                } label: {
                                                    Label("Pin", systemImage: "pin")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    checklistStore.delete(note: checklist)
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
                            if filteredChecklists.isEmpty {
                                VStack(spacing: AppTheme.Dimensions.spacing) {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                    
                                    Text(searchText.isEmpty ? "No checklists yet" : "No checklists match your search")
                                        .font(AppTheme.Typography.title)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                    
                                    if searchText.isEmpty {
                                        Button(action: {
                                            selectedChecklist = nil
                                            showingAdd = true
                                        }) {
                                            Text("Create your first checklist")
                                                .primaryButtonStyle()
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                            }
                        }
                        .padding(.top)
                        .animation(AppTheme.Animation.standard, value: pinnedChecklists)
                        .animation(AppTheme.Animation.standard, value: unpinnedChecklists)
                    }
                }
                .animation(AppTheme.Animation.standard, value: isEditMode)
            }
            .navigationTitle("Checklists")
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
                                selectedChecklist = nil
                                showingAdd = true
                            }) {
                                Label("Add Checklist", systemImage: "plus")
                            }
                            
                            Button(action: {
                                withAnimation {
                                    isEditMode = true
                                }
                            }) {
                                Label("Select Checklists", systemImage: "checkmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                ChecklistEditorView(mode: .new, existingChecklist: nil)
            }
            .sheet(isPresented: $isEditing) {
                if let checklist = selectedChecklist {
                    ChecklistEditorView(mode: .edit, existingChecklist: checklist)
                }
            }
            .alert(isPresented: $isShowingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Selected Checklists"),
                    message: Text("Are you sure you want to delete \(selectedChecklists.count) checklists? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteSelectedChecklists()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func toggleSelection(for checklist: ChecklistNote) {
        if selectedChecklists.contains(checklist.id) {
            selectedChecklists.remove(checklist.id)
        } else {
            selectedChecklists.insert(checklist.id)
        }
    }
    
    private func deleteSelectedChecklists() {
        for id in selectedChecklists {
            if let checklist = filteredChecklists.first(where: { $0.id == id }) {
                checklistStore.delete(note: checklist)
            }
        }
        
        selectedChecklists.removeAll()
        withAnimation {
            isEditMode = false
        }
    }
    
    @ViewBuilder
    private func selectionOverlay(for checklist: ChecklistNote) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.0001)) // Invisible touch layer
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                HStack {
                    Circle()
                        .strokeBorder(selectedChecklists.contains(checklist.id) ? AppTheme.Colors.primary : Color.gray, lineWidth: 2)
                        .background(
                            Circle()
                                .fill(selectedChecklists.contains(checklist.id) ? AppTheme.Colors.primary : Color.clear)
                        )
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                                .opacity(selectedChecklists.contains(checklist.id) ? 1 : 0)
                        )
                        .padding(10)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}
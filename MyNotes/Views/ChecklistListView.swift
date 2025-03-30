import SwiftUI

struct ChecklistListView: View {
    @EnvironmentObject var checklistStore: ChecklistStore
    @State private var showingAdd = false
    @State private var selectedChecklist: ChecklistNote?
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var isShowingSearch = false
    
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
                                        ChecklistCardView(checklist: checklist) {
                                            selectedChecklist = checklist
                                            isEditing = true
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
                                        ChecklistCardView(checklist: checklist) {
                                            selectedChecklist = checklist
                                            isEditing = true
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
            .navigationTitle("Checklists")
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
                        selectedChecklist = nil
                        showingAdd = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.Colors.primary)
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
        }
    }
}
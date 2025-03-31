import SwiftUI

struct GlobalSearchView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var checklistStore: ChecklistStore
    @EnvironmentObject var tagStore: TagStore
    
    @StateObject private var searchService = SearchService()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedItem: SearchResultItem?
    @State private var showingNoteEditor = false
    @State private var showingChecklistEditor = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBarView(
                    searchText: $searchService.searchText,
                    isSearching: $searchService.isSearching,
                    placeholder: "Search notes and checklists...",
                    onSubmit: performSearch
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if isLoading {
                    loadingView
                } else if searchService.searchResults.isEmpty && !searchService.searchText.isEmpty {
                    emptyResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .onAppear {
                performSearch()
            }
            .sheet(isPresented: $showingNoteEditor) {
                if let selectedItem = selectedItem, let note = noteStore.getNote(id: selectedItem.id) {
                    NavigationView {
                        NoteEditorView(mode: .edit, existingNote: note)
                            .navigationTitle("Edit Note")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") {
                                        showingNoteEditor = false
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                }
                            }
                    }
                }
            }
            .sheet(isPresented: $showingChecklistEditor) {
                if let selectedItem = selectedItem, let checklist = checklistStore.getChecklist(id: selectedItem.id) {
                    NavigationView {
                        ChecklistEditorView(mode: .edit, existingChecklist: checklist)
                            .navigationTitle("Edit Checklist")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") {
                                        showingChecklistEditor = false
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                }
                            }
                    }
                }
            }
        }
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchService.searchResults) { item in
                    SearchResultRow(item: item) {
                        selectedItem = item
                        
                        switch item.type {
                        case .note:
                            showingNoteEditor = true
                        case .checklist:
                            showingChecklistEditor = true
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
        }
        .animation(.easeInOut, value: searchService.searchResults)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .padding()
            Text("Searching...")
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No results found")
                .font(AppTheme.Typography.title2())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Try different search terms")
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private func performSearch() {
        // Simulate loading state for smoother UX
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            searchService.search(notes: noteStore.notes, checklists: checklistStore.checklists)
            isLoading = false
            
            // Add haptic feedback when search completes
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

struct SearchResultRow: View {
    let item: SearchResultItem
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon for the type of result
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? 
                            AppTheme.Colors.cardSurface : 
                            AppTheme.Colors.secondaryBackground)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(AppTheme.Typography.headline())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(item.subtitle)
                        .font(AppTheme.Typography.subheadline())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(item.type.displayName)
                            .font(AppTheme.Typography.caption())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                item.type == .note ? 
                                    AppTheme.Colors.primary : 
                                    AppTheme.Colors.accent
                            )
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text(dateFormatter.string(from: item.date))
                            .font(AppTheme.Typography.caption())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.top, 12)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                    .fill(colorScheme == .dark ? 
                        AppTheme.Colors.cardSurface : 
                        Color.white)
                    .shadow(
                        color: AppTheme.Colors.cardShadow.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    GlobalSearchView()
        .environmentObject(NoteStore())
        .environmentObject(ChecklistStore())
        .environmentObject(TagStore())
}

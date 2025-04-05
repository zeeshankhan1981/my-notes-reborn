import SwiftUI

enum ChecklistEditorMode {
    case new
    case edit
}

struct ChecklistEditorView: View {
    @EnvironmentObject var checklistStore: ChecklistStore
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var tagStore: TagStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    let mode: ChecklistEditorMode
    let existingChecklist: ChecklistNote?

    @State private var title = ""
    @State private var items: [ChecklistItem] = []
    @State private var newItem = ""
    @State private var selectedFolderID: UUID?
    @State private var tagIDs: [UUID] = []
    @State private var animateItems = false
    @State private var isShowingDeleteConfirmation = false
    
    // Animation and UI state
    @State private var animateIn = false
    @State private var focusedField: UUID?
    @FocusState private var isAddingNewItem: Bool
    @FocusState private var isTitleFocused: Bool

    // Original initializer for backward compatibility
    init(mode: ChecklistEditorMode, existingChecklist: ChecklistNote?) {
        self.mode = mode
        self.existingChecklist = existingChecklist
        
        if let checklist = existingChecklist, mode == .edit {
            _title = State(initialValue: checklist.title)
            _items = State(initialValue: checklist.items)
            _selectedFolderID = State(initialValue: checklist.folderID)
            _tagIDs = State(initialValue: checklist.tagIDs)
        }
    }
    
    // New simplified initializer
    init(checklist: ChecklistNote?) {
        if let checklist = checklist {
            self.mode = .edit
            self.existingChecklist = checklist
            _title = State(initialValue: checklist.title)
            _items = State(initialValue: checklist.items)
            _selectedFolderID = State(initialValue: checklist.folderID)
            _tagIDs = State(initialValue: checklist.tagIDs)
        } else {
            self.mode = .new
            self.existingChecklist = nil
        }
    }
    
    // Sheet presentation initializer
    init(isPresented: Binding<Bool>) {
        self.mode = .new
        self.existingChecklist = nil
        // When dismissed from this initializer, we need to set isPresented to false
        // This is handled in the saveChecklist() method
    }
    
    var body: some View {
        ZStack {
            // Background color
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            // Main content
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Title section
                        titleSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateIn)
                        
                        // Items section
                        itemsSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: animateIn)
                        
                        // Tags section
                        tagsSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 40)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateIn)
                        
                        // Folder section
                        folderSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 50)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: animateIn)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .onChange(of: focusedField) { oldValue, newValue in
                    if let id = newValue {
                        withAnimation {
                            scrollProxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(mode == .new ? "New Checklist" : "Edit Checklist")
                    .font(AppTheme.Typography.headline().bold())
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Only show delete button in edit mode
                    if mode == .edit {
                        Button {
                            isShowingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(AppTheme.Colors.danger)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityLabel("Delete Checklist")
                    }
                    
                    SaveButton(
                        action: saveChecklistWithAnimation,
                        isDisabled: title.isEmpty && items.isEmpty
                    )
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dismiss()
                    }
                }
                .foregroundColor(AppTheme.Colors.accent)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateIn = true
                }
                
                // Start item animations after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        animateItems = true
                    }
                }
                
                // Auto-focus the title field for new checklists
                if mode == .new {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isTitleFocused = true
                    }
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this checklist?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let checklist = existingChecklist {
                    checklistStore.delete(checklist: checklist)
                    // Add haptic feedback for destructive action
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - UI Components
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)
            
            TextField("Checklist title", text: $title)
                .font(AppTheme.Typography.title3().bold())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(16)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(12)
                .shadow(color: AppTheme.Colors.cardShadow.opacity(0.05), radius: 2, x: 0, y: 1)
                .focused($isTitleFocused)
                .submitLabel(.next)
                .onSubmit {
                    isAddingNewItem = true
                }
        }
    }
    
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Items")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)
            
            // Items container
            VStack(spacing: 0) {
                // Existing items
                if items.isEmpty && !isAddingNewItem {
                    emptyStateView
                } else {
                    VStack(spacing: 8) {
                        ForEach(items.indices, id: \.self) { index in
                            ChecklistItemRow(
                                item: binding(for: items[index]),
                                isAddingNewItem: isAddingNewItem,
                                onDelete: { deleteItem(at: index) }
                            )
                            .id(items[index].id)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animateItems)
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // Add new item
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.accent.opacity(0.7))
                        .font(.system(size: 20))
                    
                    TextField("Add a new item", text: $newItem)
                        .font(AppTheme.Typography.body())
                        .submitLabel(.done)
                        .focused($isAddingNewItem)
                        .onSubmit {
                            addItem()
                        }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.Colors.secondaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.Colors.divider, lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    isAddingNewItem = true
                }
            }
            .padding(16)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(12)
            .shadow(color: AppTheme.Colors.cardShadow.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.bottom, 4)
            
            Text("No items yet")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("Tap to add your first item")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .contentShape(Rectangle())
        .onTapGesture {
            isAddingNewItem = true
        }
        .transition(.opacity)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)
            
            TagFilterView(selectedTagIds: Binding(
                get: { Set(tagIDs) },
                set: { tagIDs = Array($0) }
            ))
            .padding(12)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(12)
            .shadow(color: AppTheme.Colors.cardShadow.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Folder")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)
            
            Menu {
                Button("None") {
                    withAnimation {
                        selectedFolderID = nil
                    }
                }
                
                Divider()
                
                ForEach(folderStore.folders) { folder in
                    Button(folder.name) {
                        withAnimation {
                            selectedFolderID = folder.id
                        }
                    }
                }
            } label: {
                HStack {
                    Label(selectedFolderName, systemImage: "folder.fill")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.divider, lineWidth: 1)
                )
            }
        }
    }
    
    private var selectedFolderName: String {
        if let id = selectedFolderID, let folder = folderStore.folders.first(where: { $0.id == id }) {
            return folder.name
        }
        return "None"
    }
    
    // MARK: - Actions
    
    private func binding(for item: ChecklistItem) -> Binding<ChecklistItem> {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            fatalError("Item not found: \(item.id)")
        }
        return $items[index]
    }
    
    private func addItem() {
        if !newItem.isEmpty {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                let item = ChecklistItem(
                    id: UUID(),
                    text: newItem,
                    isDone: false
                )
                items.append(item)
                newItem = ""
                
                // Provide haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Add animation for the new item
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = item.id
                }
            }
        }
    }
    
    private func deleteItem(at index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            // Provide haptic feedback for deletion
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            items.remove(at: index)
        }
    }
    
    private func saveChecklistWithAnimation() {
        // Create haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            let finalTitle = title.isEmpty ? "Untitled Checklist" : title
            
            if mode == .new {
                // Create a new checklist with items
                let newChecklist = ChecklistNote(
                    id: UUID(),
                    title: finalTitle,
                    folderID: selectedFolderID,
                    items: items,
                    isPinned: false,
                    date: Date(),
                    tagIDs: tagIDs
                )
                
                // Save the new checklist
                checklistStore.updateChecklist(checklist: newChecklist)
            } else if let checklist = existingChecklist {
                // Update existing checklist with new values
                checklistStore.updateChecklist(
                    checklist: checklist,
                    title: finalTitle,
                    items: items,
                    folderID: selectedFolderID,
                    tagIDs: tagIDs
                )
            }
            
            dismiss()
        }
    }
}

// MARK: - Enhanced Checklist Item Row
struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem
    @State var isAddingNewItem: Bool
    var onDelete: () -> Void
    
    @State private var isFocused = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    // Toggle the isDone property directly
                    item.isDone.toggle()
                    
                    // Provide haptic feedback
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }) {
                Circle()
                    .stroke(item.isDone ? AppTheme.Colors.accent : AppTheme.Colors.divider, lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(item.isDone ? 
                                  AppTheme.Colors.accent : Color.clear)
                            .frame(width: 14, height: 14)
                    )
            }
            .buttonStyle(PressableButtonStyle())
            
            // Text field
            TextField("", text: $item.text)
                .font(AppTheme.Typography.body())
                .foregroundColor(item.isDone ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                .strikethrough(item.isDone)
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) { oldValue, newValue in
                    if newValue {
                        isFocused = true
                        // Signal parent that we're not adding a new item anymore
                        withAnimation {
                            isAddingNewItem = false
                        }
                    }
                }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(item.isDone ? 
                      AppTheme.Colors.secondaryBackground.opacity(0.5) : 
                      AppTheme.Colors.secondaryBackground)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = true
        }
    }
}

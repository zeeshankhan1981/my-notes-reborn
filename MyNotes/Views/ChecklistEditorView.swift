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
    @State private var animateList = false
    @State private var focusedField: UUID?
    @FocusState private var isAddingNewItem: Bool

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
    
    var body: some View {
        ZStack {
            // Background color
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            // Main content
            mainContentView
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SaveButton {
                    saveChecklist()
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                CancelButton {
                    dismiss()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(mode == .new ? "New Checklist" : "Edit Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: startAnimations)
    }
    
    private func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                animateList = true
            }
        }
    }
    
    // MARK: - Main Content Components
    
    private var mainContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingL) {
                // Title field
                FormFieldView(label: "Title", iconName: "textformat") {
                    TextField("Checklist title", text: $title)
                        .font(AppTheme.Typography.title3())
                }
                
                // Checklist items
                FormFieldView(label: "Items", iconName: "checklist") {
                    VStack(spacing: AppTheme.Dimensions.spacingS) {
                        // Existing items
                        if items.isEmpty {
                            emptyItemsPlaceholder
                                .padding(.vertical, 8)
                        } else {
                            ForEach(items.indices, id: \.self) { index in
                                ChecklistItemRow(
                                    item: binding(for: items[index]),
                                    focusedField: $focusedField,
                                    onDelete: { deleteItem(item: items[index]) }
                                )
                                .padding(.vertical, 2)
                                .transition(.opacity)
                            }
                        }
                        
                        // Add new item section
                        addNewItemSection
                            .padding(.top, 8)
                    }
                }
                
                // Folder selection
                FormFieldView(label: "Folder", iconName: "folder") {
                    folderSelector
                }
                
                // Tag selection
                FormFieldView(label: "Tags", iconName: "tag") {
                    TagFilterView(selectedTagIds: Binding(
                        get: { Set(tagIDs) },
                        set: { tagIDs = Array($0) }
                    ))
                    .padding(4)
                }
            }
            .padding(.vertical, AppTheme.Dimensions.spacingL)
        }
    }
    
    private var titleFieldSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingXS) {
            // Label
            titleSectionLabel
            
            // Text field
            titleTextField
        }
        .opacity(animateList ? 1 : 0)
        .offset(y: animateList ? 0 : 10)
        .animation(
            AppTheme.Animations.standardCurve,
            value: animateList
        )
    }
    
    private var titleSectionLabel: some View {
        Label("Title", systemImage: "textformat")
            .font(AppTheme.Typography.headline())
            .foregroundColor(AppTheme.Colors.textSecondary)
            .padding(.horizontal)
    }
    
    private var titleTextField: some View {
        TextField("Checklist title", text: $title)
            .font(AppTheme.Typography.title3())
            .padding()
            .background(titleTextFieldBackground)
            .overlay(titleTextFieldBorder)
            .padding(.horizontal)
    }
    
    private var titleTextFieldBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
            .fill(colorScheme == .dark ? 
                  AppTheme.Colors.cardSurface : 
                  AppTheme.Colors.secondaryBackground)
    }
    
    private var titleTextFieldBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
            .stroke(AppTheme.Colors.divider, lineWidth: 1)
    }
    
    // MARK: - Checklist Items
    
    private var checklistItemsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
            // Header
            itemsSectionHeader
            
            // Existing items list
            itemsList
            
            // Add new item section
            addNewItemSection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusL)
                .fill(AppTheme.Colors.cardSurface)
                .shadow(
                    color: AppTheme.Colors.cardShadow.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .padding(.horizontal)
        .opacity(animateList ? 1 : 0)
        .offset(y: animateList ? 0 : 10)
        .animation(
            AppTheme.Animations.standardCurve.delay(0.1),
            value: animateList
        )
    }
    
    private var itemsSectionHeader: some View {
        HStack {
            Label("Items", systemImage: "checklist")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
            
            Text("\(items.count) items")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
    }
    
    private var itemsList: some View {
        VStack(spacing: AppTheme.Dimensions.spacingXS) {
            if items.isEmpty {
                emptyItemsPlaceholder
            } else {
                ForEach(items.indices, id: \.self) { index in
                    ChecklistItemRow(
                        item: binding(for: items[index]),
                        focusedField: $focusedField,
                        onDelete: { deleteItem(item: items[index]) }
                    )
                    .transition(.opacity)
                }
            }
        }
    }
    
    private var emptyItemsPlaceholder: some View {
        Text("No items yet. Add your first item below.")
            .font(AppTheme.Typography.body())
            .foregroundColor(AppTheme.Colors.textTertiary)
            .italic()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
    
    private var addNewItemSection: some View {
        HStack {
            Image(systemName: "plus.circle")
                .foregroundColor(AppTheme.Colors.primary)
                .font(.system(size: 20))
            
            TextField("Add a new item", text: $newItem)
                .font(AppTheme.Typography.body())
                .focused($isAddingNewItem)
                .submitLabel(.done)
                .onSubmit {
                    addNewItem()
                }
            
            if !newItem.isEmpty {
                Button(action: addNewItem) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.success)
                        .font(.system(size: 20))
                }
                .buttonStyle(ScaleButtonStyle())
                .transition(.scale)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                .stroke(AppTheme.Colors.divider, lineWidth: 1)
        )
    }
    
    // MARK: - Folder Selection
    
    private var folderSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
            // Header
            folderSectionHeader
            
            // Folder selector
            folderSelector
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusL)
                .fill(AppTheme.Colors.cardSurface)
                .shadow(
                    color: AppTheme.Colors.cardShadow.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .padding(.horizontal)
        .opacity(animateList ? 1 : 0)
        .offset(y: animateList ? 0 : 10)
        .animation(
            AppTheme.Animations.standardCurve.delay(0.2),
            value: animateList
        )
    }
    
    private var folderSectionHeader: some View {
        Label("Folder", systemImage: "folder")
            .font(AppTheme.Typography.headline())
            .foregroundColor(AppTheme.Colors.textSecondary)
    }
    
    private var folderSelector: some View {
        Menu {
            Button("None", action: {
                selectedFolderID = nil
            })
            .disabled(selectedFolderID == nil)
            
            Divider()
            
            ForEach(folderStore.folders) { folder in
                Button(folder.name, action: {
                    selectedFolderID = folder.id
                })
            }
        } label: {
            HStack {
                Text(selectedFolderName)
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                    .stroke(AppTheme.Colors.divider, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Tag Selection
    
    private var tagSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
            // Header
            tagSectionHeader
            
            // Tag filter
            TagFilterView(selectedTagIds: Binding(
                get: { Set(tagIDs) },
                set: { tagIDs = Array($0) }
            ))
            .environmentObject(tagStore)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusL)
                .fill(AppTheme.Colors.cardSurface)
                .shadow(
                    color: AppTheme.Colors.cardShadow.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .padding(.horizontal)
        .opacity(animateList ? 1 : 0)
        .offset(y: animateList ? 0 : 10)
        .animation(
            AppTheme.Animations.standardCurve.delay(0.3),
            value: animateList
        )
    }
    
    private var tagSectionHeader: some View {
        Label("Tags", systemImage: "tag")
            .font(AppTheme.Typography.headline())
            .foregroundColor(AppTheme.Colors.textSecondary)
    }
    
    // MARK: - Supporting Views
    
    private var selectedFolderName: String {
        if let id = selectedFolderID, let folder = folderStore.folders.first(where: { $0.id == id }) {
            return folder.name
        } else {
            return "No Folder"
        }
    }
    
    private func addNewItem() {
        guard !newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newChecklistItem = ChecklistItem(id: UUID(), text: newItem, isDone: false)
        
        withAnimation {
            items.append(newChecklistItem)
        }
        
        // Clear the text field and maintain focus
        newItem = ""
        isAddingNewItem = true
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func saveChecklist() {
        if let checklist = existingChecklist, mode == .edit {
            // Create updated checklist with the new properties
            var updatedChecklist = checklist
            updatedChecklist.title = title
            updatedChecklist.items = items
            updatedChecklist.folderID = selectedFolderID
            updatedChecklist.tagIDs = tagIDs
            
            // Update the checklist
            checklistStore.updateChecklist(checklist: updatedChecklist)
        } else {
            // Create a new checklist - passing individual properties
            // instead of the entire ChecklistNote object
            checklistStore.addChecklist(
                title: title,
                folderID: selectedFolderID,
                tagIDs: tagIDs
            )
            
            // The items will be empty initially
            // We'll add them separately if needed or update the API
        }
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Dismiss the view
        dismiss()
    }
    
    private func deleteItem(item: ChecklistItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            withAnimation {
                items.remove(at: index)
            }
        }
    }
    
    private func binding(for item: ChecklistItem) -> Binding<ChecklistItem> {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            fatalError("Checklist item not found")
        }
        
        return $items[index]
    }
}

// MARK: - Supporting Views

struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem
    @Binding var focusedField: UUID?
    @FocusState private var isTextFieldFocused: Bool
    let onDelete: () -> Void
    
    // MARK: - Computed Properties
    
    private var textColor: Color {
        item.isDone ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary
    }
    
    private var isDeleteButtonVisible: Bool {
        item.text.isEmpty || isTextFieldFocused
    }
    
    private var backgroundFill: Color {
        isTextFieldFocused ? Color.blue.opacity(0.08) : Color.clear
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: AppTheme.Dimensions.spacingS) {
            // Checkbox
            checkboxView
            
            // Text field
            textFieldView
            
            // Delete button
            deleteButtonView
        }
        .padding(AppTheme.Dimensions.spacingS)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                .fill(backgroundFill)
        )
        .onChange(of: focusedField) { _, newValue in
            isTextFieldFocused = newValue == item.id
        }
        .onChange(of: isTextFieldFocused) { _, newValue in
            if newValue {
                focusedField = item.id
            } else if focusedField == item.id {
                focusedField = nil
            }
        }
    }
    
    // MARK: - Component Views
    
    private var checkboxView: some View {
        AnimatedCheckbox(isChecked: $item.isDone)
    }
    
    private var textFieldView: some View {
        TextField("Item description", text: $item.text)
            .font(AppTheme.Typography.body())
            .foregroundColor(textColor)
            .strikethrough(item.isDone)
            .focused($isTextFieldFocused)
    }
    
    private var deleteButtonView: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .foregroundColor(AppTheme.Colors.error)
                .font(.system(size: 14))
                .padding(8)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .opacity(isDeleteButtonVisible ? 1 : 0)
    }
}

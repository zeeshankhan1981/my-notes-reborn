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

    let mode: ChecklistEditorMode
    let existingChecklist: ChecklistNote?

    @State private var title = ""
    @State private var items: [ChecklistItem] = []
    @State private var newItem = ""
    @State private var selectedFolderID: UUID?
    @State private var tagIDs: [UUID] = []
    
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
        ScrollView {
            VStack(spacing: 16) {
                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextField("Checklist title", text: $title)
                        .font(AppTheme.Typography.title)
                        .padding(10)
                        .background(AppTheme.Colors.secondaryBackground)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Items section
                VStack(alignment: .leading, spacing: 8) {
                    Text("ITEMS")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal)
                    
                    // Checklist items
                    VStack(spacing: 0) {
                        ForEach($items) { $item in
                            HStack(spacing: 12) {
                                Button(action: { item.isDone.toggle() }) {
                                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isDone ? .green : .gray)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(.plain)
                                
                                TextField("Item", text: $item.text)
                                    .font(AppTheme.Typography.body)
                                
                                Button(action: {
                                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                                        items.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                        .font(.system(size: 16))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            
                            if items.last?.id != item.id {
                                Divider()
                                    .padding(.leading, 42)
                            }
                        }
                    }
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Add new item field
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(AppTheme.Colors.primary)
                            .font(.system(size: 20))
                        
                        TextField("New Item", text: $newItem)
                            .font(AppTheme.Typography.body)
                            .submitLabel(.done)
                            .onSubmit {
                                addNewItem()
                            }
                        
                        Button("Add") {
                            addNewItem()
                        }
                        .font(AppTheme.Typography.footnote.bold())
                        .foregroundColor(AppTheme.Colors.primary)
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Folder Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Folder")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal)
                    
                    Menu {
                        Button("None") {
                            selectedFolderID = nil
                        }
                        
                        Divider()
                        
                        ForEach(folderStore.folders) { folder in
                            Button(folder.name) {
                                selectedFolderID = folder.id
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedFolderName)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding()
                        .background(AppTheme.Colors.secondaryBackground)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                
                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal)
                    
                    TagSelectorView(selectedTagIDs: $tagIDs)
                        .padding(.horizontal)
                }
                
                // Bottom padding
                Spacer(minLength: 16)
            }
            .padding(.top)
        }
        .background(AppTheme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChecklist()
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private var selectedFolderName: String {
        if let id = selectedFolderID, let folder = folderStore.folders.first(where: { $0.id == id }) {
            return folder.name
        } else {
            return "None"
        }
    }
    
    private func addNewItem() {
        let trimmedText = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            withAnimation {
                items.append(ChecklistItem(id: UUID(), text: trimmedText, isDone: false))
                newItem = ""
            }
        }
    }
    
    private func saveChecklist() {
        if let checklist = existingChecklist, mode == .edit {
            // Create updated checklist with the new properties
            var updatedChecklist = checklist
            updatedChecklist.title = title
            updatedChecklist.items = items
            updatedChecklist.folderID = selectedFolderID
            updatedChecklist.tagIDs = tagIDs
            
            // Use the correct method from ChecklistStore
            checklistStore.updateChecklist(checklist: updatedChecklist)
        } else {
            // Create a new checklist
            let checklist = ChecklistNote(
                id: UUID(),
                title: title,
                folderID: selectedFolderID,
                items: items,
                isPinned: false,
                date: Date(),
                tagIDs: tagIDs
            )
            
            // Use the correct method from ChecklistStore
            checklistStore.updateChecklist(checklist: checklist)
        }
    }
}

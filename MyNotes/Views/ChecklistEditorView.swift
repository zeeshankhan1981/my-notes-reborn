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
        NavigationView {
            Form {
                TextField("Title", text: $title)

                Section(header: Text("Items")) {
                    ForEach($items) { $item in
                        HStack {
                            Button(action: { item.isDone.toggle() }) {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isDone ? .green : .gray)
                            }
                            .buttonStyle(.plain)
                            TextField("Item", text: $item.text)
                        }
                    }
                    .onDelete { items.remove(atOffsets: $0) }
                    .onMove { from, to in
                        items.move(fromOffsets: from, toOffset: to)
                    }

                    HStack {
                        TextField("New Item", text: $newItem)
                        Button("Add") {
                            addNewItem()
                        }
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section(header: Text("Folder")) {
                    Picker("Folder", selection: $selectedFolderID) {
                        Text("None").tag(UUID?.none)
                        ForEach(folderStore.folders) { folder in
                            Text(folder.name).tag(Optional(folder.id))
                        }
                    }
                }

                Section {
                    TagSelectorView(selectedTagIDs: $tagIDs)
                }
            }
            .navigationTitle(mode == .new ? "New Checklist" : "Edit Checklist")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChecklist()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                if !items.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .onSubmit {
                if !newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    addNewItem()
                }
            }
        }
    }
    
    private func addNewItem() {
        let trimmedText = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            let item = ChecklistItem(id: UUID(), text: trimmedText, isDone: false)
            items.append(item)
            newItem = ""
        }
    }
    
    private func saveChecklist() {
        switch mode {
        case .new:
            let checklist = ChecklistNote(
                id: UUID(),
                title: title,
                folderID: selectedFolderID,
                items: items,
                isPinned: false,
                date: Date(),
                tagIDs: tagIDs
            )
            checklistStore.updateChecklist(checklist: checklist)
            
        case .edit:
            if let checklist = existingChecklist {
                checklistStore.updateChecklist(
                    checklist: checklist,
                    title: title,
                    items: items,
                    folderID: selectedFolderID,
                    tagIDs: tagIDs
                )
            }
        }
    }
}

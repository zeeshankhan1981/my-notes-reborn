import SwiftUI

struct TagManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tagStore: TagStore
    
    @State private var newTagName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var editingTag: Tag? = nil
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: Tag? = nil
    
    private let availableColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .gray]
    
    var body: some View {
        NavigationView {
            List {
                // Create new tag section
                Section {
                    TextField("Tag name", text: $newTagName)
                    
                    // Color selector
                    colorSelectionView
                    
                    // Add/Update button
                    addOrUpdateButton
                } header: {
                    Text("Create New Tag")
                }
                
                // Existing tags section
                Section {
                    if tagStore.tags.isEmpty {
                        Text("No tags created yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(tagStore.tags) { tag in
                            tagRowView(for: tag)
                        }
                    }
                } header: {
                    Text("Your Tags")
                }
            }
            .alert("Delete Tag", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteSelectedTag()
                }
            } message: {
                Text("Are you sure you want to delete this tag? This action cannot be undone.")
            }
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var colorSelectionView: some View {
        HStack {
            Text("Color")
            Spacer()
            
            ForEach(availableColors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(color == selectedColor ? Color.primary : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        selectedColor = color
                    }
                    .padding(.horizontal, 2)
            }
        }
    }
    
    private var addOrUpdateButton: some View {
        Button {
            saveTag()
        } label: {
            Text(editingTag == nil ? "Add Tag" : "Update Tag")
                .frame(maxWidth: .infinity)
        }
        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .buttonStyle(.borderedProminent)
        .padding(.vertical, 4)
    }
    
    private func tagRowView(for tag: Tag) -> some View {
        HStack {
            // Tag color indicator
            Circle()
                .fill(tag.color)
                .frame(width: 12, height: 12)
            
            // Tag name
            Text(tag.name)
            
            Spacer()
            
            // Edit button
            Button {
                startEditing(tag)
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.secondary)
            }
            
            // Delete button
            Button {
                showDeleteConfirmation(for: tag)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedName.isEmpty {
            Task {
                if let editTag = editingTag {
                    await tagStore.updateTag(id: editTag.id, name: trimmedName, color: selectedColor)
                    editingTag = nil
                } else {
                    await tagStore.addTag(name: trimmedName, color: selectedColor)
                }
                
                // Reset form
                newTagName = ""
                selectedColor = .blue
            }
        }
    }
    
    private func startEditing(_ tag: Tag) {
        editingTag = tag
        newTagName = tag.name
        selectedColor = tag.color
    }
    
    private func showDeleteConfirmation(for tag: Tag) {
        tagToDelete = tag
        showingDeleteAlert = true
    }
    
    private func deleteSelectedTag() {
        if let tag = tagToDelete {
            Task {
                await tagStore.deleteTag(id: tag.id)
            }
            tagToDelete = nil
        }
    }
}

#Preview {
    TagManagementView()
        .environmentObject(TagStore())
}

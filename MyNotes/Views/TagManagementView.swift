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
                Section(header: Text("Create New Tag")) {
                    TextField("Tag name", text: $newTagName)
                    
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
                    
                    Button(action: {
                        if !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            if let editTag = editingTag {
                                tagStore.update(tag: editTag, name: newTagName, color: selectedColor)
                                editingTag = nil
                            } else {
                                _ = tagStore.addTag(name: newTagName, color: selectedColor)
                            }
                            newTagName = ""
                            selectedColor = .blue
                        }
                    }) {
                        Text(editingTag == nil ? "Add Tag" : "Update Tag")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Your Tags")) {
                    if tagStore.tags.isEmpty {
                        Text("No tags created yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(tagStore.tags) { tag in
                            HStack {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(tag.name)
                                
                                Spacer()
                                
                                Button(action: {
                                    editingTag = tag
                                    newTagName = tag.name
                                    selectedColor = tag.color
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: {
                                    tagToDelete = tag
                                    showingDeleteAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .alert("Delete Tag", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let tag = tagToDelete {
                        tagStore.delete(tag: tag)
                        tagToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this tag? It will be removed from all notes and checklists.")
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
}

#Preview {
    TagManagementView()
        .environmentObject(TagStore())
}

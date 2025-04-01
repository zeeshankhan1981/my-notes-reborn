import SwiftUI

struct NewNoteView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedFolderID: UUID?
    @State private var showingFolderPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Title", text: $title)
                }
                
                Section(header: Text("Content")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section(header: Text("Folder")) {
                    Button(action: {
                        showingFolderPicker = true
                    }) {
                        HStack {
                            Text("Select Folder")
                            Spacer()
                            if let folderID = selectedFolderID,
                               let folder = folderStore.getFolder(id: folderID) {
                                Text(folder.name)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .sheet(isPresented: $showingFolderPicker) {
                        FolderPickerView(selectedFolderID: $selectedFolderID)
                    }
                }
            }
            .navigationBarTitle("New Note", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    saveNote()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveNote() {
        // Add the new note to the store
        noteStore.addNote(
            title: title,
            content: content,
            folderID: selectedFolderID,
            imageData: nil
        )
        
        // Dismiss the view
        isPresented = false
    }
}

struct FolderPickerView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFolderID: UUID?
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedFolderID = nil
                    dismiss()
                }) {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedFolderID == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                ForEach(folderStore.folders) { folder in
                    Button(action: {
                        selectedFolderID = folder.id
                        dismiss()
                    }) {
                        HStack {
                            Text(folder.name)
                            Spacer()
                            if selectedFolderID == folder.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Select Folder", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

struct NewNoteView_Previews: PreviewProvider {
    static var previews: some View {
        NewNoteView(isPresented: .constant(true))
            .environmentObject(NoteStore())
            .environmentObject(FolderStore())
    }
}

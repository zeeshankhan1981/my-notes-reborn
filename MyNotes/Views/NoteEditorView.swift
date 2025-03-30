import SwiftUI
import PhotosUI

enum NoteEditorMode {
    case new
    case edit
}

struct NoteEditorView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.dismiss) var dismiss

    let mode: NoteEditorMode
    let existingNote: Note?
    
    @State private var title = ""
    @State private var content = ""
    @State private var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedFolderID: UUID?
    @State private var tags = ""

    init(mode: NoteEditorMode, existingNote: Note?) {
        self.mode = mode
        self.existingNote = existingNote
        
        if let note = existingNote, mode == .edit {
            _title = State(initialValue: note.title)
            _content = State(initialValue: note.content)
            _imageData = State(initialValue: note.imageData)
            _selectedFolderID = State(initialValue: note.folderID)
            // Tags would be initialized here if tags were implemented
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $content)
                    .frame(minHeight: 150)

                PhotosPicker("Add Image", selection: $selectedItem, matching: .images)
                if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .overlay(
                            Button(action: {
                                imageData = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .padding(8),
                            alignment: .topTrailing
                        )
                }

                Picker("Folder", selection: $selectedFolderID) {
                    Text("None").tag(UUID?.none)
                    ForEach(folderStore.folders) { folder in
                        Text(folder.name).tag(Optional(folder.id))
                    }
                }

                TextField("Tags (comma separated)", text: $tags)
            }
            .navigationTitle(mode == .new ? "New Note" : "Edit Note")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
    }
    
    private func saveNote() {
        switch mode {
        case .new:
            noteStore.addNote(
                title: title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData
            )
        case .edit:
            if let note = existingNote {
                noteStore.update(
                    note: note,
                    title: title,
                    content: content,
                    folderID: selectedFolderID,
                    imageData: imageData
                )
            }
        }
    }
}
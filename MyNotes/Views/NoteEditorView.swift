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
    @State private var attributedContent = NSAttributedString()
    @State private var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedFolderID: UUID?
    @State private var tags = ""
    @State private var isShowingFormatting = false
    
    // Original initializer for backward compatibility
    init(mode: NoteEditorMode, existingNote: Note?) {
        self.mode = mode
        self.existingNote = existingNote
        
        if let note = existingNote, mode == .edit {
            _title = State(initialValue: note.title)
            _content = State(initialValue: note.content)
            _imageData = State(initialValue: note.imageData)
            _selectedFolderID = State(initialValue: note.folderID)
            
            // Initialize attributedContent from data if available
            if let attributedContentData = note.attributedContent,
               let decodedAttributedString = try? NSAttributedString(
                   data: attributedContentData,
                   options: [.documentType: NSAttributedString.DocumentType.rtfd],
                   documentAttributes: nil) {
                _attributedContent = State(initialValue: decodedAttributedString)
            } else {
                // Fallback to regular content with default attributes
                _attributedContent = State(initialValue: NSAttributedString(
                    string: note.content,
                    attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
                ))
            }
            
            // Tags would be initialized here if tags were implemented
        } else {
            // Initialize with empty attributed string
            _attributedContent = State(initialValue: NSAttributedString(
                string: "",
                attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
            ))
        }
    }
    
    // New simplified initializer
    init(note: Note?) {
        if let note = note {
            self.mode = .edit
            self.existingNote = note
            _title = State(initialValue: note.title)
            _content = State(initialValue: note.content)
            _imageData = State(initialValue: note.imageData)
            _selectedFolderID = State(initialValue: note.folderID)
            
            // Initialize attributedContent from data if available
            if let attributedContentData = note.attributedContent,
               let decodedAttributedString = try? NSAttributedString(
                   data: attributedContentData,
                   options: [.documentType: NSAttributedString.DocumentType.rtfd],
                   documentAttributes: nil) {
                _attributedContent = State(initialValue: decodedAttributedString)
            } else {
                // Fallback to regular content with default attributes
                _attributedContent = State(initialValue: NSAttributedString(
                    string: note.content,
                    attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
                ))
            }
        } else {
            self.mode = .new
            self.existingNote = nil
            
            // Initialize with empty attributed string
            _attributedContent = State(initialValue: NSAttributedString(
                string: "",
                attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Dimensions.spacing) {
                        // Title field
                        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                            Text("Title")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            TextField("Note title", text: $title)
                                .font(AppTheme.Typography.title)
                                .padding(AppTheme.Dimensions.smallSpacing)
                                .background(AppTheme.Colors.secondaryBackground)
                                .cornerRadius(AppTheme.Dimensions.smallCornerRadius)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Rich Text Editor
                        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                            HStack {
                                Text("Content")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            RichTextEditor(
                                text: $attributedContent,
                                placeholder: "Type your note content here...",
                                onTextChange: { newText in
                                    attributedContent = newText
                                    // Update plain text content as well for search & previews
                                    content = newText.string
                                }
                            )
                            .frame(minHeight: 200)
                            .background(AppTheme.Colors.secondaryBackground)
                            .cornerRadius(AppTheme.Dimensions.cornerRadius)
                            .padding(.horizontal)
                        }
                        
                        // Image Picker
                        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                            Text("Image")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.horizontal)
                            
                            VStack {
                                if let data = imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(AppTheme.Dimensions.cornerRadius)
                                        .overlay(
                                            Button(action: {
                                                withAnimation {
                                                    imageData = nil
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title)
                                                    .foregroundColor(.white)
                                                    .shadow(radius: 1)
                                            }
                                            .padding(8),
                                            alignment: .topTrailing
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        VStack(spacing: AppTheme.Dimensions.smallSpacing) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 40))
                                                .foregroundColor(AppTheme.Colors.textTertiary)
                                            
                                            Text("Add Image")
                                                .font(AppTheme.Typography.caption)
                                                .foregroundColor(AppTheme.Colors.primary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                        .background(AppTheme.Colors.secondaryBackground)
                                        .cornerRadius(AppTheme.Dimensions.cornerRadius)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .animation(AppTheme.Animation.standard, value: imageData != nil)
                        }
                        
                        // Folder selection
                        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                            Text("Folder")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Picker("Select Folder", selection: $selectedFolderID) {
                                Text("None").tag(UUID?.none)
                                
                                ForEach(folderStore.folders) { folder in
                                    Text(folder.name).tag(Optional(folder.id))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.secondaryBackground)
                            .cornerRadius(AppTheme.Dimensions.cornerRadius)
                        }
                        .padding(.horizontal)
                        
                        // Tags field (for future implementation)
                        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                            Text("Tags")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            TextField("Add tags separated by commas", text: $tags)
                                .padding()
                                .background(AppTheme.Colors.secondaryBackground)
                                .cornerRadius(AppTheme.Dimensions.cornerRadius)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(mode == .new ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(AppTheme.Colors.primary)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .onChange(of: selectedItem) { oldItem, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        withAnimation {
                            imageData = data
                        }
                    }
                }
            }
        }
    }
    
    private func saveNote() {
        // Convert attributedContent to Data for storage
        let rtfdData: Data?
        if !attributedContent.string.isEmpty {
            rtfdData = try? attributedContent.data(
                from: NSRange(location: 0, length: attributedContent.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
            )
        } else {
            rtfdData = nil
        }
        
        switch mode {
        case .new:
            noteStore.addNote(
                title: title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: rtfdData
            )
        case .edit:
            if let note = existingNote {
                noteStore.update(
                    note: note,
                    title: title,
                    content: content,
                    folderID: selectedFolderID,
                    imageData: imageData,
                    attributedContent: rtfdData
                )
            }
        }
    }
}
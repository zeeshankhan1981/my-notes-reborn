import SwiftUI
import PhotosUI

enum NoteEditorMode {
    case new
    case edit
}

struct NoteEditorView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var tagStore: TagStore
    @Environment(\.dismiss) var dismiss

    let mode: NoteEditorMode
    let existingNote: Note?
    
    @State private var title = ""
    @State private var content = ""
    @State private var attributedContent = NSAttributedString()
    @State private var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedFolderID: UUID?
    @State private var tagIDs = [UUID]()
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
            _tagIDs = State(initialValue: note.tagIDs)
            
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
            // Set default attributed content for new notes
            _attributedContent = State(initialValue: NSAttributedString(
                string: "",
                attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
            ))
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
                    
                    TextField("Note title", text: $title)
                        .font(AppTheme.Typography.title)
                        .padding(10)
                        .background(AppTheme.Colors.secondaryBackground)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Rich Text Editor
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Content")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        // Toggle formatting toolbar button
                        Button(action: {
                            withAnimation {
                                isShowingFormatting.toggle()
                            }
                        }) {
                            Label(isShowingFormatting ? "Hide Formatting" : "Show Formatting", 
                                  systemImage: isShowingFormatting ? "textformat.alt" : "textformat")
                                .labelStyle(.iconOnly)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Rich text formatting toolbar
                    if isShowingFormatting {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FormatButton(icon: "bold", action: {
                                    applyFormatting(.bold)
                                })
                                
                                FormatButton(icon: "italic", action: {
                                    applyFormatting(.italic)
                                })
                                
                                FormatButton(icon: "underline", action: {
                                    applyFormatting(.underline)
                                })
                                
                                Divider().frame(height: 20)
                                
                                FormatButton(icon: "text.alignleft", action: {
                                    applyFormatting(.alignLeft)
                                })
                                
                                FormatButton(icon: "text.aligncenter", action: {
                                    applyFormatting(.alignCenter)
                                })
                                
                                FormatButton(icon: "text.alignright", action: {
                                    applyFormatting(.alignRight)
                                })
                                
                                Divider().frame(height: 20)
                                
                                FormatButton(icon: "list.bullet", action: {
                                    applyFormatting(.bulletList)
                                })
                                
                                FormatButton(icon: "list.number", action: {
                                    applyFormatting(.numberedList)
                                })
                                
                                Divider().frame(height: 20)
                                
                                FormatButton(icon: "textformat.size", action: {
                                    applyFormatting(.fontSize(16.0))
                                })
                                
                                FormatButton(icon: "paintpalette", action: {
                                    applyFormatting(.textColor(.blue))
                                })
                                
                                FormatButton(icon: "link", action: {
                                    let url = URL(string: "https://example.com")!
                                    applyFormatting(.insertLink(url, "Link"))
                                })
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(AppTheme.Colors.secondaryBackground)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
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
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Image Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Image")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal)
                    
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        HStack {
                            Spacer()
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                            
                            Spacer()
                        }
                        .overlay(
                            Button(action: {
                                withAnimation {
                                    self.imageData = nil
                                    self.selectedItem = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.7)))
                                    .padding(8)
                            }, alignment: .topTrailing
                        )
                    } else {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack {
                                Spacer()
                                
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                
                                VStack(alignment: .leading) {
                                    Text("Add Image")
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.primary)
                                    
                                    Text("Tap to select")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(AppTheme.Colors.secondaryBackground)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
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
                
                // Bottom padding to ensure content isn't hidden behind safe area
                Spacer(minLength: 16)
            }
            .padding(.top)
        }
        .background(AppTheme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveNote()
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
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    imageData = data
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
    
    private func saveNote() {
        // Convert attributedContent to Data for storage
        let rtfdData: Data?
        do {
            rtfdData = try attributedContent.data(
                from: NSRange(location: 0, length: attributedContent.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
            )
        } catch {
            print("Error converting attributed string to data: \(error)")
            rtfdData = nil
        }
        
        if let note = existingNote, mode == .edit {
            noteStore.update(
                note: note,
                title: title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: rtfdData,
                tagIDs: tagIDs
            )
        } else {
            noteStore.addNote(
                title: title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: rtfdData,
                tagIDs: tagIDs
            )
        }
    }
    
    private func applyFormatting(_ formatting: RichTextEditor.TextFormatting) {
        // Find the UITextView in the view hierarchy and apply formatting
        // This is a simplistic approach - in a real application, you would use a more robust method
        // to communicate with the RichTextEditor
        NotificationCenter.default.post(
            name: NSNotification.Name("ApplyRichTextFormatting"), 
            object: formatting
        )
    }
}

struct FormatButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.primary)
                .padding(8)
                .background(AppTheme.Colors.background)
                .cornerRadius(4)
        }
    }
}
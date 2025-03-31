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
    @State private var isFocusMode = false
    
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
                    attributes: [.font: UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)]
                ))
            }
        } else {
            // Set default attributed content for new notes
            _attributedContent = State(initialValue: NSAttributedString(
                string: "",
                attributes: [.font: UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)]
            ))
        }
    }
    
    var body: some View {
        ZStack {
            // Main editor content
            editorContent
                .opacity(isFocusMode ? 0.3 : 1.0)
            
            // Focus mode overlay (only visible when focus mode is active)
            if isFocusMode {
                VStack(spacing: 0) {
                    Spacer()
                    
                    RichTextEditor(
                        text: $attributedContent,
                        placeholder: "Type your note content here...",
                        onTextChange: { newText in
                            attributedContent = newText
                            content = newText.string
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Dimensions.spacing)
                    .background(AppTheme.Colors.focusBackground)
                    
                    Spacer()
                    
                    Button("Exit Focus Mode") {
                        withAnimation {
                            isFocusMode = false
                        }
                    }
                    .minimalButtonStyle()
                    .padding(.bottom)
                }
                .background(Color.black.opacity(0.02))
                .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if mode == .edit {
                    Button("Done") {
                        saveNote()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                } else {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text(mode == .new ? "New Note" : "Edit Note")
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveNote()
                    dismiss()
                }
                .foregroundColor(AppTheme.Colors.accent)
            }
        }
    }
    
    // Main editor content
    private var editorContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title field
                VStack(alignment: .leading, spacing: 0) {
                    Text("TITLE")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Dimensions.spacing)
                        .padding(.top, AppTheme.Dimensions.spacing)
                        .padding(.bottom, AppTheme.Dimensions.tinySpacing)
                    
                    TextField("Untitled", text: $title)
                        .font(AppTheme.Typography.editorTitle())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .padding(.horizontal, AppTheme.Dimensions.spacing)
                        .padding(.bottom, AppTheme.Dimensions.smallSpacing)
                }
                
                Divider()
                    .background(AppTheme.Colors.divider)
                
                // Content section
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("CONTENT")
                            .font(AppTheme.Typography.caption())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        HStack(spacing: AppTheme.Dimensions.smallSpacing) {
                            // Focus mode button
                            Button(action: {
                                withAnimation {
                                    isFocusMode = true
                                }
                            }) {
                                Image(systemName: "rectangle.expand.vertical")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            
                            // Formatting button
                            Button(action: {
                                withAnimation {
                                    isShowingFormatting.toggle()
                                }
                            }) {
                                Image(systemName: isShowingFormatting ? "textformat.alt" : "textformat")
                                    .font(.system(size: 14))
                                    .foregroundColor(isFocusMode ? AppTheme.Colors.textTertiary : 
                                                    (isShowingFormatting ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary))
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Dimensions.spacing)
                    .padding(.top, AppTheme.Dimensions.spacing)
                    .padding(.bottom, AppTheme.Dimensions.tinySpacing)
                    
                    // Rich text formatting toolbar (minimalist style)
                    if isShowingFormatting {
                        HStack(spacing: AppTheme.Dimensions.spacing) {
                            FormatButton(icon: "bold", action: {
                                applyFormatting(.bold)
                            })
                            
                            FormatButton(icon: "italic", action: {
                                applyFormatting(.italic)
                            })
                            
                            FormatButton(icon: "underline", action: {
                                applyFormatting(.underline)
                            })
                            
                            Divider()
                                .frame(height: 16)
                            
                            FormatButton(icon: "paintpalette", action: {
                                applyFormatting(.textColor(.blue))
                            })
                            
                            FormatButton(icon: "link", action: {
                                let url = URL(string: "https://example.com")!
                                applyFormatting(.insertLink(url, "Link"))
                            })
                            
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Dimensions.spacing)
                        .padding(.vertical, AppTheme.Dimensions.smallSpacing)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Rich Text Editor (monospaced, iA Writer style)
                    RichTextEditor(
                        text: $attributedContent,
                        placeholder: "Type your note content here...",
                        onTextChange: { newText in
                            attributedContent = newText
                            content = newText.string
                        }
                    )
                    .frame(minHeight: 200)
                    .padding(.horizontal, AppTheme.Dimensions.spacing)
                }
                
                Divider()
                    .background(AppTheme.Colors.divider)
                
                // Metadata section
                VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacing) {
                    // Image section
                    imageSection
                    
                    // Folder selection
                    folderSection
                    
                    // Tags section
                    tagSection
                }
                .padding(.vertical, AppTheme.Dimensions.spacing)
            }
        }
        .background(AppTheme.Colors.background)
    }
    
    // Image section
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
            Text("IMAGE")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Dimensions.spacing)
            
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .frame(maxWidth: .infinity)
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
                    .padding(.horizontal, AppTheme.Dimensions.spacing)
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        
                        Text("Add Image")
                            .font(AppTheme.Typography.body())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(AppTheme.Dimensions.smallSpacing)
                    .overlay(
                        Rectangle()
                            .stroke(AppTheme.Colors.divider, lineWidth: 1)
                    )
                    .padding(.horizontal, AppTheme.Dimensions.spacing)
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
    
    // Folder section
    private var folderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
            Text("FOLDER")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Dimensions.spacing)
            
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
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(AppTheme.Dimensions.smallSpacing)
                .overlay(
                    Rectangle()
                        .stroke(AppTheme.Colors.divider, lineWidth: 1)
                )
                .padding(.horizontal, AppTheme.Dimensions.spacing)
            }
        }
    }
    
    // Tags section
    private var tagSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
            Text("TAGS")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Dimensions.spacing)
            
            TagFilterView(selectedTagIds: Binding(
                get: { Set(tagIDs) },
                set: { tagIDs = Array($0) }
            ))
                .padding(.horizontal, AppTheme.Dimensions.spacing)
        }
    }
    
    private var selectedFolderName: String {
        if let id = selectedFolderID, let folder = folderStore.folders.first(where: { $0.id == id }) {
            return folder.name
        } else {
            return "None"
        }
    }
    
    private func applyFormatting(_ formatting: RichTextEditor.TextFormatting) {
        // Find the rich text editor and apply formatting
        NotificationCenter.default.post(
            name: Notification.Name("ApplyRichTextFormatting"),
            object: formatting
        )
    }
    
    private func saveNote() {
        // Create attributed content data
        let attributedContentData = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        
        if mode == .new {
            noteStore.addNote(
                title: title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: attributedContentData,
                tagIDs: tagIDs
            )
        } else if let note = existingNote {
            noteStore.update(
                note: note,
                title: title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: attributedContentData,
                tagIDs: tagIDs
            )
        }
    }
}

// Minimalist format button for the toolbar
struct FormatButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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
    @Environment(\.presentationMode) var presentationMode

    let mode: NoteEditorMode
    let existingNote: Note?
    
    // Flag to indicate if toolbar items should be shown
    // This helps avoid duplicate buttons when presented from MainView
    var showsToolbarItems: Bool = true
    
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
    init(mode: NoteEditorMode, existingNote: Note?, showsToolbarItems: Bool = true) {
        self.mode = mode
        self.existingNote = existingNote
        self.showsToolbarItems = showsToolbarItems
        
        if let note = existingNote, mode == .edit {
            _title = State(initialValue: note.title)
            _content = State(initialValue: note.content)
            _imageData = State(initialValue: note.imageData)
            _selectedFolderID = State(initialValue: note.folderID)
            _tagIDs = State(initialValue: note.tagIDs)
            
            // Initialize attributedContent from data if available
            if let attributedContentData = note.attributedContent,
               let attributedString = try? NSAttributedString(
                data: attributedContentData,
                options: [.documentType: NSAttributedString.DocumentType.rtfd],
                documentAttributes: nil
               ) {
                _attributedContent = State(initialValue: attributedString)
            } else {
                // Fallback to plain text content if no attributed content
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
            if showsToolbarItems {
                ToolbarItem(placement: .navigationBarLeading) {
                    CancelButton {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(mode == .new ? "New Note" : "Edit Note")
                        .font(AppTheme.Typography.headline())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    SaveButton {
                        saveNote()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Main editor content
    private var editorContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Dimensions.spacingL) {
                // Title field
                FormFieldView(label: "Title", iconName: "textformat") {
                    TextField("Note title", text: $title)
                        .font(AppTheme.Typography.title3())
                }
                
                // Content field
                FormFieldView(label: "Content", iconName: "text.justify") {
                    VStack(alignment: .trailing, spacing: AppTheme.Dimensions.smallSpacing) {
                        if isRichTextEditorAvailable() {
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
                        } else {
                            TextField("Note content", text: $content)
                                .font(AppTheme.Typography.body())
                                .padding(.horizontal, AppTheme.Dimensions.spacing)
                        }
                        
                        HStack {
                            Spacer()
                            
                            if !isFocusMode {
                                Button {
                                    withAnimation {
                                        isShowingFormatting.toggle()
                                    }
                                } label: {
                                    Label("Format", systemImage: "textformat")
                                        .font(AppTheme.Typography.caption())
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                            
                            Button {
                                withAnimation {
                                    isFocusMode.toggle()
                                }
                            } label: {
                                Label(
                                    isFocusMode ? "Exit Focus" : "Focus Mode",
                                    systemImage: isFocusMode ? "eye" : "eye.slash"
                                )
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                }
                
                // Image field
                FormFieldView(label: "Image", iconName: "photo") {
                    VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
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
                
                // Folder field
                FormFieldView(label: "Folder", iconName: "folder") {
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
                
                // Tags field
                FormFieldView(label: "Tags", iconName: "tag") {
                    TagFilterView(selectedTagIds: Binding(
                        get: { Set(tagIDs) },
                        set: { tagIDs = Array($0) }
                    ))
                    .padding(.horizontal, AppTheme.Dimensions.spacing)
                }
            }
            .padding(.vertical, AppTheme.Dimensions.spacingL)
        }
        .background(AppTheme.Colors.background)
    }
    
    private var selectedFolderName: String {
        if let id = selectedFolderID, let folder = folderStore.folders.first(where: { $0.id == id }) {
            return folder.name
        } else {
            return "None"
        }
    }
    
    private func isRichTextEditorAvailable() -> Bool {
        // Currently always returning true as rich text editing is supported
        // In the future, this could check for specific features or conditions
        return true
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

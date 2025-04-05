import SwiftUI
import PhotosUI
import UIKit

enum NoteEditorMode {
    case new
    case edit
}

enum NoteEditorPresentationMode {
    case standalone  // View adds its own toolbar items
    case embedded    // View doesn't add toolbar items (parent view handles it)
}

struct NoteEditorView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var tagStore: TagStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // Note data
    @State private var title: String
    @State private var content: String
    @State private var attributedContent: NSAttributedString
    @State private var isPinned: Bool
    @State private var selectedFolderID: UUID?
    @State private var tagIDs = [UUID]()
    
    // UI state
    @State private var showActionSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showImagePicker = false
    @State private var isFocusMode = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var activeFormatting = Set<TextFormatting>()
    @State private var animateChanges = false
    @State private var contentOpacity: CGFloat = 1
    @State private var showMetadata = false
    @State private var isTextSelected = false
    @State private var showFormattingToolbar = false
    @State private var toolbarPosition = CGPoint(x: 200, y: 200)
    @FocusState private var isEditorFocused: Bool
    
    let mode: NoteEditorMode
    let existingNote: Note?
    let presentationMode: NoteEditorPresentationMode
    
    init(mode: NoteEditorMode, existingNote: Note?, presentationMode: NoteEditorPresentationMode = .standalone) {
        self.mode = mode
        self.existingNote = existingNote
        self.presentationMode = presentationMode
        
        if let note = existingNote {
            _title = State(initialValue: note.title)
            _content = State(initialValue: note.content)
            _isPinned = State(initialValue: note.isPinned)
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
                    attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .regular)]
                ))
            }
            
            _imageData = State(initialValue: note.imageData)
        } else {
            _title = State(initialValue: "")
            _content = State(initialValue: "")
            _attributedContent = State(initialValue: NSAttributedString())
            _isPinned = State(initialValue: false)
            _selectedFolderID = State(initialValue: nil)
            _tagIDs = State(initialValue: [])
            _imageData = State(initialValue: nil)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Title field - always visible
                    titleField
                        .padding(.horizontal, isFocusMode ? 16 : 20)
                        .padding(.top, isFocusMode ? 8 : 16)
                        .padding(.bottom, 8)
                        .background(
                            AppTheme.Colors.background
                                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.1), 
                                        radius: isFocusMode ? 0 : 3, 
                                        x: 0, 
                                        y: 1)
                        )
                        .zIndex(1)
                    
                    // Content area
                    ScrollView {
                        VStack(spacing: 0) {
                            // Main editor
                            contentEditor
                                .padding(.horizontal, isFocusMode ? 16 : 20)
                                .padding(.vertical, isFocusMode ? 8 : 16)
                                .animation(.easeInOut(duration: 0.3), value: isFocusMode)
                            
                            // Collapsible metadata section
                            if !isFocusMode {
                                metadataSection
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                isEditorFocused = true
                            }
                    )
                }
                
                // Floating formatting toolbar
                if showFormattingToolbar && isTextSelected {
                    floatingFormattingToolbar
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 3)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                        .zIndex(100)
                }
                
                // Focus mode toggle button
                focusModeButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
            .onChange(of: isEditorFocused) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFormattingToolbar = newValue && isTextSelected
                }
            }
        }
        .navigationBarTitle(isFocusMode ? "" : mode == .new ? "New Note" : "Edit Note", displayMode: .inline)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if presentationMode == .standalone {
                ToolbarItem(placement: .principal) {
                    Text(isFocusMode ? title : "")
                        .font(AppTheme.Typography.headline().bold())
                        .opacity(isFocusMode ? 0.7 : 1)
                        .lineLimit(1)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveNoteWithAnimation) {
                        Text("Save")
                            .font(AppTheme.Typography.button())
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if mode == .edit {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(AppTheme.Colors.danger)
                        }
                    } else {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateChanges = true
                }
            }
            
            // Add observer for save requests from parent views
            if presentationMode == .embedded {
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("SaveNoteFromParent"),
                    object: nil,
                    queue: .main
                ) { _ in
                    // Use a separate action to handle the save operation
                    // This prevents modifying state during view update
                    DispatchQueue.main.async {
                        self.saveNoteWithAnimation()
                    }
                }
            }
        }
        .onDisappear {
            // Remove observer when view disappears
            if presentationMode == .embedded {
                NotificationCenter.default.removeObserver(
                    self,
                    name: Notification.Name("SaveNoteFromParent"),
                    object: nil
                )
            }
        }
        .confirmationDialog("Are you sure you want to delete this note?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let note = existingNote {
                    noteStore.delete(note: note)
                    
                    dismiss()
                    
                    // Haptic feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - UI Components
    
    private var titleField: some View {
        TextField("Note title", text: $title)
            .font(AppTheme.Typography.title3().bold())
            .foregroundColor(AppTheme.Colors.textPrimary)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color.clear)
            .contentShape(Rectangle())
    }
    
    private var contentEditor: some View {
        ZStack(alignment: .topLeading) {
            RichTextEditor(
                text: $attributedContent,
                placeholder: "Write something...",
                onTextChange: { newText in
                    attributedContent = newText
                    content = newText.string
                    
                    // Check if text is selected to show the formatting toolbar
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isTextSelected = newText.length > 0 && isEditorFocused
                        showFormattingToolbar = isTextSelected
                    }
                },
                activeFormatting: $activeFormatting
            )
            .padding(isFocusMode ? 0 : 8)
            .background(isFocusMode ? Color.clear : AppTheme.Colors.secondaryBackground.opacity(0.3))
            .cornerRadius(isFocusMode ? 0 : 12)
            .focused($isEditorFocused)
            .opacity(contentOpacity)
            .onChange(of: isFocusMode) { _, newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    contentOpacity = newValue ? 1 : 0.95
                }
            }
        }
        .frame(minHeight: 300)
        .animation(.easeInOut(duration: 0.3), value: isFocusMode)
    }
    
    private var metadataSection: some View {
        VStack(spacing: 16) {
            // Metadata header with toggle
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showMetadata.toggle()
                }
            }) {
                HStack {
                    Text("Details")
                        .font(AppTheme.Typography.subheadline().bold())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Image(systemName: showMetadata ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if showMetadata {
                VStack(spacing: 20) {
                    // Tags section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(AppTheme.Typography.caption())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        TagFilterView(selectedTagIds: Binding(
                            get: { Set(tagIDs) },
                            set: { tagIDs = Array($0) }
                        ))
                        .padding(12)
                        .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
                        .cornerRadius(12)
                    }
                    
                    // Folder section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Folder")
                            .font(AppTheme.Typography.caption())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
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
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .padding(12)
                            .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Image section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image")
                            .font(AppTheme.Typography.caption())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                    .transition(.opacity)
                                
                                Button(action: {
                                    withAnimation {
                                        self.imageData = nil
                                        self.selectedItem = nil
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                        .font(.system(size: 20))
                                }
                                .padding(8)
                            }
                        } else {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                HStack {
                                    Spacer()
                                    Label("Add Image", systemImage: "photo")
                                        .font(AppTheme.Typography.body())
                                        .foregroundColor(AppTheme.Colors.accent)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
                                .cornerRadius(12)
                            }
                            .onChange(of: selectedItem) { oldValue, newValue in
                                if let newValue {
                                    Task {
                                        if let data = try? await newValue.loadTransferable(type: Data.self) {
                                            imageData = data
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.bottom, 8)
            }
        }
        .padding(16)
        .background(AppTheme.Colors.secondaryBackground.opacity(0.3))
        .cornerRadius(16)
        .onAppear {
            // Start with metadata hidden for a cleaner look
            showMetadata = false
        }
    }
    
    private var floatingFormattingToolbar: some View {
        HStack(spacing: 8) {
            FormatButton(icon: "bold", action: {
                applyFormatting(.bold)
            }, isActive: activeFormatting.contains(.bold))
            
            FormatButton(icon: "italic", action: {
                applyFormatting(.italic)
            }, isActive: activeFormatting.contains(.italic))
            
            FormatButton(icon: "underline", action: {
                applyFormatting(.underline)
            }, isActive: activeFormatting.contains(.underline))
            
            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)
            
            FormatButton(icon: "text.alignleft", action: {
                applyFormatting(.alignLeft)
            }, isActive: activeFormatting.contains(.alignLeft))
            
            FormatButton(icon: "text.aligncenter", action: {
                applyFormatting(.alignCenter)
            }, isActive: activeFormatting.contains(.alignCenter))
            
            FormatButton(icon: "text.alignright", action: {
                applyFormatting(.alignRight)
            }, isActive: activeFormatting.contains(.alignRight))
            
            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)
            
            FormatButton(icon: "list.bullet", action: {
                applyFormatting(.bulletList)
            }, isActive: activeFormatting.contains(.bulletList))
            
            FormatButton(icon: "list.number", action: {
                applyFormatting(.numberedList)
            }, isActive: activeFormatting.contains(.numberedList))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.secondaryBackground)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2), 
                        radius: 10, x: 0, y: 4)
        )
    }
    
    private var focusModeButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isFocusMode.toggle()
                    }
                    
                    // Haptic feedback
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Image(systemName: isFocusMode ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            Circle()
                                .fill(AppTheme.Colors.accent)
                                .shadow(color: AppTheme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .opacity(animateChanges ? 1 : 0)
                .scaleEffect(animateChanges ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: animateChanges)
            }
        }
    }
    
    private var selectedFolderName: String {
        if let id = selectedFolderID, let folder = folderStore.folders.first(where: { $0.id == id }) {
            return folder.name
        }
        return "None"
    }
    
    // MARK: - Actions
    
    private func saveNoteWithAnimation() {
        // Create haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Create attributed content data
        let attributedContentData = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        
        // Validate input - ensure title is not empty
        let finalTitle = title.isEmpty ? "Untitled Note" : title
        
        // Use a separate action to handle state changes
        let saveAction = {
            if self.mode == .new {
                // Add new note
                self.noteStore.addNote(
                    title: finalTitle,
                    content: self.content,
                    folderID: self.selectedFolderID,
                    imageData: self.imageData,
                    attributedContent: attributedContentData,
                    tagIDs: self.tagIDs
                )
            } else if let note = self.existingNote {
                // Update existing note
                self.noteStore.update(
                    note: note,
                    title: finalTitle,
                    content: self.content,
                    folderID: self.selectedFolderID,
                    imageData: self.imageData,
                    attributedContent: attributedContentData,
                    tagIDs: self.tagIDs
                )
            }
            
            // Only dismiss if in standalone mode
            if self.presentationMode == .standalone {
                self.dismiss()
            }
        }
        
        // Execute the save action with animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            saveAction()
        }
    }
    
    private func applyFormatting(_ formatting: TextFormatting) {
        if activeFormatting.contains(formatting) {
            activeFormatting.remove(formatting)
        } else {
            activeFormatting.insert(formatting)
            
            // Handle mutually exclusive formatting options
            if formatting == .alignLeft {
                activeFormatting.remove(.alignCenter)
                activeFormatting.remove(.alignRight)
            } else if formatting == .alignCenter {
                activeFormatting.remove(.alignLeft)
                activeFormatting.remove(.alignRight)
            } else if formatting == .alignRight {
                activeFormatting.remove(.alignLeft)
                activeFormatting.remove(.alignCenter)
            }
        }
        
        // Sync with RichTextEditor
        syncFormattingToRichTextEditor(formatting)
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // Update formatting in the RichTextEditor
    private func syncFormattingToRichTextEditor(_ formatting: TextFormatting) {
        // The formatting is already updated in the activeFormatting Set
        // which is directly bound to the editor, so no additional conversion needed
        
        // Post notification to apply formatting
        let notificationName = Notification.Name("ApplyRichTextFormatting")
        NotificationCenter.default.post(name: notificationName, object: formatting)
    }
}

// MARK: - Supporting Views

// Triangle shape for the floating toolbar
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

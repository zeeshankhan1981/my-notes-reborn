import SwiftUI
import PhotosUI
import UIKit

enum NoteEditorMode {
    case new
    case edit
}

struct NoteEditorView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var tagStore: TagStore
    @Environment(\.dismiss) var dismiss
    
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
    
    let mode: NoteEditorMode
    let existingNote: Note?
    
    init(mode: NoteEditorMode, existingNote: Note?) {
        self.mode = mode
        self.existingNote = existingNote
        
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
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()

            // Regular editor mode
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        titleSection
                            .opacity(animateChanges ? 1 : 0)
                            .offset(y: animateChanges ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateChanges)

                        formattingToolbar
                            .opacity(animateChanges ? 1 : 0)
                            .offset(y: animateChanges ? 0 : -10)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.05), value: animateChanges)
                    }

                    contentSection
                        .opacity(animateChanges ? 1 : 0)
                        .offset(y: animateChanges ? 0 : 30)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(isFocusMode ? 0 : 0.1),
                            value: animateChanges
                        )

                    if !isFocusMode {
                        tagSection
                            .opacity(animateChanges ? 1 : 0)
                            .offset(y: animateChanges ? 0 : 40)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: animateChanges)

                        folderSection
                            .opacity(animateChanges ? 1 : 0)
                            .offset(y: animateChanges ? 0 : 50)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animateChanges)

                        imageSection
                            .opacity(animateChanges ? 1 : 0)
                            .offset(y: animateChanges ? 0 : 60)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: animateChanges)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            // Focus mode toggle button
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
                            .background(AppTheme.Colors.accent)
                            .clipShape(Circle())
                            .shadow(color: AppTheme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .offset(y: -20)
                    .padding(.trailing, 20)
                    .opacity(animateChanges ? 1 : 0)
                    .scaleEffect(animateChanges ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: animateChanges)
                }
            }
        }
        .navigationBarTitle(isFocusMode ? "" : mode == .new ? "New Note" : "Edit Note", displayMode: .inline)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isFocusMode ? title : "")
                    .font(AppTheme.Typography.headline().bold())
                    .opacity(isFocusMode ? 0.7 : 1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                SaveButton(action: saveNoteWithAnimation)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                if mode == .edit {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(AppTheme.Colors.danger)
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

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)

            TextField("Note title", text: $title)
                .font(AppTheme.Typography.title3().bold())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(16)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(12)
                .shadow(color: AppTheme.Colors.cardShadow.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }

    private var formattingToolbar: some View {
        HStack(spacing: 14) {
            FormatButton(icon: "bold", action: {
                applyFormatting(.bold)
            }, isActive: activeFormatting.contains(.bold))

            FormatButton(icon: "italic", action: {
                applyFormatting(.italic)
            }, isActive: activeFormatting.contains(.italic))

            FormatButton(icon: "underline", action: {
                applyFormatting(.underline)
            }, isActive: activeFormatting.contains(.underline))

            Spacer()

            FormatButton(icon: "text.alignleft", action: {
                applyFormatting(.alignLeft)
            }, isActive: activeFormatting.contains(.alignLeft))

            FormatButton(icon: "text.aligncenter", action: {
                applyFormatting(.alignCenter)
            }, isActive: activeFormatting.contains(.alignCenter))

            FormatButton(icon: "text.alignright", action: {
                applyFormatting(.alignRight)
            }, isActive: activeFormatting.contains(.alignRight))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.Colors.secondaryBackground.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: AppTheme.Colors.cardShadow.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !isFocusMode {
                Text("Content")
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.leading, 4)
            }

            ZStack(alignment: .topLeading) {
                RichTextEditor(
                    text: $attributedContent,
                    placeholder: "Write something...",
                    onTextChange: { newText in
                        attributedContent = newText
                        content = newText.string
                    },
                    activeFormatting: $activeFormatting
                )
                .padding(16)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(12)
                .opacity(contentOpacity)
                .onChange(of: isFocusMode) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        contentOpacity = newValue ? 0.8 : 1
                    }
                }
            }
            .frame(minHeight: isFocusMode ? 300 : 200)
        }
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)

            TagFilterView(selectedTagIds: Binding(
                get: { Set(tagIDs) },
                set: { tagIDs = Array($0) }
            ))
            .padding(12)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
    }

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Folder")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)

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
                .padding(16)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(12)
            }
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)

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
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.divider, lineWidth: 1)
                    )
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
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            // Validate input - ensure title is not empty
            let finalTitle = title.isEmpty ? "Untitled Note" : title
            
            if mode == .new {
                // Add new note
                noteStore.addNote(
                    title: finalTitle,
                    content: content,
                    folderID: selectedFolderID,
                    imageData: imageData,
                    attributedContent: attributedContentData,
                    tagIDs: tagIDs
                )
            } else if let note = existingNote {
                // Update existing note
                noteStore.update(
                    note: note,
                    title: finalTitle,
                    content: content,
                    folderID: selectedFolderID,
                    imageData: imageData,
                    attributedContent: attributedContentData,
                    tagIDs: tagIDs
                )
            }
            
            dismiss()
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

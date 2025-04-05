import SwiftUI
import PhotosUI
import UIKit

enum NoteEditorMode {
    case new
    case edit
}

enum NoteEditorPresentationMode: Equatable {
    case standalone  // View adds its own toolbar items
    case embedded    // View doesn't add toolbar items (parent view handles it)
}

struct NoteEditorView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var tagStore: TagStore
    @Environment(\.dismiss) var environmentDismiss
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
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showFormatOptions = false
    @State private var showImagePicker = false
    @FocusState private var isEditorFocused: Bool
    @FocusState private var isTitleFocused: Bool
    
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
            _tagIDs = State(initialValue: note.tagIDs ?? [])
            
            if let attributedContentData = note.attributedContent,
               let attributedString = try? NSAttributedString(
                data: attributedContentData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil) {
                _attributedContent = State(initialValue: attributedString)
            } else {
                let string = NSAttributedString(string: note.content)
                _attributedContent = State(initialValue: string)
            }
            
            if let imageData = note.imageData {
                _imageData = State(initialValue: imageData)
            } else {
                _imageData = State(initialValue: nil)
            }
        } else {
            _title = State(initialValue: "")
            _content = State(initialValue: "")
            _attributedContent = State(initialValue: NSAttributedString(string: ""))
            _isPinned = State(initialValue: false)
            _selectedFolderID = State(initialValue: nil)
            _imageData = State(initialValue: nil)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Content area with Bear-style red line on left
                HStack(alignment: .top, spacing: 0) {
                    // Red vertical line like in Bear app
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2)
                    
                    // Content area
                    VStack(alignment: .leading, spacing: 0) {
                        // Title field
                        TextField("Title", text: $title)
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            .focused($isTitleFocused)
                        
                        // Content field - simple text editor
                        TextEditor(text: $content)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 16)
                            .focused($isEditorFocused)
                            .onChange(of: content) { _, newValue in
                                // Update attributed content
                                let attributedString = NSMutableAttributedString(string: newValue)
                                attributedString.addAttributes(
                                    [.font: UIFont.preferredFont(forTextStyle: .body)],
                                    range: NSRange(location: 0, length: newValue.count)
                                )
                                attributedContent = attributedString
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Formatting and image buttons at the bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // Format button with popover
                    Button(action: {
                        showFormatOptions.toggle()
                    }) {
                        Image(systemName: "textformat")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    .popover(isPresented: $showFormatOptions, arrowEdge: .bottom) {
                        FormatOptionsView(content: $content)
                            .frame(width: 300, height: 200)
                            .padding()
                    }
                    .padding(.trailing, 8)
                    
                    // Image picker button
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "photo")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                imageData = data
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Show image if selected
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                VStack {
                    Spacer()
                    
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            )
                            .padding()
                        
                        Button(action: {
                            withAnimation {
                                self.imageData = nil
                                self.selectedItem = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(24)
                    }
                    
                    Spacer()
                }
                .background(Color.black.opacity(0.5))
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    environmentDismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text(mode == .new ? "New Note" : "Edit Note")
                    .font(.headline)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveNote()
                    environmentDismiss()
                }) {
                    Text("Done")
                        .foregroundColor(AppTheme.Colors.accent)
                        .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            // Auto-focus the title field if it's a new note
            if mode == .new {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTitleFocused = true
                }
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Note"),
                message: Text("Are you sure you want to delete this note?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteNote()
                    environmentDismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Actions
    
    private func saveNote() {
        // Create haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Create attributed content data
        let attributedContentData = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        
        if let existingNote = existingNote {
            // Update existing note
            noteStore.update(
                note: existingNote,
                title: title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: attributedContentData,
                tagIDs: tagIDs
            )
        } else {
            // Create new note
            noteStore.addNote(
                title: title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: attributedContentData,
                tagIDs: tagIDs
            )
        }
    }
    
    private func deleteNote() {
        if let note = existingNote {
            noteStore.delete(note: note)
        }
    }
}

// MARK: - Format Options View
struct FormatOptionsView: View {
    @Binding var content: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Text Formatting")
                .font(.headline)
                .padding(.top, 8)
            
            HStack(spacing: 20) {
                FormatOptionButton(title: "Bold", icon: "bold", action: { applyBold() })
                FormatOptionButton(title: "Italic", icon: "italic", action: { applyItalic() })
                FormatOptionButton(title: "Underline", icon: "underline", action: { applyUnderline() })
            }
            
            HStack(spacing: 20) {
                FormatOptionButton(title: "Heading", icon: "text.heading", action: { applyHeading() })
                FormatOptionButton(title: "List", icon: "list.bullet", action: { applyList() })
                FormatOptionButton(title: "Quote", icon: "text.quote", action: { applyQuote() })
            }
            
            Spacer()
        }
        .padding()
    }
    
    // These are placeholder functions - in a real app, you'd implement proper formatting
    private func applyBold() {}
    private func applyItalic() {}
    private func applyUnderline() {}
    private func applyHeading() {}
    private func applyList() {}
    private func applyQuote() {}
}

struct FormatOptionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .padding(10)
                    .background(Circle().fill(Color(.systemGray5)))
                
                Text(title)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

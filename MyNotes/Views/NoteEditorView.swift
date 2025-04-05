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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    environmentDismiss()
                }) {
                    Image(systemName: "chevron.left")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveNote()
                    environmentDismiss()
                }) {
                    Text("Done")
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

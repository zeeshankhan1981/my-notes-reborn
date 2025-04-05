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
    @State private var tagIDs: [UUID]
    
    // UI state
    @State private var showActionSheet = false
    @State private var showDeleteConfirmation = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showFormatOptions = false
    @State private var isEditing = true
    @State private var activeFormatting: Set<TextFormatting> = []
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
            _tagIDs = State(initialValue: note.tagIDs)
            
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
            _tagIDs = State(initialValue: [])
            _imageData = State(initialValue: nil)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
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
                        
                        // Content field - using BasicTextEditor
                        BasicTextEditor(
                            text: $content,
                            attributedText: $attributedContent,
                            placeholder: "Start writing...",
                            isEditing: $isEditing
                        )
                        .padding(.horizontal, 16)
                        .focused($isEditorFocused)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Bottom formatting buttons - similar to Bear Notes
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // Format button
                    Button(action: {
                        showFormatOptions.toggle()
                    }) {
                        Image(systemName: "textformat")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    .padding(.trailing, 8)
                    
                    // Image picker button
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "photo")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
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
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            self.imageData = nil
                            self.selectedItem = nil
                        }
                    }
                
                VStack {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 300)
                            .cornerRadius(8)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
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
                }
                .transition(.opacity)
                .zIndex(10)
            }
            
            // Format options sheet
            if showFormatOptions {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showFormatOptions = false
                    }
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("Text Formatting")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        HStack(spacing: 30) {
                            FormatOptionButton(formatting: .bold, isActive: activeFormatting.contains(.bold)) {
                                applyFormatting(.bold)
                            }
                            FormatOptionButton(formatting: .italic, isActive: activeFormatting.contains(.italic)) {
                                applyFormatting(.italic)
                            }
                            FormatOptionButton(formatting: .underline, isActive: activeFormatting.contains(.underline)) {
                                applyFormatting(.underline)
                            }
                        }
                        
                        HStack(spacing: 30) {
                            FormatOptionButton(formatting: .heading, isActive: activeFormatting.contains(.heading)) {
                                applyFormatting(.heading)
                            }
                            FormatOptionButton(formatting: .list, isActive: activeFormatting.contains(.list)) {
                                applyFormatting(.list)
                            }
                            FormatOptionButton(formatting: .quote, isActive: activeFormatting.contains(.quote)) {
                                applyFormatting(.quote)
                            }
                        }
                        
                        Spacer()
                            .frame(height: 16)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding()
                }
                .transition(.move(edge: .bottom))
                .zIndex(20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if presentationMode == .standalone {
                // Leading toolbar items
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        environmentDismiss()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                }
                
                // Trailing toolbar items
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if mode == .edit {
                            Menu {
                                Button(action: {
                                    isPinned.toggle()
                                    if let note = existingNote {
                                        noteStore.togglePin(note: note)
                                    }
                                }) {
                                    Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
                                }
                                
                                Button(role: .destructive, action: {
                                    showDeleteConfirmation = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .padding(.trailing, 8)
                        }
                        
                        Button("Done") {
                            saveNote()
                            environmentDismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            if title.isEmpty {
                isTitleFocused = true
            } else {
                isEditorFocused = true
            }
        }
        .alert("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let note = existingNote {
                    noteStore.delete(note: note)
                    environmentDismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
    
    // MARK: - Actions
    
    private func saveNote() {
        // Create attributed content data for storage
        let attributedContentData = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        
        if mode == .new {
            noteStore.addNote(
                title: title.isEmpty ? "Untitled" : title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: attributedContentData,
                tagIDs: tagIDs
            )
        } else if let note = existingNote {
            noteStore.update(
                note: note,
                title: title.isEmpty ? "Untitled" : title,
                content: content,
                folderID: selectedFolderID,
                imageData: imageData,
                attributedContent: attributedContentData,
                tagIDs: tagIDs
            )
        }
    }
    
    // Apply formatting to the text
    private func applyFormatting(_ formatting: TextFormatting) {
        // Simplified formatting approach for BasicTextEditor
        // We'll store the formatting in our activeFormatting set
        if activeFormatting.contains(formatting) {
            activeFormatting.remove(formatting)
        } else {
            activeFormatting.insert(formatting)
        }
        
        // For a real implementation, you would update attributedContent here
        // Currently, BasicTextEditor doesn't fully support rich text formatting
        // so this is mostly UI feedback for the formatting buttons
        
        // Close the formatting panel after selection
        showFormatOptions = false
    }
}

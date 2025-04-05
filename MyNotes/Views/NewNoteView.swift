import SwiftUI

// Remove duplicate declarations since they're now in TextEditorComponents.swift

struct NewNoteView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var tagStore: TagStore
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var content = NSAttributedString()
    @State private var selectedFolderID: UUID?
    @State private var tagIDs: [UUID] = []
    @State private var showingFolderPicker = false
    @State private var animateIn = false
    @State private var activeFormatting = Set<TextFormatting>()
    @FocusState private var focusField: Field?
    
    enum Field {
        case title, content
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                // Content
                HStack(alignment: .top, spacing: 0) {
                    // Red vertical line like in Bear app
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2)
                    
                    // Main content area
                    VStack(alignment: .leading, spacing: 0) {
                        // Title field
                        TextField("Title", text: $title)
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            .focused($focusField, equals: .title)
                        
                        // Content field - simple text editor
                        TextEditor(text: Binding(
                            get: { content.string },
                            set: { newValue in
                                let attributedString = NSMutableAttributedString(string: newValue)
                                attributedString.addAttributes(
                                    [.font: UIFont.preferredFont(forTextStyle: .body)],
                                    range: NSRange(location: 0, length: newValue.count)
                                )
                                content = attributedString
                            }
                        ))
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minHeight: 300)
                        .focused($focusField, equals: .content)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveNote()
                        }
                        .disabled(title.isEmpty && content.string.isEmpty)
                    }
                }
                .onAppear {
                    // Auto-focus the title field when the view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        focusField = .title
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveNote() {
        // Create attributed content data
        let attributedContentData = try? content.data(
            from: NSRange(location: 0, length: content.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        
        // Add the new note to the store
        noteStore.addNote(
            title: title,
            content: content.string,
            folderID: selectedFolderID,
            imageData: nil,
            attributedContent: attributedContentData,
            tagIDs: tagIDs
        )
        
        // Dismiss the view
        isPresented = false
    }
}

struct NewNoteView_Previews: PreviewProvider {
    static var previews: some View {
        NewNoteView(isPresented: .constant(true))
            .environmentObject(NoteStore())
            .environmentObject(FolderStore())
            .environmentObject(TagStore())
    }
}

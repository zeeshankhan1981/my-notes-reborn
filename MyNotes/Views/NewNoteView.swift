import SwiftUI
import PhotosUI

struct NewNoteView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var tagStore: TagStore
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var content = NSAttributedString()
    @State private var selectedFolderID: UUID?
    @State private var tagIDs: [UUID] = []
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showFormatOptions = false
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
                            FormatOptionsView(content: Binding(
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Left side - Cancel button
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(AppTheme.Colors.accent)
            }
            
            // Center - Title
            ToolbarItem(placement: .principal) {
                Text("New Note")
                    .font(.headline)
            }
            
            // Right side - Save button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveNote()
                }
                .disabled(title.isEmpty && content.string.isEmpty)
                .foregroundColor(title.isEmpty && content.string.isEmpty ? AppTheme.Colors.textTertiary : AppTheme.Colors.accent)
                .fontWeight(.medium)
            }
        }
        .onAppear {
            // Auto-focus the title field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusField = .title
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveNote() {
        // Create attributed content data
        let attributedContentData = try? content.data(
            from: NSRange(location: 0, length: content.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        
        // Add the new note to the store
        noteStore.addNote(
            title: title,
            content: content.string,
            folderID: selectedFolderID,
            imageData: imageData,
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

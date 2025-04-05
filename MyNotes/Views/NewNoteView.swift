import SwiftUI
import PhotosUI

struct NewNoteView: View {
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var folderStore: FolderStore
    @EnvironmentObject var tagStore: TagStore
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var content = ""
    @State private var attributedContent = NSAttributedString()
    @State private var selectedFolderID: UUID?
    @State private var tagIDs: [UUID] = []
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showFormatOptions = false
    @State private var isEditing = true
    @State private var activeFormatting: Set<TextFormatting> = []
    @FocusState private var focusField: Field?
    
    enum Field {
        case title, content
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(.systemBackground)
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
                        
                        // Content field - using BasicTextEditor
                        BasicTextEditor(
                            text: $content,
                            attributedText: $attributedContent,
                            placeholder: "Start writing...",
                            isEditing: $isEditing
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minHeight: 300)
                        .focused($focusField, equals: .content)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveNote()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                // Focus the title field when the view appears
                focusField = .title
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveNote() {
        // Create attributed content data
        let attributedContentData = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        
        // Add the new note to the store
        noteStore.addNote(
            title: title.isEmpty ? "Untitled" : title,
            content: content,
            folderID: selectedFolderID,
            imageData: imageData,
            attributedContent: attributedContentData,
            tagIDs: tagIDs
        )
        
        // Dismiss the view
        isPresented = false
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

struct NewNoteView_Previews: PreviewProvider {
    static var previews: some View {
        NewNoteView(isPresented: .constant(true))
            .environmentObject(NoteStore())
            .environmentObject(FolderStore())
            .environmentObject(TagStore())
    }
}

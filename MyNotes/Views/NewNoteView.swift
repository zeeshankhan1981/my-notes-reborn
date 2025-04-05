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
                ScrollView {
                    VStack(spacing: 24) {
                        // Title field with animation
                        titleField
                            .padding(.top, 16)
                        
                        // Content field
                        contentField
                        
                        // Additional fields
                        tagsField
                        
                        folderField
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .background(AppTheme.Colors.background)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Cancel button
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isPresented = false
                            }
                        }
                        .foregroundColor(AppTheme.Colors.accent)
                    }
                    
                    // Save button
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            saveNoteWithAnimation()
                        }
                        .disabled(title.isEmpty)
                        .foregroundColor(title.isEmpty ? AppTheme.Colors.textSecondary : AppTheme.Colors.accent)
                        .fontWeight(.semibold)
                    }
                }
                .navigationTitle("New Note")
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        animateIn = true
                    }
                    
                    // Auto-focus the title field
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        focusField = .title
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)
            
            TextField("Enter note title", text: $title)
                .font(AppTheme.Typography.title3().bold())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(16)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(12)
                .shadow(color: AppTheme.Colors.cardShadow.opacity(0.05), radius: 2, x: 0, y: 1)
                .focused($focusField, equals: .title)
                .submitLabel(.next)
                .onSubmit {
                    focusField = .content
                }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    private var contentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Content")
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                FormatButton(icon: "bold", action: {
                    applyFormatting(.bold)
                }, isActive: activeFormatting.contains(.bold))
                
                FormatButton(icon: "italic", action: {
                    applyFormatting(.italic)
                }, isActive: activeFormatting.contains(.italic))
                
                FormatButton(icon: "underline", action: {
                    applyFormatting(.underline)
                }, isActive: activeFormatting.contains(.underline))
                
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
            .padding(.horizontal, 4)
            
            RichTextEditor(
                text: $content,
                placeholder: "Write something...",
                onTextChange: { newText in
                    content = newText
                },
                activeFormatting: $activeFormatting
            )
            .frame(minHeight: 200)
            .padding(16)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(12)
            .shadow(color: AppTheme.Colors.cardShadow.opacity(0.05), radius: 2, x: 0, y: 1)
            .focused($focusField, equals: .content)
            .onAppear {
                // Set up notification observer for formatting changes
                let notificationName = Notification.Name("ApplyRichTextFormatting")
                NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: .main) { notification in
                    if let formatting = notification.object as? TextFormatting {
                        syncFormattingToRichTextEditor(formatting)
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: animateIn)
    }
    
    private var tagsField: some View {
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
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateIn)
    }
    
    private var folderField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Folder")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.leading, 4)
            
            Button(action: {
                showingFolderPicker = true
            }) {
                HStack {
                    if let folderID = selectedFolderID,
                       let folder = folderStore.getFolder(id: folderID) {
                        Label(folder.name, systemImage: "folder.fill")
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    } else {
                        Label("Select Folder", systemImage: "folder")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding(16)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.divider, lineWidth: 1)
                )
            }
            .sheet(isPresented: $showingFolderPicker) {
                EnhancedFolderPickerView(selectedFolderID: $selectedFolderID, showingPicker: $showingFolderPicker)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 50)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: animateIn)
    }
    
    private var formattingBar: some View {
        EmptyView()
    }
    
    // MARK: - Actions
    
    private func saveNoteWithAnimation() {
        // Create haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Create attributed content data
        let attributedContentData = try? content.data(
            from: NSRange(location: 0, length: content.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        
        // Animate out
        withAnimation(.easeInOut(duration: 0.2)) {
            animateIn = false
        }
        
        // Save with a slight delay to allow animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
    
    private func applyFormatting(_ formatting: TextFormatting) {
        if activeFormatting.contains(formatting) {
            activeFormatting.remove(formatting)
        } else {
            activeFormatting.insert(formatting)
        }
        
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
        
        // Sync with RichTextEditor
        syncFormattingToRichTextEditor(formatting)
        
        // Post notification to apply formatting
        let notificationName = Notification.Name("ApplyRichTextFormatting")
        NotificationCenter.default.post(name: notificationName, object: formatting)
        
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

// Enhanced folder picker with animations and improved UI
struct EnhancedFolderPickerView: View {
    @EnvironmentObject var folderStore: FolderStore
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFolderID: UUID?
    @Binding var showingPicker: Bool
    @State private var animateItems = false
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    withAnimation {
                        selectedFolderID = nil
                        dismiss()
                    }
                }) {
                    HStack {
                        Label("None", systemImage: "tray")
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        if selectedFolderID == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                    }
                }
                .listRowBackground(selectedFolderID == nil ? AppTheme.Colors.selectedRowBackground : Color.clear)
                
                ForEach(folderStore.folders) { folder in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFolderID = folder.id
                            dismiss()
                        }
                    }) {
                        HStack {
                            Label(folder.name, systemImage: "folder.fill")
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            if selectedFolderID == folder.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.Colors.accent)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .listRowBackground(selectedFolderID == folder.id ? AppTheme.Colors.selectedRowBackground : Color.clear)
                    .contentShape(Rectangle())
                    .opacity(animateItems ? 1 : 0)
                    .offset(y: animateItems ? 0 : 10)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(folder.id.hashValue % 10) * 0.03), value: animateItems)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Select Folder", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingPicker = false
                    }
                }
                .fontWeight(.semibold)
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        animateItems = true
                    }
                }
            }
        }
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

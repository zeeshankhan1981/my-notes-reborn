import SwiftUI

struct FolderManagerView: View {
    @EnvironmentObject var folderStore: FolderStore
    @State private var newFolder = ""
    @State private var showingAddFolder = false
    @State private var showingDeleteConfirmation = false
    @State private var folderToDelete: Folder?

    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Folder list
                List {
                    // Active folders
                    if !folderStore.folders.isEmpty {
                        Section {
                            ForEach(folderStore.folders) { folder in
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(AppTheme.Colors.primary)
                                        .font(.system(size: 18))
                                        .frame(width: 24)
                                    
                                    Text(folder.name)
                                        .font(AppTheme.Typography.body())
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        folderToDelete = folder
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(AppTheme.Colors.error)
                                            .font(.system(size: 16))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel("Delete folder \(folder.name)")
                                }
                                .padding(.vertical, AppTheme.Dimensions.spacingXS)
                            }
                        } header: {
                            Text("Your Folders")
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    } else {
                        // Empty state
                        Section {
                            VStack(spacing: AppTheme.Dimensions.spacingM) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                    .padding(.top, AppTheme.Dimensions.spacingL)
                                
                                Text("No Folders Yet")
                                    .font(AppTheme.Typography.title3())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Text("Create folders to organize your notes and checklists")
                                    .font(AppTheme.Typography.body())
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, AppTheme.Dimensions.spacingL)
                                
                                Button {
                                    showingAddFolder = true
                                } label: {
                                    Text("Create New Folder")
                                        .font(AppTheme.Typography.headline())
                                        .foregroundColor(AppTheme.Colors.primary)
                                        .padding(.vertical, AppTheme.Dimensions.spacingS)
                                }
                                .padding(.top, AppTheme.Dimensions.spacingM)
                                .accessibilityLabel("Create a new folder")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Dimensions.spacingL)
                            .listRowBackground(AppTheme.Colors.background)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                // Add folder input field
                HStack(spacing: AppTheme.Dimensions.spacingM) {
                    TextField("New Folder", text: $newFolder)
                        .font(AppTheme.Typography.body())
                        .padding(AppTheme.Dimensions.spacingM)
                        .background(AppTheme.Colors.cardSurface)
                        .cornerRadius(AppTheme.Dimensions.radiusM)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                                .stroke(AppTheme.Colors.divider, lineWidth: 1)
                        )
                    
                    Button {
                        if !newFolder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            folderStore.addFolder(name: newFolder.trimmingCharacters(in: .whitespacesAndNewlines))
                            
                            // Haptic feedback for successful action
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            newFolder = ""
                        }
                    } label: {
                        Text("Add")
                            .font(AppTheme.Typography.headline())
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Dimensions.spacingM)
                            .padding(.vertical, AppTheme.Dimensions.spacingS)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.Dimensions.radiusM)
                    }
                    .disabled(newFolder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newFolder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    .accessibilityLabel("Add folder")
                }
                .padding(AppTheme.Dimensions.spacingM)
                .background(AppTheme.Colors.secondaryBackground)
            }
        }
        .confirmationDialog("Are you sure you want to delete this folder?", 
                            isPresented: $showingDeleteConfirmation, 
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let folder = folderToDelete {
                    folderStore.deleteFolder(id: folder.id)
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the folder and remove its assignment from any notes or checklists.")
        }
    }
}
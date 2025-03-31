import SwiftUI

struct TagFilterView: View {
    @EnvironmentObject var tagStore: TagStore
    @Binding var selectedTagIds: Set<UUID>
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateItems = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
            // Header with expand/collapse button
            headerView
            
            if isExpanded {
                tagSelectionArea
            }
            
            // Show selected filters
            if !selectedTagIds.isEmpty {
                activeFiltersView
            }
        }
        .padding(AppTheme.Dimensions.spacingM)
        .background(colorScheme == .dark ? 
                    AppTheme.Colors.cardSurface.opacity(0.9) : 
                    AppTheme.Colors.secondaryBackground.opacity(0.7))
        .cornerRadius(AppTheme.Dimensions.radiusM)
        .shadow(color: AppTheme.Colors.cardShadow.opacity(0.08), radius: 3, x: 0, y: 2)
        .animation(AppTheme.Animations.standardCurve, value: isExpanded)
        .onAppear {
            // Trigger animation after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animateItems = true
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        HStack {
            Label("Filter by Tags", systemImage: "tag")
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            // The count badge showing number of active filters
            if !selectedTagIds.isEmpty {
                Text("\(selectedTagIds.count)")
                    .font(AppTheme.Typography.captionSmall())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.primary.opacity(0.2))
                    .foregroundColor(AppTheme.Colors.primary)
                    .cornerRadius(10)
            }
            
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                    
                    // Add haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .cornerRadius(AppTheme.Dimensions.radiusS)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
    
    private var tagSelectionArea: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
            Divider()
                .padding(.vertical, 2)
            
            if tagStore.tags.isEmpty {
                noTagsView
            } else {
                tagOptionsView
            }
        }
    }
    
    private var noTagsView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: AppTheme.Dimensions.spacingXS) {
                Image(systemName: "tag.slash")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.bottom, 4)
                
                Text("No tags available")
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Text("Create tags in note settings")
                    .font(AppTheme.Typography.captionSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(.vertical, AppTheme.Dimensions.spacingM)
            
            Spacer()
        }
    }
    
    private var tagOptionsView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
            // Clear all button
            if !selectedTagIds.isEmpty {
                Button(action: {
                    withAnimation {
                        selectedTagIds.removeAll()
                        
                        // Add haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }) {
                    HStack(spacing: AppTheme.Dimensions.spacingXS) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                        
                        Text("Clear All")
                            .font(AppTheme.Typography.caption())
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, AppTheme.Dimensions.spacingS)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusS)
                            .fill(AppTheme.Colors.secondaryBackground)
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
            
            // Tag options in a wrapped flow layout
            FlowLayout(spacing: 8) {
                ForEach(tagStore.tags) { tag in
                    TagFilterItem(
                        tag: tag,
                        isSelected: selectedTagIds.contains(tag.id)
                    ) {
                        toggleTag(tag)
                    }
                    .opacity(animateItems ? 1 : 0)
                    .offset(y: animateItems ? 0 : 10)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var activeFiltersView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingXS) {
            if !isExpanded {
                Divider()
                    .padding(.bottom, 4)
            }
            
            Text("Active filters")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.bottom, 2)
            
            FlowLayout(spacing: 6) {
                ForEach(selectedTagsArray) { tag in
                    SelectedTagView(tag: tag, onRemove: {
                        toggleTag(tag)
                    })
                }
            }
        }
        .padding(.top, isExpanded ? 0 : AppTheme.Dimensions.spacingXS)
    }
    
    // MARK: - Helper Methods
    
    private var selectedTagsArray: [Tag] {
        tagStore.tags.filter { selectedTagIds.contains($0.id) }
    }
    
    private func toggleTag(_ tag: Tag) {
        withAnimation {
            if selectedTagIds.contains(tag.id) {
                selectedTagIds.remove(tag.id)
            } else {
                selectedTagIds.insert(tag.id)
            }
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// MARK: - Support Views

struct TagFilterItem: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tag.color)
                    .frame(width: 8, height: 8)
                
                Text(tag.name)
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(isSelected ? 
                                      AppTheme.Colors.textPrimary : 
                                      AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusS)
                    .fill(isSelected ? 
                          tag.color.opacity(colorScheme == .dark ? 0.25 : 0.15) : 
                          AppTheme.Colors.secondaryBackground.opacity(colorScheme == .dark ? 0.7 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusS)
                    .stroke(isSelected ? tag.color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Preview Provider

struct TagFilterView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStore = TagStore()
        let tag1 = Tag(id: UUID(), name: "Work", color: .blue)
        let tag2 = Tag(id: UUID(), name: "Personal", color: .green)
        let tag3 = Tag(id: UUID(), name: "Important", color: .red)
        mockStore.tags = [tag1, tag2, tag3]
        
        return Group {
            TagFilterView(selectedTagIds: .constant([]))
                .environmentObject(TagStore())
                .previewDisplayName("Tag Filter (Empty)")
                .padding()
                .frame(width: 350)
            
            TagFilterView(selectedTagIds: .constant([tag1.id, tag3.id]))
                .environmentObject(mockStore)
                .previewDisplayName("Tag Filter (With Selection)")
                .padding()
                .frame(width: 350)
        }
    }
}

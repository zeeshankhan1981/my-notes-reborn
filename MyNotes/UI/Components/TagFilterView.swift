import SwiftUI

struct TagFilterView: View {
    @EnvironmentObject var tagStore: TagStore
    @Binding var selectedTagIDs: Set<UUID>
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Filter by Tags")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            
            if isExpanded {
                if tagStore.tags.isEmpty {
                    Text("No tags available")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.vertical, 4)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation {
                                    selectedTagIDs.removeAll()
                                }
                            }) {
                                Text("Clear All")
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                                            .fill(AppTheme.Colors.secondaryBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                                            .stroke(AppTheme.Colors.secondaryBackground, lineWidth: 1)
                                    )
                            }
                            
                            ForEach(tagStore.tags) { tag in
                                TagFilterItem(
                                    tag: tag,
                                    isSelected: selectedTagIDs.contains(tag.id)
                                ) {
                                    toggleTag(tag)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Show selected filters
            if !selectedTagIDs.isEmpty {
                HStack {
                    Text("Active filters:")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(selectedTagsArray) { tag in
                                TagBadgeView(tag: tag) {
                                    toggleTag(tag)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(8)
        .background(AppTheme.Colors.background)
        .cornerRadius(AppTheme.Dimensions.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadius)
                .stroke(AppTheme.Colors.secondaryBackground, lineWidth: 1)
        )
    }
    
    private var selectedTagsArray: [Tag] {
        tagStore.tags.filter { selectedTagIDs.contains($0.id) }
    }
    
    private func toggleTag(_ tag: Tag) {
        withAnimation {
            if selectedTagIDs.contains(tag.id) {
                selectedTagIDs.remove(tag.id)
            } else {
                selectedTagIDs.insert(tag.id)
            }
        }
    }
}

struct TagFilterItem: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag.name)
                .font(AppTheme.Typography.footnote)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                        .fill(isSelected ? tag.color.opacity(0.3) : AppTheme.Colors.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                        .stroke(isSelected ? tag.color : AppTheme.Colors.textTertiary.opacity(0.3), lineWidth: isSelected ? 1.5 : 0.5)
                )
        }
    }
}

#Preview {
    TagFilterView(selectedTagIDs: .constant([]))
        .environmentObject(TagStore())
        .padding()
        .frame(width: 350)
}

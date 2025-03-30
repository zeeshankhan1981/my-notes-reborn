import SwiftUI

struct TagSelectorView: View {
    @Binding var selectedTagIDs: [UUID]
    @EnvironmentObject var tagStore: TagStore
    @State private var showingTagManagement = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    showingTagManagement = true
                }) {
                    Label("Manage Tags", systemImage: "gear")
                        .font(AppTheme.Typography.caption)
                }
                .sheet(isPresented: $showingTagManagement) {
                    TagManagementView()
                }
            }
            
            if tagStore.tags.isEmpty {
                Text("No tags created yet. Tap 'Manage Tags' to create some.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.Dimensions.cornerRadius)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tagStore.tags) { tag in
                            TagView(tag: tag, isSelected: selectedTagIDs.contains(tag.id))
                                .onTapGesture {
                                    toggleTag(tag)
                                }
                        }
                    }
                    .padding(4)
                }
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.Dimensions.cornerRadius)
            }
            
            // Selected tags
            if !selectedTagIDs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Tags")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    FlowLayout(spacing: 4) {
                        ForEach(tagStore.getTagsByIDs(selectedTagIDs)) { tag in
                            SelectedTagView(tag: tag) {
                                toggleTag(tag)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.removeAll { $0 == tag.id }
        } else {
            selectedTagIDs.append(tag.id)
        }
    }
}

struct TagView: View {
    let tag: Tag
    let isSelected: Bool
    
    var body: some View {
        Text(tag.name)
            .font(AppTheme.Typography.footnote)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                    .fill(tag.color.opacity(isSelected ? 0.8 : 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                    .stroke(tag.color, lineWidth: isSelected ? 1.5 : 0.5)
            )
    }
}

struct SelectedTagView: View {
    let tag: Tag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.color)
                .frame(width: 8, height: 8)
            
            Text(tag.name)
                .font(AppTheme.Typography.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                .fill(tag.color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                .stroke(tag.color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// FlowLayout is a helper view that arranges its children in a wrapping flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if x + viewSize.width > width {
                // Move to next row
                y += maxHeight + spacing
                x = 0
                maxHeight = 0
            }
            
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
            
            // Update total height
            height = max(height, y + maxHeight)
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if x + viewSize.width > bounds.maxX {
                // Move to next row
                y += maxHeight + spacing
                x = bounds.minX
                maxHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height))
            
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
        }
    }
}

#Preview {
    TagSelectorView(selectedTagIDs: .constant([UUID()]))
        .environmentObject(TagStore())
        .padding()
        .frame(width: 350)
}

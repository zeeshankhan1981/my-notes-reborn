import SwiftUI

struct SelectedTagView: View {
    let tag: Tag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.color)
                .frame(width: 8, height: 8)
            
            Text(tag.name)
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                .fill(AppTheme.Colors.secondaryBackground.opacity(0.5))
        )
    }
}

#Preview {
    SelectedTagView(tag: Tag(id: UUID(), name: "Important", color: .red)) {
        print("Removed tag")
    }
    .padding()
}

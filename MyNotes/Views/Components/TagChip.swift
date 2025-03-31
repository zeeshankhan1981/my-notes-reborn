import SwiftUI

struct TagChip: View {
    let tag: Tag
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Text(tag.name)
            .font(AppTheme.Typography.caption())
            .foregroundColor(isSelected ? .white : Color(hex: tag.colorString()))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: tag.colorString()) : Color(hex: tag.colorString()).opacity(0.2))
            )
            .onTapGesture {
                if let onTap = onTap {
                    onTap()
                }
            }
    }
}

#Preview {
    HStack {
        TagChip(tag: Tag(id: UUID(), name: "Work", color: .blue))
        TagChip(tag: Tag(id: UUID(), name: "Personal", color: .green), isSelected: true)
        TagChip(tag: Tag(id: UUID(), name: "Urgent", color: .red))
    }
    .padding()
}

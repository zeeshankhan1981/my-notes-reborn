import SwiftUI

struct NoteCardView: View {
    let note: Note
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                // Title and pin
                HStack {
                    Text(note.title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                // Preview of content
                Text(note.content)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                
                Spacer()
                
                // Date
                HStack {
                    Spacer()
                    Text(formattedDate)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                // Image thumbnail if present
                if let imageData = note.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(AppTheme.Dimensions.smallCornerRadius)
                        .clipped()
                }
            }
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.Dimensions.cornerRadius)
            .shadow(color: Color.black.opacity(isPressed ? 0.02 : 0.05), 
                    radius: isPressed ? 2 : 5, 
                    x: 0, 
                    y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.2, pressing: { pressing in
            self.isPressed = pressing
        }, perform: {})
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: note.date)
    }
}

#if DEBUG
struct NoteCardView_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardView(
            note: Note(
                id: UUID(),
                title: "Meeting Notes",
                content: "Discussed project timeline and resource allocation for Q3.",
                folderID: nil,
                isPinned: true,
                date: Date(),
                imageData: nil
            ),
            onTap: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

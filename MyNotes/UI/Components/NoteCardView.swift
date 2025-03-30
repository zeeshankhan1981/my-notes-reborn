import SwiftUI

struct NoteCardView: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    // Threshold for delete action
    private let deleteThreshold: CGFloat = -80
    
    var body: some View {
        ZStack {
            // Delete background
            HStack {
                Spacer()
                
                VStack {
                    Image(systemName: "trash")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Delete")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .frame(width: abs(min(offset, 0)), height: 100)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadius))
            }
            
            // Card content
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
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if !isSwiping {
                            isSwiping = true
                        }
                        // Only allow left swipe (negative values)
                        let newOffset = min(0, gesture.translation.width)
                        withAnimation(.interactiveSpring()) {
                            offset = newOffset
                        }
                    }
                    .onEnded { gesture in
                        withAnimation(.spring()) {
                            if offset < deleteThreshold {
                                // Delete the note
                                offset = -UIScreen.main.bounds.width
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDelete()
                                }
                            } else {
                                // Reset position
                                offset = 0
                            }
                            isSwiping = false
                        }
                    }
            )
        }
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
            onTap: {},
            onDelete: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

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
    // Visual indicator width for swipe hint
    private let swipeIndicatorWidth: CGFloat = 3 // Thinner for more subtlety
    
    var body: some View {
        ZStack {
            // Delete background
            HStack {
                Spacer()
                
                // Delete indicator - more subtle and refined
                VStack(spacing: AppTheme.Dimensions.tinySpacing) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.white)
                    
                    Text("Delete")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: max(abs(min(offset, 0)), 0), height: 80)
                .padding(.horizontal, AppTheme.Dimensions.spacing)
                .background(AppTheme.Colors.error.opacity(0.9))
                .cornerRadius(AppTheme.Dimensions.cornerRadius)
            }
            
            // Card content - cleaner, more typography-focused design
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                // Title and pin
                HStack(alignment: .top) {
                    Text(note.title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(AppTheme.Colors.accent.opacity(0.8))
                            .font(.caption)
                    }
                }
                
                // Subtle divider
                Rectangle()
                    .fill(AppTheme.Colors.divider)
                    .frame(height: 1)
                    .padding(.vertical, AppTheme.Dimensions.tinySpacing)
                    .opacity(0.6)
                
                // Preview of content - more refined typography
                Text(note.content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(2)
                
                Spacer()
                
                // Date - more minimal
                HStack {
                    Spacer()
                    Text(formattedDate)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.top, AppTheme.Dimensions.tinySpacing)
                }
                
                // Image thumbnail if present - more refined presentation
                if let imageData = note.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100) // Slightly smaller
                        .frame(maxWidth: .infinity)
                        .cornerRadius(AppTheme.Dimensions.smallCornerRadius)
                        .clipped()
                        .padding(.top, AppTheme.Dimensions.smallSpacing)
                }
            }
            .padding(AppTheme.Dimensions.spacing)
            .background(
                ZStack(alignment: .trailing) {
                    AppTheme.Colors.cardSurface
                    
                    // Swipe hint indicator - more subtle
                    if offset == 0 && !isSwiping {
                        Rectangle()
                            .fill(AppTheme.Colors.error.opacity(0.2))
                            .frame(width: swipeIndicatorWidth)
                    }
                }
            )
            .cornerRadius(AppTheme.Dimensions.cornerRadius)
            .shadow(color: AppTheme.Colors.cardShadow, 
                    radius: isPressed ? 1 : AppTheme.Dimensions.cardElevation, 
                    x: 0, 
                    y: isPressed ? 0 : AppTheme.Dimensions.cardElevation/2)
            .scaleEffect(isPressed ? 0.99 : 1.0) // More subtle scale
            .offset(x: offset)
            .animation(AppTheme.Animation.quick, value: isPressed)
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        onTap()
                    }
                    .simultaneously(with: 
                        LongPressGesture(minimumDuration: 0.2)
                            .onChanged { value in
                                self.isPressed = value
                            }
                    )
            )
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isSwiping = true
                        // Only allow left swipe (negative values)
                        let newOffset = min(0, gesture.translation.width)
                        withAnimation(.interactiveSpring()) {
                            offset = newOffset
                        }
                    }
                    .onEnded { gesture in
                        withAnimation(AppTheme.Animation.subtle) {
                            if offset < deleteThreshold {
                                // Delete the note with animation
                                offset = -UIScreen.main.bounds.width
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDelete()
                                }
                            } else {
                                // Reset position
                                offset = 0
                            }
                            
                            // Reset swiping after a delay to allow swipe hint to reappear
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isSwiping = false
                            }
                        }
                    }
            )
        }
        .contentShape(Rectangle()) // Make entire card tappable
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

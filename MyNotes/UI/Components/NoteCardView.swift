import SwiftUI

struct NoteCardView: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void
    let isInSelectionMode: Bool
    let isSelected: Bool
    
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
                .frame(width: 80)
                .background(Color.red)
            }
            
            // Card content
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                // Title and pin indicator
                HStack {
                    if isInSelectionMode {
                        // Selection indicator
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                            .padding(.trailing, 6)
                    }
                    
                    Text(note.title)
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                    }
                }
                
                // Content preview
                Text(note.content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .padding(.bottom, 4)
                
                // Date
                HStack {
                    Spacer()
                    Text(formattedDate)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.cardSurface)
            .cornerRadius(AppTheme.Dimensions.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.cornerRadius)
                    .stroke(
                        isSelected ? AppTheme.Colors.primary : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .overlay(
                // Right edge indicator for swipe hint
                Rectangle()
                    .frame(width: swipeIndicatorWidth)
                    .foregroundColor(offset < 0 ? Color.red.opacity(min(1, -offset / deleteThreshold)) : Color.clear)
                    .padding(.vertical, 1)
                ,
                alignment: .trailing
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .offset(x: offset)
            .animation(AppTheme.Animation.standard, value: isPressed)
            .animation(AppTheme.Animation.standard, value: isSelected)
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
                        isSwiping = false
                        if offset < deleteThreshold {
                            withAnimation(.spring()) {
                                offset = -UIScreen.main.bounds.width
                            }
                            // Trigger delete after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDelete()
                            }
                        } else {
                            withAnimation(.spring()) {
                                offset = 0
                            }
                        }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        if !isSwiping && !isInSelectionMode {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            onLongPress()
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if !isSwiping {
                            if isInSelectionMode {
                                // In selection mode, tap toggles selection
                                onLongPress()
                            } else {
                                // Normal mode, open the note
                                onTap()
                            }
                        }
                    }
            )
            .onTapGesture {
                // This is handled by the TapGesture above
            }
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
        VStack(spacing: 16) {
            // Normal mode
            NoteCardView(
                note: Note(id: UUID(), title: "Meeting Notes", content: "Discuss project timeline and milestones", folderID: nil, isPinned: true, date: Date(), imageData: nil),
                onTap: {},
                onDelete: {},
                onLongPress: {},
                isInSelectionMode: false,
                isSelected: false
            )
            
            // Selection mode, not selected
            NoteCardView(
                note: Note(id: UUID(), title: "Shopping List", content: "Milk, eggs, bread", folderID: nil, isPinned: false, date: Date(), imageData: nil),
                onTap: {},
                onDelete: {},
                onLongPress: {},
                isInSelectionMode: true,
                isSelected: false
            )
            
            // Selection mode, selected
            NoteCardView(
                note: Note(id: UUID(), title: "Ideas", content: "New app concept with AR integration", folderID: nil, isPinned: false, date: Date(), imageData: nil),
                onTap: {},
                onDelete: {},
                onLongPress: {},
                isInSelectionMode: true,
                isSelected: true
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif

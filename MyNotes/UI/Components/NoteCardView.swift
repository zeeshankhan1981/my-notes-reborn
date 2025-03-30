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
    @State private var isSwiped = false
    @State private var initialOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    
    // Threshold for delete action
    private let deleteThreshold: CGFloat = -80
    private let deleteWidth: CGFloat = 80
    // Visual indicator width for swipe hint
    private let swipeIndicatorWidth: CGFloat = 3 // Thinner for more subtlety
    
    var body: some View {
        ZStack {
            // Delete background
            HStack {
                Spacer()
                
                // Delete indicator - more subtle and refined
                Button(action: {
                    withAnimation(AppTheme.Animations.standardCurve) {
                        offset = 0
                        isSwiped = false
                    }
                    onDelete()
                }) {
                    VStack(spacing: AppTheme.Dimensions.tinySpacing) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Text("Delete")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(width: deleteWidth)
                    .contentShape(Rectangle())
                }
                .background(AppTheme.Colors.error)
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
                        .font(AppTheme.Typography.headline())
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
                if !note.content.isEmpty {
                    Text(note.content)
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(3)
                        .padding(.bottom, 4)
                }
                
                // Date and metadata
                HStack {
                    Text(formattedDate)
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    // Tags indicator (if present)
                    if !note.tagIDs.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(0..<min(3, note.tagIDs.count), id: \.self) { _ in
                                Circle()
                                    .fill(AppTheme.Colors.accent.opacity(0.7))
                                    .frame(width: 8, height: 8)
                            }
                            
                            if note.tagIDs.count > 3 {
                                Text("+\(note.tagIDs.count - 3)")
                                    .font(AppTheme.Typography.caption())
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                        }
                    }
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
            .shadow(
                color: colorScheme == .dark 
                    ? AppTheme.Colors.cardShadow.opacity(0.25) 
                    : AppTheme.Colors.cardShadow.opacity(0.08),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .offset(x: offset)
            .animation(AppTheme.Animations.standardCurve, value: isPressed)
            .animation(AppTheme.Animations.standardCurve, value: isSelected)
            .listItemTransition()
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if !isInSelectionMode {
                            let newOffset = gesture.translation.width + initialOffset
                            // Only allow left swipe (negative values)
                            offset = min(0, newOffset)
                        }
                    }
                    .onEnded { gesture in
                        if !isInSelectionMode {
                            // Determine if we should show delete or snap back
                            if offset < deleteThreshold {
                                withAnimation(AppTheme.Animations.standardCurve) {
                                    offset = -deleteWidth
                                    isSwiped = true
                                }
                                initialOffset = -deleteWidth
                            } else {
                                withAnimation(AppTheme.Animations.standardCurve) {
                                    offset = 0
                                    isSwiped = false
                                }
                                initialOffset = 0
                            }
                        }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        if !isInSelectionMode && !isSwiped {
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
                        if !isSwiped {
                            if isInSelectionMode {
                                // In selection mode, tap toggles selection
                                onLongPress()
                            } else {
                                // Normal mode, open the note
                                onTap()
                            }
                        } else {
                            // Reset swipe if tapped while swiped
                            withAnimation(AppTheme.Animations.standardCurve) {
                                offset = 0
                                isSwiped = false
                                initialOffset = 0
                            }
                        }
                    }
            )
        }
        .clipped()
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
        Group {
            NoteCardView(
                note: Note(
                    id: UUID(),
                    title: "Meeting Notes",
                    content: "Discussed the project timeline and assigned tasks to team members.",
                    folderID: nil,
                    isPinned: true,
                    date: Date(),
                    imageData: nil,
                    attributedContent: nil,
                    tagIDs: []
                ),
                onTap: {},
                onDelete: {},
                onLongPress: {},
                isInSelectionMode: false,
                isSelected: false
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
            
            NoteCardView(
                note: Note(
                    id: UUID(),
                    title: "Shopping List",
                    content: "Milk, eggs, bread, cheese, apples, cereal",
                    folderID: nil,
                    isPinned: false,
                    date: Date(),
                    imageData: nil,
                    attributedContent: nil,
                    tagIDs: [UUID(), UUID()]
                ),
                onTap: {},
                onDelete: {},
                onLongPress: {},
                isInSelectionMode: true,
                isSelected: true
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        }
    }
}
#endif

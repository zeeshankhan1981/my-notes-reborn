import SwiftUI

struct NoteCardView: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void
    let isInSelectionMode: Bool
    let isSelected: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
            // Title and pin indicator
            HStack {
                if isInSelectionMode {
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
        .background(isSelected ? AppTheme.Colors.highlightBackground : AppTheme.Colors.cardSurface)
        .cornerRadius(AppTheme.Dimensions.radiusM)
        .shadow(
            color: colorScheme == .dark 
                ? AppTheme.Colors.cardShadow.opacity(0.25) 
                : AppTheme.Colors.cardShadow.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                .stroke(
                    isSelected ? AppTheme.Colors.primary : Color.clear,
                    lineWidth: isSelected ? 2 : 0
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isInSelectionMode {
                onLongPress()
            } else {
                onTap()
            }
        }
        .onLongPressGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onLongPress()
        }
        .animation(AppTheme.Animations.standardCurve, value: isSelected)
        .listItemTransition()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
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

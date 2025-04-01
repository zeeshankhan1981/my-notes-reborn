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
                
                // Add priority indicator if priority is not none
                if note.priority != .none {
                    PriorityIndicator(priority: note.priority, size: 14)
                        .padding(.leading, 4)
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
            color: AppTheme.Colors.cardShadow.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: AppTheme.Dimensions.shadowRadius,
            x: AppTheme.Dimensions.shadowOffsetX,
            y: AppTheme.Dimensions.shadowOffsetY
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
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation {
                    onDelete()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
                
                // Post notification to trigger pin toggle in parent view
                NotificationCenter.default.post(
                    name: NSNotification.Name("ToggleNotePin"),
                    object: note.id
                )
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(AppTheme.Colors.primary)
        }
        .swipeActions(edge: .leading) {
            Button {
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
                
                // Post notification for sharing
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShareNote"),
                    object: note.id
                )
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(AppTheme.Colors.accent)
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

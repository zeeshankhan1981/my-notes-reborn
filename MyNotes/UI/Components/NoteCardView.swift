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
                        .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary.opacity(0.4))
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
                    .multilineTextAlignment(.leading)
            }
            
            // Metadata (date, tag count, etc.)
            HStack {
                Text(note.date, style: .date)
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Spacer()
                
                // Display tag count if present
                if !note.tagIDs.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.system(size: 10))
                        Text("\(note.tagIDs.count)")
                            .font(AppTheme.Typography.captionSmall())
                    }
                    .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(AppTheme.Dimensions.spacingM)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                    .fill(AppTheme.Colors.cardSurface)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                        .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 2)
                }
            }
        )
        .shadow(
            color: AppTheme.Colors.cardShadow.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .contextMenu {
            // Pin/unpin
            Button {
                // Post a notification to toggle pin status
                NotificationCenter.default.post(name: NSNotification.Name("ToggleNotePin"), object: note.id)
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            
            // Edit button
            Button {
                if !isInSelectionMode {
                    onTap()
                }
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            // Delete
            Button(role: .destructive, action: {
                onDelete()
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: {
                onDelete()
            }) {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                // Post a notification to toggle pin status
                NotificationCenter.default.post(name: NSNotification.Name("ToggleNotePin"), object: note.id)
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(AppTheme.Colors.primary)
        }
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

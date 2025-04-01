import SwiftUI

struct ChecklistCardView: View {
    let checklist: ChecklistNote
    let onTap: () -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void
    let isInSelectionMode: Bool
    let isSelected: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
            // Title row
            HStack {
                if isInSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary.opacity(0.4))
                        .padding(.trailing, 6)
                }
                
                Text(checklist.title)
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                if checklist.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: AppTheme.Dimensions.smallIconSize))
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.7))
                }
            }
            
            // Progress bar
            if !checklist.items.isEmpty {
                VStack(spacing: AppTheme.Dimensions.spacingXS) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(AppTheme.Colors.divider)
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            Rectangle()
                                .fill(completionPercentage == 1.0 ? AppTheme.Colors.success : AppTheme.Colors.primary)
                                .frame(width: geometry.size.width * CGFloat(completionPercentage), height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 4)
                }
            }
            
            // Items preview
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingXS) {
                ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: AppTheme.Dimensions.spacingXS) {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundColor(item.isDone ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                        
                        Text(item.text)
                            .font(AppTheme.Typography.body())
                            .foregroundColor(item.isDone ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                            .strikethrough(item.isDone)
                            .lineLimit(1)
                    }
                }
                
                if checklist.items.count > 3 {
                    Text("+ \(checklist.items.count - 3) more items")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.top, AppTheme.Dimensions.spacingXXS)
                }
            }
            
            // Footer row
            HStack(spacing: AppTheme.Dimensions.spacingS) {
                Text(formattedDate)
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Spacer()
                
                Text("\(doneItemCount)/\(checklist.items.count) done")
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
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
                NotificationCenter.default.post(name: NSNotification.Name("ToggleChecklistPin"), object: checklist.id)
            } label: {
                Label(checklist.isPinned ? "Unpin" : "Pin", systemImage: checklist.isPinned ? "pin.slash" : "pin")
            }
            
            // Complete all items
            Button {
                NotificationCenter.default.post(name: NSNotification.Name("CompleteAllChecklistItems"), object: checklist.id)
            } label: {
                Label("Toggle All Items", systemImage: "checkmark.circle")
            }
            
            // Edit
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
                NotificationCenter.default.post(name: NSNotification.Name("ToggleChecklistPin"), object: checklist.id)
            } label: {
                Label(checklist.isPinned ? "Unpin" : "Pin", systemImage: checklist.isPinned ? "pin.slash" : "pin")
            }
            .tint(AppTheme.Colors.primary)
            
            Button {
                NotificationCenter.default.post(name: NSNotification.Name("CompleteAllChecklistItems"), object: checklist.id)
            } label: {
                Label("Complete All", systemImage: "checkmark.circle")
            }
            .tint(AppTheme.Colors.success)
        }
        .animation(AppTheme.Animations.standardCurve, value: isSelected)
        .listItemTransition()
    }
    
    // Helper properties
    
    private var previewItems: [ChecklistItem] {
        Array(checklist.items.prefix(3))
    }
    
    private var doneItemCount: Int {
        checklist.items.filter { $0.isDone }.count
    }
    
    private var completionPercentage: Double {
        checklist.items.isEmpty ? 0 : Double(doneItemCount) / Double(checklist.items.count)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: checklist.date)
    }
}

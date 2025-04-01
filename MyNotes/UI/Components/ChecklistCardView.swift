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
                        .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                        .padding(.trailing, 4)
                }
                
                Text(checklist.title)
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                if checklist.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: AppTheme.Dimensions.smallIconSize))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                // Add priority indicator if priority is not none
                if checklist.priority != .none {
                    PriorityIndicator(priority: checklist.priority, size: 14, showBackground: true)
                        .padding(.leading, 4)
                }
            }
            
            // Items preview - show more compact, Todoist style
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .center, spacing: 8) {
                        AnimatedCheckbox(isChecked: .constant(item.isDone), size: 16)
                        
                        AnimatedStrikethroughText(
                            text: item.text, 
                            isStrikethrough: .constant(item.isDone),
                            font: AppTheme.Typography.body(),
                            foregroundColor: AppTheme.Colors.textPrimary,
                            strikethroughColor: AppTheme.Colors.textTertiary
                        )
                        .lineLimit(1)
                    }
                    .padding(.vertical, 2) // Tighter spacing between items
                    .opacity(item.isDone ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: item.isDone)
                }
                
                if checklist.items.count > 3 {
                    Text("+ \(checklist.items.count - 3) more")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.top, 2)
                }
            }
            
            // Progress bar
            if !checklist.items.isEmpty {
                VStack(spacing: 2) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(AppTheme.Colors.divider)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                            
                            Rectangle()
                                .fill(completionPercentage == 1.0 ? AppTheme.Colors.success : AppTheme.Colors.primary)
                                .frame(width: geometry.size.width * CGFloat(completionPercentage), height: 3)
                                .cornerRadius(1.5)
                        }
                    }
                    .frame(height: 3)
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
            .padding(.top, 2)
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
            onTap()
        }
        .onLongPressGesture {
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
                    name: NSNotification.Name("ToggleChecklistPin"),
                    object: checklist.id
                )
            } label: {
                Label(checklist.isPinned ? "Unpin" : "Pin", systemImage: checklist.isPinned ? "pin.slash" : "pin")
            }
            .tint(AppTheme.Colors.primary)
        }
        .swipeActions(edge: .leading) {
            Button {
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
                
                // Post notification to trigger completion of all items
                NotificationCenter.default.post(
                    name: NSNotification.Name("CompleteAllChecklistItems"),
                    object: checklist.id
                )
            } label: {
                Label("Complete All", systemImage: "checkmark.circle")
            }
            .tint(AppTheme.Colors.success)
        }
    }
    
    private var previewItems: [ChecklistItem] {
        // Show at most 3 items
        Array(checklist.items.prefix(3))
    }
    
    private var doneItemCount: Int {
        checklist.items.filter { $0.isDone }.count
    }
    
    private var completionPercentage: Double {
        guard !checklist.items.isEmpty else { return 0 }
        return Double(doneItemCount) / Double(checklist.items.count)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: checklist.date)
    }
}

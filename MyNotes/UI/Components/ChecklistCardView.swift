import SwiftUI

struct ChecklistCardView: View {
    let checklist: ChecklistNote
    let onTap: () -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void
    let isInSelectionMode: Bool
    let isSelected: Bool
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    @State private var initialOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    
    // Constants for swipe behavior
    private let deleteThreshold: CGFloat = -75
    private let deleteWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(AppTheme.Animations.standardCurve) {
                        offset = 0
                        isSwiped = false
                    }
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: AppTheme.Dimensions.iconSize))
                        .foregroundColor(.white)
                        .frame(width: deleteWidth)
                        .contentShape(Rectangle())
                }
                .background(AppTheme.Colors.error)
            }
            
            // Card content
            cardContent
                .background(AppTheme.Colors.cardSurface)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isInSelectionMode {
                                let newOffset = value.translation.width + initialOffset
                                // Only allow swiping left
                                offset = min(0, newOffset)
                            }
                        }
                        .onEnded { value in
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
        }
        .clipped()
        .cornerRadius(AppTheme.Dimensions.radiusM)
        .shadow(
            color: colorScheme == .dark 
                ? AppTheme.Colors.cardShadow.opacity(0.25) 
                : AppTheme.Colors.cardShadow.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        .animation(AppTheme.Animations.standardCurve, value: isSelected)
        .listItemTransition()
    }
    
    private var cardContent: some View {
        HStack(spacing: AppTheme.Dimensions.spacingS) {
            // Main card content
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
                // Title row with pin indicator and selection
                HStack {
                    if isInSelectionMode {
                        // Selection indicator
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
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
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                
                // Progress indicator
                if !checklist.items.isEmpty {
                    progressView
                }
                
                // Item previews
                itemPreview
                
                // Metadata row
                HStack(spacing: AppTheme.Dimensions.spacingS) {
                    // Date and completion count
                    Text(formattedDate)
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    Text("\(completedItemCount)/\(checklist.items.count) completed")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(AppTheme.Dimensions.spacing)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isSwiped {
                    if isInSelectionMode {
                        // In selection mode, tap toggles selection
                        onLongPress()
                    } else {
                        // Normal mode, open the checklist
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
        }
        .background(isSelected ? AppTheme.Colors.highlightBackground : AppTheme.Colors.cardSurface)
    }
    
    // MARK: - Helper Views
    
    private var progressView: some View {
        VStack(spacing: AppTheme.Dimensions.spacingXS) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(AppTheme.Colors.divider)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress indicator
                    Rectangle()
                        .fill(completionPercentage == 1.0 ? AppTheme.Colors.success : AppTheme.Colors.primary)
                        .frame(width: geometry.size.width * CGFloat(completionPercentage), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4) // Ensure height is consistent
        }
    }
    
    private var itemPreview: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingXS) {
            // Show up to 3 items as a preview
            ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: AppTheme.Dimensions.spacingXS) {
                    // Checkbox icon
                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isDone ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                        .font(.system(size: 14))
                    
                    // Item text
                    Text(item.text)
                        .font(AppTheme.Typography.body())
                        .foregroundColor(item.isDone ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                        .strikethrough(item.isDone)
                        .lineLimit(1)
                }
            }
            
            // "More items" indicator if needed
            if checklist.items.count > 3 {
                Text("+ \(checklist.items.count - 3) more items")
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.top, AppTheme.Dimensions.spacingXXS)
            }
        }
    }
    
    // MARK: - Helper Methods & Computed Properties
    
    private var previewItems: [ChecklistItem] {
        Array(checklist.items.prefix(3))
    }
    
    private var completedItemCount: Int {
        checklist.items.filter { $0.isDone }.count
    }
    
    private var completionPercentage: Double {
        checklist.items.isEmpty ? 0 : Double(completedItemCount) / Double(checklist.items.count)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: checklist.date)
    }
}

#if DEBUG
struct ChecklistCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Normal mode
            ChecklistCardView(
                checklist: ChecklistNote(
                    id: UUID(),
                    title: "Shopping List",
                    folderID: nil,
                    items: [
                        ChecklistItem(id: UUID(), text: "Milk", isDone: false),
                        ChecklistItem(id: UUID(), text: "Eggs", isDone: true),
                        ChecklistItem(id: UUID(), text: "Bread", isDone: false)
                    ],
                    isPinned: true,
                    date: Date()
                ),
                onTap: {},
                onDelete: {},
                onLongPress: {},
                isInSelectionMode: false,
                isSelected: false
            )
            
            // Selection mode, not selected
            ChecklistCardView(
                checklist: ChecklistNote(
                    id: UUID(),
                    title: "To-Do List",
                    folderID: nil,
                    items: [
                        ChecklistItem(id: UUID(), text: "Call Tim", isDone: true),
                        ChecklistItem(id: UUID(), text: "Schedule meeting", isDone: false)
                    ],
                    isPinned: false,
                    date: Date()
                ),
                onTap: {},
                onDelete: {},
                onLongPress: {},
                isInSelectionMode: true,
                isSelected: false
            )
            
            // Selection mode, selected
            ChecklistCardView(
                checklist: ChecklistNote(
                    id: UUID(),
                    title: "Project Tasks",
                    folderID: nil,
                    items: [
                        ChecklistItem(id: UUID(), text: "Research", isDone: true),
                        ChecklistItem(id: UUID(), text: "Design mockups", isDone: true),
                        ChecklistItem(id: UUID(), text: "Implementation", isDone: false),
                        ChecklistItem(id: UUID(), text: "Testing", isDone: false),
                        ChecklistItem(id: UUID(), text: "Deploy", isDone: false)
                    ],
                    isPinned: false,
                    date: Date()
                ),
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

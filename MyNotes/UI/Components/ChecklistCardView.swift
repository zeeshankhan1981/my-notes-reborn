import SwiftUI

struct ChecklistCardView: View {
    let checklist: ChecklistNote
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
                    Text(checklist.title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if checklist.isPinned {
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
                
                // Progress bar - more refined
                ProgressView(value: completionPercentage, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.accent.opacity(0.8)))
                    .frame(height: 3) // Thinner for more subtlety
                    .padding(.vertical, AppTheme.Dimensions.tinySpacing)
                
                // Completion status - cleaner typography
                HStack {
                    Text("\(completedCount)/\(checklist.items.count) completed")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    // Date
                    Text(formattedDate)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                // Preview of checklist items - more refined presentation
                if !checklist.items.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Dimensions.tinySpacing) {
                        ForEach(Array(checklist.items.prefix(3)), id: \.id) { item in
                            HStack(spacing: AppTheme.Dimensions.smallSpacing) {
                                // More refined checkmark style
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isDone ? AppTheme.Colors.success.opacity(0.8) : AppTheme.Colors.textTertiary)
                                    .font(.caption)
                                
                                Text(item.text)
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .strikethrough(item.isDone)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 1) // Slight padding for better readability
                        }
                        
                        if checklist.items.count > 3 {
                            Text("+ \(checklist.items.count - 3) more items")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .italic()
                                .padding(.top, 2)
                        }
                    }
                    .padding(.top, AppTheme.Dimensions.tinySpacing)
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
                                // Delete the checklist with animation
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
    
    private var completedCount: Int {
        checklist.items.filter { $0.isDone }.count
    }
    
    private var completionPercentage: Double {
        guard !checklist.items.isEmpty else { return 0 }
        return Double(completedCount) / Double(checklist.items.count)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: checklist.date)
    }
}

#if DEBUG
struct ChecklistCardView_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistCardView(
            checklist: ChecklistNote(
                id: UUID(),
                title: "Shopping List",
                folderID: nil,
                items: [
                    ChecklistItem(id: UUID(), text: "Apples", isDone: true),
                    ChecklistItem(id: UUID(), text: "Bread", isDone: false),
                    ChecklistItem(id: UUID(), text: "Milk", isDone: false)
                ],
                isPinned: true,
                date: Date()
            ),
            onTap: {},
            onDelete: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

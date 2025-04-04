import SwiftUI

struct ChecklistCardView: View {
    let checklist: ChecklistNote
    let onTap: () -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void
    let isInSelectionMode: Bool
    let isSelected: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if isInSelectionMode {
                onLongPress()
            } else {
                onTap()
            }
        }) {
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                // Title row
                HStack {
                    if isInSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                            .padding(.trailing, 6)
                    }
                    
                    Text(checklist.title)
                        .font(AppTheme.Typography.headline())
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if checklist.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.primary.opacity(0.7))
                    }
                }
                
                // Items preview
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(previewItems) { item in
                        HStack(alignment: .center, spacing: 8) {
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
                radius: isPressed ? 2 : AppTheme.Dimensions.shadowRadius,
                x: AppTheme.Dimensions.shadowOffsetX,
                y: isPressed ? 1 : AppTheme.Dimensions.shadowOffsetY
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                    .stroke(
                        isSelected ? AppTheme.Colors.primary : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .contextMenu {
            Button(action: {
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
                NotificationCenter.default.post(
                    name: NSNotification.Name("ToggleChecklistPin"),
                    object: checklist.id
                )
            }) {
                Label(checklist.isPinned ? "Unpin" : "Pin", systemImage: checklist.isPinned ? "pin.slash" : "pin")
            }
            
            Button(role: .destructive, action: {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                onDelete()
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            
            if checklist.isPinned {
                Button {
                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                    impactGenerator.impactOccurred()
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ToggleChecklistPin"),
                        object: checklist.id
                    )
                } label: {
                    Label("Unpin", systemImage: "pin.slash")
                }
                .tint(.blue)
            } else {
                Button {
                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                    impactGenerator.impactOccurred()
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ToggleChecklistPin"),
                        object: checklist.id
                    )
                } label: {
                    Label("Pin", systemImage: "pin")
                }
                .tint(.blue)
            }
        }
        .animation(AppTheme.Animations.standardCurve, value: isSelected)
    }
    
    private var previewItems: [ChecklistItem] {
        // Show at most 3 items
        Array(checklist.items.prefix(3))
    }
    
    private var doneItemCount: Int {
        checklist.items.filter { $0.isDone }.count
    }
    
    private var completionPercentage: Double {
        if checklist.items.isEmpty {
            return 0.0
        }
        return Double(doneItemCount) / Double(checklist.items.count)
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
        Group {
            ChecklistCardView(
                checklist: ChecklistNote(
                    id: UUID(),
                    title: "Shopping List",
                    folderID: nil,
                    items: [
                        ChecklistItem(id: UUID(), text: "Milk", isDone: true),
                        ChecklistItem(id: UUID(), text: "Eggs", isDone: false),
                        ChecklistItem(id: UUID(), text: "Bread", isDone: false),
                        ChecklistItem(id: UUID(), text: "Apples", isDone: false)
                    ],
                    isPinned: true,
                    date: Date(),
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
            
            ChecklistCardView(
                checklist: ChecklistNote(
                    id: UUID(),
                    title: "Tasks",
                    folderID: nil,
                    items: [
                        ChecklistItem(id: UUID(), text: "Email client", isDone: true),
                        ChecklistItem(id: UUID(), text: "Prepare presentation", isDone: true)
                    ],
                    isPinned: false,
                    date: Date(),
                    tagIDs: [UUID()]
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

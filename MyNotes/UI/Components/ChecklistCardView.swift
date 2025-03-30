import SwiftUI

struct ChecklistCardView: View {
    let checklist: ChecklistNote
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.smallSpacing) {
                // Title and pin
                HStack {
                    Text(checklist.title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if checklist.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                // Progress bar
                ProgressView(value: completionPercentage, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.primary))
                    .frame(height: 4)
                
                // Completion status
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
                
                // Preview of checklist items
                if !checklist.items.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Dimensions.tinySpacing) {
                        ForEach(Array(checklist.items.prefix(3)), id: \.id) { item in
                            HStack(spacing: AppTheme.Dimensions.smallSpacing) {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isDone ? .green : AppTheme.Colors.textTertiary)
                                    .font(.caption)
                                
                                Text(item.text)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .strikethrough(item.isDone)
                                    .lineLimit(1)
                            }
                        }
                        
                        if checklist.items.count > 3 {
                            Text("+ \(checklist.items.count - 3) more items")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .italic()
                        }
                    }
                    .padding(.top, AppTheme.Dimensions.smallSpacing)
                }
            }
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.Dimensions.cornerRadius)
            .shadow(color: Color.black.opacity(isPressed ? 0.02 : 0.05), 
                    radius: isPressed ? 2 : 5, 
                    x: 0, 
                    y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.2, pressing: { pressing in
            self.isPressed = pressing
        }, perform: {})
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
                    ChecklistItem(id: UUID(), text: "Milk", isDone: true),
                    ChecklistItem(id: UUID(), text: "Bread", isDone: false),
                    ChecklistItem(id: UUID(), text: "Eggs", isDone: false),
                    ChecklistItem(id: UUID(), text: "Butter", isDone: true)
                ],
                isPinned: true,
                date: Date()
            ),
            onTap: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

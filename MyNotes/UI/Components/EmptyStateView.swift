import SwiftUI

struct EmptyStateView: View {
    enum EmptyStateType {
        case notes
        case checklists
        case search
        case filtered
        case folder
        
        var icon: String {
            switch self {
            case .notes: return "note.text"
            case .checklists: return "checklist"
            case .search: return "magnifyingglass"
            case .filtered: return "tag"
            case .folder: return "folder"
            }
        }
        
        var title: String {
            switch self {
            case .notes: return "No Notes Yet"
            case .checklists: return "No Checklists Yet"
            case .search: return "No Results Found"
            case .filtered: return "No Matches"
            case .folder: return "Empty Folder"
            }
        }
        
        var message: String {
            switch self {
            case .notes: return "Start capturing your thoughts"
            case .checklists: return "Keep track of tasks you need to complete"
            case .search: return "Try a different search term"
            case .filtered: return "No items match your current filters"
            case .folder: return "Add notes or checklists to this folder"
            }
        }
    }
    
    let type: EmptyStateType
    let searchText: String
    var actionButtonTitle: String?
    var action: (() -> Void)?
    
    @State private var animateIn = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.Dimensions.spacingL) {
            // Icon with decorative elements
            ZStack {
                // Background decorative circle
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIn ? 1.0 : 0.8)
                    .opacity(animateIn ? 1.0 : 0)
                
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(AppTheme.Colors.primary)
                    .offset(y: animateIn ? 0 : 10)
                    .opacity(animateIn ? 1.0 : 0)
            }
            .padding(.bottom, AppTheme.Dimensions.spacingM)
            
            // Title and message
            VStack(spacing: AppTheme.Dimensions.spacingS) {
                Text(searchText.isEmpty ? type.title : "No Results")
                    .font(AppTheme.Typography.title2())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(animateIn ? 1.0 : 0)
                    .offset(y: animateIn ? 0 : 10)
                
                Text(searchText.isEmpty ? type.message : "Try a different search term")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
                    .padding(.bottom, AppTheme.Dimensions.spacingS)
                    .opacity(animateIn ? 1.0 : 0)
                    .offset(y: animateIn ? 0 : 10)
            }
            
            // Action button
            if let actionButtonTitle = actionButtonTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus")
                        Text(actionButtonTitle)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                    .buttonStyle(ScaleButtonStyle())
                }
                .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 2)
                .opacity(animateIn ? 1.0 : 0)
                .offset(y: animateIn ? 0 : 15)
            }
        }
        .padding(.horizontal, AppTheme.Dimensions.spacingXL)
        .padding(.bottom, 60) // Extra space at bottom
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyStateView(
                type: .notes, 
                searchText: "", 
                actionButtonTitle: "New Note") {}
                .previewDisplayName("Notes")
            
            EmptyStateView(
                type: .checklists, 
                searchText: "", 
                actionButtonTitle: "New Checklist") {}
                .previewDisplayName("Checklists")
            
            EmptyStateView(
                type: .search, 
                searchText: "meeting")
                .previewDisplayName("Search")
            
            EmptyStateView(
                type: .filtered, 
                searchText: "")
                .previewDisplayName("Filtered")
            
            EmptyStateView(
                type: .folder, 
                searchText: "", 
                actionButtonTitle: "Add Item") {}
                .previewDisplayName("Folder")
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppTheme.Colors.background)
    }
}

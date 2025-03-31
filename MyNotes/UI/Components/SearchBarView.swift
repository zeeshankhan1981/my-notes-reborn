import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var placeholder: String
    var onSubmit: () -> Void = {}
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            TextField(placeholder, text: $searchText)
                .font(AppTheme.Typography.body())
                .submitLabel(.search)
                .onSubmit(onSubmit)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    // Add haptic feedback for clear action
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .transition(.scale.combined(with: .opacity))
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(10)
        .background(colorScheme == .dark ? 
            AppTheme.Colors.cardSurface : 
            AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.Dimensions.radiusM)
        .shadow(
            color: AppTheme.Colors.cardShadow.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBarView(
            searchText: .constant(""),
            isSearching: .constant(false),
            placeholder: "Search notes..."
        )
        
        SearchBarView(
            searchText: .constant("Hello"),
            isSearching: .constant(true),
            placeholder: "Search notes..."
        )
    }
    .padding()
    .background(AppTheme.Colors.background)
}

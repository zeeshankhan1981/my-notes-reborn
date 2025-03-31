import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var placeholder: String
    var onSubmit: () -> Void = {}
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isFocused || !searchText.isEmpty ? 
                                     AppTheme.Colors.primary : 
                                     AppTheme.Colors.textTertiary)
                    .font(.system(size: 16))
                
                TextField(placeholder, text: $searchText)
                    .font(AppTheme.Typography.body())
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
                    .focused($isFocused)
                    .onChange(of: isFocused) { oldValue, newValue in
                        if newValue {
                            // Haptic feedback when search is focused
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        // Keep focus on the search field
                        isFocused = true
                        // Add haptic feedback for clear action
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .font(.system(size: 16))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(12)
            .background(colorScheme == .dark ? 
                AppTheme.Colors.cardSurface : 
                AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.Dimensions.radiusM)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                    .stroke(isFocused ? AppTheme.Colors.primary.opacity(0.2) : Color.clear, lineWidth: 1.5)
            )
            
            if !searchText.isEmpty {
                HStack {
                    Text("Searching for \"\(searchText)\"")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(searchText.count) character\(searchText.count != 1 ? "s" : "")")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding(.horizontal, 4)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .transition(.opacity)
            }
        }
        .onChange(of: isSearching) { oldValue, newValue in
            if newValue {
                // Auto-focus when search mode is activated
                isFocused = true
            } else {
                // Clear search when exiting search mode
                searchText = ""
                isFocused = false
            }
        }
        .animation(.easeInOut(duration: 0.2), value: searchText)
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

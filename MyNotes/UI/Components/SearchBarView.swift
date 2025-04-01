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
                    .animation(.easeInOut(duration: 0.2), value: searchText)
                }
                
                Button(action: {
                    withAnimation(AppTheme.Animations.standardCurve) {
                        // Clear and dismiss search
                        searchText = ""
                        isFocused = false
                        isSearching = false
                    }
                    // Add haptic feedback for cancel action
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    Text("Cancel")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(AppTheme.Typography.subheadline())
                }
                .padding(.leading, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                    .fill(AppTheme.Colors.cardSurface.opacity(0.8))
                    .shadow(
                        color: AppTheme.Colors.cardShadow.opacity(0.08), 
                        radius: 2, 
                        x: 0, 
                        y: 1
                    )
            )
            .onAppear {
                // Auto-focus the search field when it appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
            
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

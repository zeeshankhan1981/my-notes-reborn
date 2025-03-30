import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Base colors - more refined and subdued
        static let primary = Color("AppPrimaryColor")
        static let secondary = Color("AppSecondaryColor")
        static let accent = Color("AccentColor")
        static let background = Color("BackgroundColor")
        static let secondaryBackground = Color("SecondaryBackgroundColor")
        
        // Text colors - higher contrast for better readability
        static let textPrimary = Color("TextPrimaryColor")
        static let textSecondary = Color("TextSecondaryColor")
        static let textTertiary = Color("TextTertiaryColor")
        
        // Status colors - slightly desaturated for a more refined look
        static let success = Color.green.opacity(0.9)
        static let warning = Color.yellow.opacity(0.9)
        static let error = Color.red.opacity(0.9)
        static let info = Color.blue.opacity(0.9)
        
        // iA Writer inspired surface colors
        static let cardSurface = Color("SecondaryBackgroundColor")
        static let cardShadow = Color.black.opacity(0.03)
        static let divider = Color("TextTertiaryColor").opacity(0.2)
        static let highlightBackground = Color("AppPrimaryColor").opacity(0.05)
    }
    
    // MARK: - Dimensions
    struct Dimensions {
        // More generous spacing for a cleaner look
        static let cornerRadius: CGFloat = 8 // Less rounded for a cleaner look
        static let smallCornerRadius: CGFloat = 4
        static let iconSize: CGFloat = 24
        static let smallIconSize: CGFloat = 16
        static let largeIconSize: CGFloat = 32
        
        // Increased spacing for better content breathing room
        static let spacing: CGFloat = 20
        static let smallSpacing: CGFloat = 12
        static let tinySpacing: CGFloat = 6
        static let largeSpacing: CGFloat = 32
        
        // Same interaction sizes
        static let buttonHeight: CGFloat = 48
        static let minTouchSize: CGFloat = 44
        
        // New dimensions for typography
        static let lineHeight: CGFloat = 1.5
        static let paragraphSpacing: CGFloat = 8
        static let cardElevation: CGFloat = 2 // Subtle elevation
    }
    
    // MARK: - Typography
    struct Typography {
        // More refined typography with SF Mono options for code/writing
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.medium) // Less heavy weight
        static let headline = Font.headline.weight(.medium)
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let footnote = Font.footnote
        static let caption = Font.caption
        
        // iA Writer inspired typography
        static let editor = Font.system(size: 16).monospaced() // Monospaced for focus
        static let editorHeadline = Font.system(size: 18).weight(.medium).monospaced()
        static let mono = Font.system(size: 14).monospaced()
    }
    
    // MARK: - Animation
    struct Animation {
        // More subtle animations
        static let standard = SwiftUI.Animation.easeOut(duration: 0.25)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeOut(duration: 0.4)
        static let springy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        
        // New subtle animations
        static let fade = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let subtle = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - View Extensions
extension View {
    // Cleaner card style with subtle elevation
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.cardSurface)
            .cornerRadius(AppTheme.Dimensions.cornerRadius)
            .shadow(color: AppTheme.Colors.cardShadow, 
                    radius: AppTheme.Dimensions.cardElevation, 
                    x: 0, 
                    y: AppTheme.Dimensions.cardElevation/2)
    }
    
    // More refined button style
    func primaryButtonStyle() -> some View {
        self
            .padding(.vertical, AppTheme.Dimensions.smallSpacing)
            .padding(.horizontal, AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.Dimensions.smallCornerRadius)
    }
    
    // New writer-focused styles
    func editorStyle() -> some View {
        self
            .font(AppTheme.Typography.editor)
            .lineSpacing(4)
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.background)
    }
    
    // Focus mode style for current paragraph
    func focusModeHighlight() -> some View {
        self
            .padding(AppTheme.Dimensions.smallSpacing)
            .background(AppTheme.Colors.highlightBackground)
            .cornerRadius(AppTheme.Dimensions.smallCornerRadius)
    }
    
    // Minimalist input field style
    func minimalTextField() -> some View {
        self
            .padding(AppTheme.Dimensions.smallSpacing)
            .background(AppTheme.Colors.background)
            .cornerRadius(AppTheme.Dimensions.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.smallCornerRadius)
                    .stroke(AppTheme.Colors.divider, lineWidth: 1)
            )
    }
}

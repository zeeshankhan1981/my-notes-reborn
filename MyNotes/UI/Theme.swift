import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Base colors
        static let primary = Color("PrimaryColor")
        static let secondary = Color("SecondaryColor")
        static let accent = Color("AccentColor")
        static let background = Color("BackgroundColor")
        static let secondaryBackground = Color("SecondaryBackgroundColor")
        
        // Text colors
        static let textPrimary = Color("TextPrimaryColor")
        static let textSecondary = Color("TextSecondaryColor")
        static let textTertiary = Color("TextTertiaryColor")
        
        // Status colors
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        static let info = Color.blue
    }
    
    // MARK: - Dimensions
    struct Dimensions {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let iconSize: CGFloat = 24
        static let smallIconSize: CGFloat = 16
        static let largeIconSize: CGFloat = 32
        
        static let spacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let tinySpacing: CGFloat = 4
        static let largeSpacing: CGFloat = 24
        
        static let buttonHeight: CGFloat = 48
        static let minTouchSize: CGFloat = 44
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let footnote = Font.footnote
        static let caption = Font.caption
    }
    
    // MARK: - Animation
    struct Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let springy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.Dimensions.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .padding(.vertical, AppTheme.Dimensions.smallSpacing)
            .padding(.horizontal, AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.Dimensions.smallCornerRadius)
    }
}

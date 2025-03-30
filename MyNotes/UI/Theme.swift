import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Base colors - minimal and focused
        static let primary = Color("AppPrimaryColor") 
        static let secondary = Color("AppSecondaryColor")
        static let accent = Color.blue // Simple blue accent like iA Writer
        static let background = Color.white // Clean white background
        static let secondaryBackground = Color(UIColor.systemGray6) // Very subtle gray
        
        // Text colors - high contrast for better readability
        static let textPrimary = Color.black // Pure black for text
        static let textSecondary = Color(UIColor.darkGray)
        static let textTertiary = Color(UIColor.gray)
        
        // Status colors - minimal but clear
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Simplified surface colors
        static let cardSurface = Color.white
        static let cardShadow = Color.black.opacity(0.05)
        static let divider = Color(UIColor.systemGray5)
        static let highlightBackground = Color.blue.opacity(0.1)
        
        // Focus mode
        static let focusBackground = Color(white: 0.98)
    }
    
    // MARK: - Dimensions
    struct Dimensions {
        // Minimal spacing for a cleaner look
        static let cornerRadius: CGFloat = 4 // Much less rounded corners
        static let smallCornerRadius: CGFloat = 2
        static let iconSize: CGFloat = 20 // Smaller icons
        static let smallIconSize: CGFloat = 14
        static let largeIconSize: CGFloat = 28
        
        // Consistent spacing
        static let spacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let tinySpacing: CGFloat = 4
        static let largeSpacing: CGFloat = 24
        
        // Touch targets
        static let buttonHeight: CGFloat = 44
        static let minTouchSize: CGFloat = 44
        
        // Typography measurements
        static let lineHeight: CGFloat = 1.6 // Increased line height like iA Writer
        static let paragraphSpacing: CGFloat = 10
        static let cardElevation: CGFloat = 1 // Very subtle elevation
    }
    
    // MARK: - Typography
    struct Typography {
        // iA Writer inspired typography - focused on monospaced
        static func largeTitle() -> Font {
            return Font.system(size: 28, weight: .bold)
        }
        
        static func title() -> Font {
            return Font.system(size: 22, weight: .medium)
        }
        
        static func headline() -> Font {
            return Font.system(size: 17, weight: .semibold)
        }
        
        static func subheadline() -> Font {
            return Font.system(size: 15, weight: .regular)
        }
        
        // Core typography - monospaced for content
        static func body() -> Font {
            return Font.system(size: 16)
        }
        
        static func bodyMono() -> Font {
            return Font.monospaced(Font.system(size: 16))()
        }
        
        static func caption() -> Font {
            return Font.system(size: 13)
        }
        
        // Editor typography - fully monospaced
        static func editor() -> Font {
            return Font.monospaced(Font.system(size: 16))()
        }
        
        static func editorHeadline() -> Font {
            return Font.monospaced(Font.system(size: 18, weight: .medium))()
        }
        
        static func editorTitle() -> Font {
            return Font.monospaced(Font.system(size: 22, weight: .bold))()
        }
    }
    
    // MARK: - Animation
    struct Animation {
        // Subtle, quick animations
        static let standard = SwiftUI.Animation.easeOut(duration: 0.2)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.1)
        static let slow = SwiftUI.Animation.easeOut(duration: 0.3)
        
        // Content transitions
        static let fade = SwiftUI.Animation.easeInOut(duration: 0.15)
    }
}

// MARK: - View Extensions
extension View {
    // Clean, minimal card style
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.cardSurface)
            .cornerRadius(AppTheme.Dimensions.cornerRadius)
            .shadow(color: AppTheme.Colors.cardShadow, 
                    radius: 1, 
                    x: 0, 
                    y: 1)
    }
    
    // iA Writer-style content container
    func contentContainer() -> some View {
        self
            .padding(.horizontal, AppTheme.Dimensions.spacing)
            .padding(.vertical, AppTheme.Dimensions.smallSpacing)
            .background(AppTheme.Colors.background)
    }
    
    // Minimal button style
    func minimalButtonStyle() -> some View {
        self
            .font(AppTheme.Typography.body())
            .foregroundColor(AppTheme.Colors.accent)
            .padding(.vertical, AppTheme.Dimensions.smallSpacing)
            .padding(.horizontal, AppTheme.Dimensions.spacing)
    }
    
    // Focus mode style
    func focusModeStyle() -> some View {
        self
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.focusBackground)
            .cornerRadius(0) // No corner radius for the clean iA Writer look
    }
    
    // Text field style
    func iaTextFieldStyle() -> some View {
        self
            .font(AppTheme.Typography.bodyMono())
            .padding(AppTheme.Dimensions.smallSpacing)
            .background(AppTheme.Colors.background)
            .cornerRadius(0) // No rounding
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.Colors.divider),
                alignment: .bottom
            )
    }
}

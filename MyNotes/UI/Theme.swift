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
        static let danger = Color.red // Alias for error to maintain compatibility
        static let info = Color.blue
        
        // Simplified surface colors
        static let cardSurface = Color.white
        static let cardShadow = Color.black.opacity(0.05)
        static let divider = Color(UIColor.systemGray5)
        static let highlightBackground = Color.blue.opacity(0.1)
        static let selectedRowBackground = Color.blue.opacity(0.08) // For selected rows/items
        
        // Focus mode
        static let focusBackground = Color(white: 0.98)
        
        // New interface states for Todoist-inspired design
        static let pressedState = Color.gray.opacity(0.3)
        static let disabledState = Color.gray.opacity(0.4)
        static let textOnPrimary = Color.white
        
        // Tag colors - for visualization (Todoist-inspired)
        static let tagColors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .red,
            .yellow, .teal, .indigo, .gray, .brown, .mint
        ]
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
        
        // New spacing constants (Todoist-inspired)
        static let spacingXXS: CGFloat = 2
        static let spacingXS: CGFloat = 4
        static let spacingS: CGFloat = 8
        static let spacingM: CGFloat = 16
        static let spacingL: CGFloat = 24
        static let spacingXL: CGFloat = 32
        
        // Card radii (Todoist-inspired)
        static let radiusXS: CGFloat = 2
        static let radiusS: CGFloat = 4
        static let radiusM: CGFloat = 8
        static let radiusL: CGFloat = 12
        
        // Touch targets
        static let buttonHeight: CGFloat = 44
        static let minTouchSize: CGFloat = 44
        
        // Elevation (Todoist-inspired)
        static let elevationXS: CGFloat = 1
        static let elevationS: CGFloat = 2
        static let elevationM: CGFloat = 4
        static let elevationL: CGFloat = 8
        
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
            return Font.system(size: 22, weight: .bold)
        }
        
        static func title2() -> Font {
            return Font.system(size: 20, weight: .bold)
        }
        
        static func title3() -> Font {
            return Font.system(size: 18, weight: .semibold)
        }
        
        static func headline() -> Font {
            return Font.system(size: 16, weight: .semibold)
        }
        
        static func subheadline() -> Font {
            return Font.system(size: 14, weight: .semibold)
        }
        
        static func body() -> Font {
            return Font.system(size: 16, weight: .regular)
        }
        
        static func bodyCompact() -> Font {
            return Font.system(size: 14, weight: .regular)
        }
        
        static func footnote() -> Font {
            return Font.system(size: 12, weight: .regular)
        }
        
        static func caption() -> Font {
            return Font.system(size: 10, weight: .regular)
        }
        
        // Core typography - monospaced for content
        static func bodyMono() -> Font {
            return Font.monospaced(Font.system(size: 16))()
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
        
        // New typography styles (Todoist-inspired)
        static func button() -> Font {
            return Font.system(size: 14, weight: .medium)
        }
        
        static func captionSmall() -> Font {
            return Font.system(size: 10)
        }
    }
    
    // MARK: - Animations (Todoist-inspired)
    struct Animations {
        // Standard durations
        static let durationXS: Double = 0.1
        static let durationS: Double = 0.2
        static let durationM: Double = 0.3
        static let durationL: Double = 0.5
        
        // Curves
        static let standardCurve = Animation.easeInOut(duration: durationM)
        static let accelerateCurve = Animation.easeIn(duration: durationM)
        static let decelerateCurve = Animation.easeOut(duration: durationM)
        static let quickCurve = Animation.easeInOut(duration: durationS)
        
        // Specific animations
        static let buttonPress = Animation.easeIn(duration: durationXS)
        static let listTransition = Animation.easeInOut(duration: durationM)
        static let checkboxToggle = Animation.spring(response: 0.2, dampingFraction: 0.6)
        
        // Delayed animations
        static func staggered(index: Int, baseDelay: Double = 0.05) -> Animation {
            Animation.easeInOut(duration: 0.25).delay(Double(index) * baseDelay)
        }
        
        // Complex animation sequences
        static let slideInFromBottom = Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let fadeInSlowly = Animation.easeIn(duration: 0.5)
        static let quickFadeOut = Animation.easeOut(duration: 0.15)
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
    
    // Enhanced card style (Todoist-inspired)
    func enhancedCardStyle(elevation: CGFloat = AppTheme.Dimensions.elevationXS) -> some View {
        self
            .padding(AppTheme.Dimensions.spacing)
            .background(AppTheme.Colors.cardSurface)
            .cornerRadius(AppTheme.Dimensions.radiusM)
            .shadow(
                color: AppTheme.Colors.cardShadow.opacity(0.1),
                radius: elevation * 2,
                x: 0,
                y: elevation
            )
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
    
    // List item transition animation (Todoist-inspired)
    func listItemTransition(delay: Double = 0) -> some View {
        self
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(
                Animation
                    .easeInOut(duration: AppTheme.Animations.durationM)
                    .delay(delay),
                value: UUID()
            )
    }
    
    // Clean, minimal card style
    func cardStyle(elevation: CGFloat = AppTheme.Dimensions.cardElevation) -> some View {
        self
            .background(AppTheme.Colors.cardSurface)
            .cornerRadius(AppTheme.Dimensions.cornerRadius)
            .shadow(color: AppTheme.Colors.cardShadow,
                    radius: elevation,
                    x: 0,
                    y: elevation)
    }
    
    // Enhanced card style with interactive feedback (Todoist-inspired)
    func interactiveCardStyle(isPressed: Bool = false) -> some View {
        self
            .background(AppTheme.Colors.cardSurface)
            .cornerRadius(AppTheme.Dimensions.radiusM)
            .shadow(
                color: AppTheme.Colors.cardShadow.opacity(isPressed ? 0.03 : 0.1),
                radius: isPressed ? 1 : 3,
                x: 0,
                y: isPressed ? 1 : 2
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
    }
    
    // Custom pill-shaped tag style (Todoist-inspired)
    func tagStyle(color: Color) -> some View {
        self
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
    }
    
    // Primary button style (Todoist-inspired)
    func primaryButtonStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppTheme.Colors.primary)
            .foregroundColor(AppTheme.Colors.textOnPrimary)
            .cornerRadius(AppTheme.Dimensions.radiusM)
            .shadow(
                color: AppTheme.Colors.primary.opacity(0.3),
                radius: 3,
                x: 0,
                y: 2
            )
    }
    
    // Accent button
    func accentButtonStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppTheme.Colors.accent)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.Dimensions.radiusM)
    }
    
    // Text button style
    func textButtonStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(AppTheme.Colors.primary)
    }
}

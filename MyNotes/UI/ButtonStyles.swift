import SwiftUI

// MARK: - Button Styles

/// A button style that provides a subtle scale and opacity effect when pressed
/// Inspired by Todoist's interactive feel
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// A button style that provides a more pronounced scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A button style for primary actions with background
struct FilledButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppTheme.Colors.primary
    var foregroundColor: Color = .white
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                isDisabled ? AppTheme.Colors.disabledState : backgroundColor
            )
            .foregroundColor(foregroundColor)
            .cornerRadius(AppTheme.Dimensions.radiusM)
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.97 : 1)
            .opacity(configuration.isPressed && !isDisabled ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// A button style for secondary actions with outlined border
struct OutlinedButtonStyle: ButtonStyle {
    var borderColor: Color = AppTheme.Colors.primary
    var foregroundColor: Color = AppTheme.Colors.primary
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                    .stroke(isDisabled ? AppTheme.Colors.disabledState : borderColor, lineWidth: 1.5)
            )
            .foregroundColor(isDisabled ? AppTheme.Colors.textTertiary : foregroundColor)
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.97 : 1)
            .opacity(configuration.isPressed && !isDisabled ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

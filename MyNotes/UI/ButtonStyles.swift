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

/// A button style for navigation bar actions
struct NavigationButtonStyle: ButtonStyle {
    var isPrimary: Bool = false
    var isDestructive: Bool = false
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: isPrimary ? .semibold : .regular))
            .foregroundColor(
                isDisabled ? AppTheme.Colors.textTertiary :
                isDestructive ? AppTheme.Colors.error :
                isPrimary ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary
            )
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// A standardized Save button for editor views
struct SaveButton: View {
    var action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()
            action()
        }) {
            Text("Save")
                .font(.system(size: 17, weight: .semibold))
        }
        .buttonStyle(NavigationButtonStyle(isPrimary: true, isDisabled: isDisabled))
        .disabled(isDisabled)
    }
}

/// A standardized Cancel button for editor views
struct CancelButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            action()
        }) {
            Text("Cancel")
                .font(.system(size: 17))
        }
        .buttonStyle(NavigationButtonStyle())
    }
}

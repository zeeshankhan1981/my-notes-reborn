import SwiftUI

struct AnimatedCheckbox: View {
    @Binding var isChecked: Bool
    var onToggle: (() -> Void)? = nil
    var size: CGFloat = 24
    var primaryColor: Color = AppTheme.Colors.primary
    var secondaryColor: Color = AppTheme.Colors.success
    
    @State private var animationTrigger = false
    @State private var innerCircleScale: CGFloat = 0
    
    var body: some View {
        Button(action: {
            withAnimation(AppTheme.Animations.checkboxToggle) {
                isChecked.toggle()
                animationTrigger.toggle()
                innerCircleScale = isChecked ? 1.0 : 0.0
            }
            
            // Add haptic feedback for satisfaction
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            onToggle?()
        }) {
            ZStack {
                // Outer circle
                Circle()
                    .strokeBorder(
                        isChecked ? secondaryColor : AppTheme.Colors.divider,
                        lineWidth: size * 0.08
                    )
                    .frame(width: size, height: size)
                    .scaleEffect(animationTrigger ? 0.95 : 1.0)
                
                // Inner checkmark
                Group {
                    if isChecked {
                        ZStack {
                            // Background fill
                            Circle()
                                .fill(secondaryColor)
                                .frame(width: size * 0.8, height: size * 0.8)
                                .scaleEffect(innerCircleScale)
                            
                            // Checkmark
                            Image(systemName: "checkmark")
                                .font(.system(size: size * 0.5, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(innerCircleScale)
                                .scaleEffect(animationTrigger ? 1.0 : 0.5)
                        }
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            // Ensure state is synchronized on appear
            innerCircleScale = isChecked ? 1.0 : 0.0
        }
    }
}

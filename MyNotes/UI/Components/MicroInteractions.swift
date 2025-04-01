import SwiftUI

// MARK: - Button Styles

/// A button style that provides subtle scaling and haptic feedback
struct InteractiveButtonStyle: ButtonStyle {
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
    var scaleAmount: CGFloat = 0.97
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue && !oldValue {
                    let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                    generator.impactOccurred()
                }
            }
    }
}

/// A button style that provides a satisfying press effect with slightly deeper scale and medium haptic
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue && !oldValue {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
    }
}

// MARK: - Animated Modifiers

/// Adds a subtle hover effect when the user presses on a view
struct PressableViewStyle: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onTapGesture {
                // Quick press animation
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = true
                }
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Release animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
            }
    }
}

/// Adds an attention-grabbing pulse animation to draw attention to a view
struct PulseAnimation: ViewModifier {
    @State private var animating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(0.3))
                    .scaleEffect(animating ? 1.5 : 0.8)
                    .opacity(animating ? 0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: false),
                        value: animating
                    )
            )
            .onAppear {
                animating = true
            }
    }
}

/// Adds a subtle fade in animation when a view appears
struct FadeInAnimation: ViewModifier {
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                }
            }
    }
}

/// Adds a subtle slide in animation when a view appears
struct SlideInAnimation: ViewModifier {
    enum Direction {
        case top, bottom, leading, trailing
    }
    
    let direction: Direction
    let distance: CGFloat = 20
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: direction == .leading ? offset : (direction == .trailing ? -offset : 0),
                y: direction == .top ? offset : (direction == .bottom ? -offset : 0)
            )
            .opacity(opacity)
            .onAppear {
                offset = distance
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - Extension for View

extension View {
    func pressableStyle() -> some View {
        modifier(PressableViewStyle())
    }
    
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
    
    func fadeInAnimation() -> some View {
        modifier(FadeInAnimation())
    }
    
    func slideInAnimation(from direction: SlideInAnimation.Direction) -> some View {
        modifier(SlideInAnimation(direction: direction))
    }
    
    /// Adds a subtle hover effect to a view
    func hoverEffect(scale: CGFloat = 1.02) -> some View {
        self
            .buttonStyle(InteractiveButtonStyle(scaleAmount: scale))
    }
}

// MARK: - Animation Presets

extension Animation {
    /// A subtle animation for UI elements when they appear
    static var subtleAppear: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    /// A quick animation for UI elements that need to feel responsive
    static var quickResponse: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
    
    /// A bouncy animation for celebratory moments
    static var celebratory: Animation {
        .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3)
    }
}

// MARK: - Preview

struct MicroInteractions_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Button Styles
            Button("Interactive Button") {}
                .padding()
                .background(AppTheme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
                .buttonStyle(InteractiveButtonStyle())
            
            Button("Primary Button") {}
                .padding()
                .background(AppTheme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
                .buttonStyle(PrimaryButtonStyle())
            
            // Pressable View
            Text("Pressable View")
                .padding()
                .background(AppTheme.Colors.cardSurface)
                .cornerRadius(8)
                .pressableStyle()
            
            // Pulse Animation
            Circle()
                .fill(AppTheme.Colors.primary)
                .frame(width: 50, height: 50)
                .pulseAnimation()
            
            // Fade In
            Text("Fade In Text")
                .padding()
                .background(AppTheme.Colors.cardSurface)
                .cornerRadius(8)
                .fadeInAnimation()
            
            // Slide In
            Text("Slide In Text")
                .padding()
                .background(AppTheme.Colors.cardSurface)
                .cornerRadius(8)
                .slideInAnimation(from: .bottom)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

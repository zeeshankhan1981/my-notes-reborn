import SwiftUI

struct AnimatedCheckbox: View {
    @Binding var isChecked: Bool
    var onToggle: (() -> Void)? = nil
    var size: CGFloat = 24
    var primaryColor: Color = AppTheme.Colors.primary
    var secondaryColor: Color = AppTheme.Colors.success
    
    @State private var animationTrigger = false
    @State private var innerCircleScale: CGFloat = 0
    @State private var rotationDegrees: Double = 0
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            // First scale up slightly
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                bounceScale = 1.2
            }
            
            // Then toggle the checkbox after a tiny delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(Animation.spring(response: 0.35, dampingFraction: 0.7)) {
                    isChecked.toggle()
                    animationTrigger.toggle()
                    innerCircleScale = isChecked ? 1.0 : 0.0
                    rotationDegrees = isChecked ? 360 : 0
                    bounceScale = 1.0
                }
                
                // Add haptic feedback with proper timing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
            
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
                    .scaleEffect(bounceScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceScale)
                
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
                                .rotationEffect(.degrees(rotationDegrees * 0.5))
                        }
                    }
                }
            }
            .scaleEffect(bounceScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceScale)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Ensure state is synchronized on appear
            innerCircleScale = isChecked ? 1.0 : 0.0
            rotationDegrees = isChecked ? 360 : 0
        }
    }
}

// Enhanced animated strikethrough text for checklist items
struct AnimatedStrikethroughText: View {
    let text: String
    @Binding var isStrikethrough: Bool
    var font: Font = AppTheme.Typography.body()
    var foregroundColor: Color = AppTheme.Colors.textPrimary
    var strikethroughColor: Color = AppTheme.Colors.textTertiary
    
    @State private var width: CGFloat = 0
    @State private var strikethroughWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            // The text
            Text(text)
                .font(font)
                .foregroundColor(isStrikethrough ? strikethroughColor : foregroundColor)
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            self.width = geometry.size.width
                        }
                    }
                )
                .animation(.easeOut(duration: 0.2), value: isStrikethrough)
            
            // The strikethrough line
            if width > 0 {
                Rectangle()
                    .fill(strikethroughColor)
                    .frame(width: strikethroughWidth, height: 1.5)
                    .offset(y: -2)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: strikethroughWidth)
            }
        }
        .onChange(of: isStrikethrough) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                strikethroughWidth = newValue ? width : 0
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                strikethroughWidth = isStrikethrough ? width : 0
            }
        }
    }
}

// Preview provider
struct AnimatedCheckbox_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StateWrapper(initialState: false) { state in
                HStack(spacing: 16) {
                    AnimatedCheckbox(isChecked: state)
                    AnimatedStrikethroughText(text: "Complete this task", isStrikethrough: state)
                }
                .padding()
                .background(AppTheme.Colors.cardSurface)
                .cornerRadius(8)
            }
            
            StateWrapper(initialState: true) { state in
                HStack(spacing: 16) {
                    AnimatedCheckbox(isChecked: state)
                    AnimatedStrikethroughText(text: "Completed task", isStrikethrough: state)
                }
                .padding()
                .background(AppTheme.Colors.cardSurface)
                .cornerRadius(8)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
    
    struct StateWrapper<Content: View>: View {
        @State private var state: Bool
        let content: (Binding<Bool>) -> Content
        
        init(initialState: Bool, @ViewBuilder content: @escaping (Binding<Bool>) -> Content) {
            self._state = State(initialValue: initialState)
            self.content = content
        }
        
        var body: some View {
            content($state)
        }
    }
}

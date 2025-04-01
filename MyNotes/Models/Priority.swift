import SwiftUI

enum Priority: Int, Codable, Identifiable, CaseIterable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return Color.gray
        case .low: return Color.blue
        case .medium: return Color.orange
        case .high: return Color.red
        }
    }
    
    var icon: String {
        switch self {
        case .none: return ""
        case .low: return "flag"
        case .medium: return "flag.fill"
        case .high: return "exclamationmark.triangle.fill"
        }
    }
    
    var flagsDisplay: String {
        switch self {
        case .none: return ""
        case .low: return "!"
        case .medium: return "!!"
        case .high: return "!!!"
        }
    }
}

struct PriorityIndicator: View {
    let priority: Priority
    var size: CGFloat = 12
    var showBackground: Bool = false
    
    var body: some View {
        if priority != .none {
            HStack(spacing: 2) {
                if showBackground {
                    Circle()
                        .fill(priority.color.opacity(0.2))
                        .frame(width: size * 1.6, height: size * 1.6)
                        .overlay(
                            Image(systemName: priority.icon)
                                .font(.system(size: size))
                                .foregroundColor(priority.color)
                        )
                } else {
                    Image(systemName: priority.icon)
                        .font(.system(size: size))
                        .foregroundColor(priority.color)
                }
            }
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(), value: priority)
        }
    }
}

struct PrioritySelector: View {
    @Binding var selectedPriority: Priority
    var onSelect: ((Priority) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Priority.allCases) { priority in
                Button(action: {
                    withAnimation {
                        selectedPriority = priority
                    }
                    onSelect?(priority)
                    
                    // Add haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    ZStack {
                        // Background
                        Circle()
                            .fill(priority == selectedPriority ? 
                                  priority.color.opacity(0.2) : 
                                  Color.gray.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        // Icon
                        if priority == .none {
                            Image(systemName: "flag.slash")
                                .font(.system(size: 16))
                                .foregroundColor(priority == selectedPriority ? 
                                                 priority.color : 
                                                 Color.gray)
                        } else {
                            Image(systemName: priority.icon)
                                .font(.system(size: 16))
                                .foregroundColor(priority == selectedPriority ? 
                                                 priority.color : 
                                                 Color.gray)
                        }
                    }
                    .scaleEffect(priority == selectedPriority ? 1.1 : 1.0)
                    .shadow(color: priority == selectedPriority ? 
                            priority.color.opacity(0.3) : 
                            Color.clear, 
                            radius: 3, x: 0, y: 1)
                }
                .buttonStyle(InteractiveButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
}

struct Priority_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Priority Indicators
            HStack(spacing: 20) {
                ForEach(Priority.allCases) { priority in
                    PriorityIndicator(priority: priority, showBackground: true)
                }
            }
            
            // Priority Selector
            StateWrapper(initialState: .none) { state in
                PrioritySelector(selectedPriority: state)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
    
    struct StateWrapper<Content: View>: View {
        @State private var state: Priority
        let content: (Binding<Priority>) -> Content
        
        init(initialState: Priority, @ViewBuilder content: @escaping (Binding<Priority>) -> Content) {
            self._state = State(initialValue: initialState)
            self.content = content
        }
        
        var body: some View {
            content($state)
        }
    }
}

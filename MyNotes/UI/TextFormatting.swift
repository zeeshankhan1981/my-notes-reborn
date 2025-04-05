import SwiftUI
import UIKit

/// Text formatting options for basic editing
enum TextFormatting: Hashable {
    case bold
    case italic
    case underline
    case alignLeft
    case alignCenter
    case alignRight
    case bulletList
    case numberedList
    case fontSize(CGFloat)
    case textColor(UIColor)
    case insertLink(URL, String)
    
    // For comparing format states
    func hash(into hasher: inout Hasher) {
        switch self {
        case .bold: hasher.combine(0)
        case .italic: hasher.combine(1)
        case .underline: hasher.combine(2)
        case .alignLeft: hasher.combine(3)
        case .alignCenter: hasher.combine(4)
        case .alignRight: hasher.combine(5)
        case .bulletList: hasher.combine(6)
        case .numberedList: hasher.combine(7)
        case .fontSize(let size): 
            hasher.combine(8)
            hasher.combine(size)
        case .textColor(let color): 
            hasher.combine(9)
            hasher.combine(color.hashValue)
        case .insertLink(let url, let text):
            hasher.combine(10)
            hasher.combine(url.hashValue)
            hasher.combine(text)
        }
    }
    
    static func == (lhs: TextFormatting, rhs: TextFormatting) -> Bool {
        switch (lhs, rhs) {
        case (.bold, .bold), (.italic, .italic), (.underline, .underline),
             (.alignLeft, .alignLeft), (.alignCenter, .alignCenter), (.alignRight, .alignRight),
             (.bulletList, .bulletList), (.numberedList, .numberedList):
            return true
        case (.fontSize(let size1), .fontSize(let size2)):
            return size1 == size2
        case (.textColor(let color1), .textColor(let color2)):
            return color1 == color2
        case (.insertLink(let url1, let text1), .insertLink(let url2, let text2)):
            return url1 == url2 && text1 == text2
        default:
            return false
        }
    }
}

/// Format button with improved visual feedback
struct FormatButton: View {
    let icon: String
    let action: () -> Void
    let isActive: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isActive ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
                .padding(8)
                .background(
                    Circle()
                        .fill(isActive ? AppTheme.Colors.accent.opacity(0.1) : Color.clear)
                )
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

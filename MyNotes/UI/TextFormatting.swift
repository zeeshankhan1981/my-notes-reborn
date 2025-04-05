import SwiftUI
import UIKit

// Text formatting options
enum TextFormatting {
    case bold
    case italic
    case underline
    case heading
    case list
    case quote
    
    var icon: String {
        switch self {
        case .bold:
            return "bold"
        case .italic:
            return "italic"
        case .underline:
            return "underline"
        case .heading:
            return "textformat.size" // Using a valid SF Symbol that exists
        case .list:
            return "list.bullet"
        case .quote:
            return "text.quote"
        }
    }
    
    var title: String {
        switch self {
        case .bold:
            return "Bold"
        case .italic:
            return "Italic"
        case .underline:
            return "Underline"
        case .heading:
            return "Heading"
        case .list:
            return "List"
        case .quote:
            return "Quote"
        }
    }
}

// Format option button for text formatting
struct FormatOptionButton: View {
    let formatting: TextFormatting
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: formatting.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? .white : .primary)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(isActive ? Color.accentColor : Color(.systemGray5))
                    )
                
                Text(formatting.title)
                    .font(.caption)
                    .foregroundColor(isActive ? .accentColor : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Helper extension to apply formatting to attributed strings
extension NSMutableAttributedString {
    func applyFormatting(_ formatting: TextFormatting, range: NSRange) {
        switch formatting {
        case .bold:
            let fontAttributes = self.attributes(at: range.location, effectiveRange: nil)
            if let font = fontAttributes[.font] as? UIFont {
                let traits = font.fontDescriptor.symbolicTraits
                let descriptor = font.fontDescriptor.withSymbolicTraits(traits.union(.traitBold))
                if let descriptor = descriptor {
                    let newFont = UIFont(descriptor: descriptor, size: font.pointSize)
                    self.addAttribute(.font, value: newFont, range: range)
                }
            }
        case .italic:
            let fontAttributes = self.attributes(at: range.location, effectiveRange: nil)
            if let font = fontAttributes[.font] as? UIFont {
                let traits = font.fontDescriptor.symbolicTraits
                let descriptor = font.fontDescriptor.withSymbolicTraits(traits.union(.traitItalic))
                if let descriptor = descriptor {
                    let newFont = UIFont(descriptor: descriptor, size: font.pointSize)
                    self.addAttribute(.font, value: newFont, range: range)
                }
            }
        case .underline:
            self.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        case .heading:
            let headingFont = UIFont.systemFont(ofSize: 20, weight: .bold)
            self.addAttribute(.font, value: headingFont, range: range)
        case .list:
            // Simple implementation - prepend bullet point
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 15.0
            paragraphStyle.firstLineHeadIndent = 0.0
            self.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            
            // Insert bullet point at the beginning of each paragraph
            let string = self.string as NSString
            let paragraphRange = string.paragraphRange(for: range)
            let bulletPoint = "• "
            
            if !string.substring(with: NSRange(location: paragraphRange.location, length: min(2, paragraphRange.length))).hasPrefix(bulletPoint) {
                self.insert(NSAttributedString(string: bulletPoint), at: paragraphRange.location)
            }
        case .quote:
            // Simple implementation - add quote formatting
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = 20.0
            paragraphStyle.firstLineHeadIndent = 20.0
            self.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            self.addAttribute(.foregroundColor, value: UIColor.darkGray, range: range)
            
            // Add a vertical bar for quotes
            let quoteBarAttachment = NSTextAttachment()
            let quoteBarImage = UIImage(systemName: "quote.opening")?.withTintColor(.gray)
            quoteBarAttachment.image = quoteBarImage
            let quoteBarString = NSAttributedString(attachment: quoteBarAttachment)
            self.insert(quoteBarString, at: range.location)
        }
    }
}

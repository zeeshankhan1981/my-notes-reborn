import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: NSAttributedString
    var placeholder: String
    var onTextChange: (NSAttributedString) -> Void
    
    // Custom attributes currently supported
    enum TextFormatting {
        case bold
        case italic
        case underline
        case strikethrough
        case highlight(UIColor)
        case fontSize(CGFloat)
        case textColor(UIColor)
        case alignLeft
        case alignCenter
        case alignRight
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        
        // Configure the text view
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear
        
        // Set placeholder if needed
        if text.string.isEmpty {
            textView.attributedText = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor.placeholderText,
                    .font: UIFont.preferredFont(forTextStyle: .body)
                ]
            )
        } else {
            textView.attributedText = text
        }
        
        // Add toolbar with formatting options
        setupToolbar(for: textView)
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // To avoid the "Publishing changes from within view updates" warning,
        // we need to be careful about modifying state during view updates
        
        // Check if the current view's text is the placeholder
        let isShowingPlaceholder = textView.attributedText.string == placeholder 
            && textView.textColor == UIColor.placeholderText
        
        // Only update the text view if our binding changed AND
        // we're not showing the placeholder now
        if !isShowingPlaceholder && text.string != textView.attributedText.string {
            // Use a temporary variable to avoid directly modifying state
            let currentText = text
            
            // Update text view without triggering onTextChange
            context.coordinator.updatingFromParent = true
            textView.attributedText = currentText
            context.coordinator.updatingFromParent = false
        }
    }
    
    private func setupToolbar(for textView: UITextView) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        // Create formatting buttons
        let boldButton = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: nil, action: nil)
        boldButton.primaryAction = UIAction { _ in
            self.applyFormatting(.bold, to: textView)
        }
        
        let italicButton = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: nil, action: nil)
        italicButton.primaryAction = UIAction { _ in
            self.applyFormatting(.italic, to: textView)
        }
        
        let underlineButton = UIBarButtonItem(image: UIImage(systemName: "underline"), style: .plain, target: nil, action: nil)
        underlineButton.primaryAction = UIAction { _ in
            self.applyFormatting(.underline, to: textView)
        }
        
        let strikethroughButton = UIBarButtonItem(image: UIImage(systemName: "strikethrough"), style: .plain, target: nil, action: nil)
        strikethroughButton.primaryAction = UIAction { _ in
            self.applyFormatting(.strikethrough, to: textView)
        }
        
        let alignLeftButton = UIBarButtonItem(image: UIImage(systemName: "text.alignleft"), style: .plain, target: nil, action: nil)
        alignLeftButton.primaryAction = UIAction { _ in
            self.applyFormatting(.alignLeft, to: textView)
        }
        
        let alignCenterButton = UIBarButtonItem(image: UIImage(systemName: "text.aligncenter"), style: .plain, target: nil, action: nil)
        alignCenterButton.primaryAction = UIAction { _ in
            self.applyFormatting(.alignCenter, to: textView)
        }
        
        let alignRightButton = UIBarButtonItem(image: UIImage(systemName: "text.alignright"), style: .plain, target: nil, action: nil)
        alignRightButton.primaryAction = UIAction { _ in
            self.applyFormatting(.alignRight, to: textView)
        }
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneButton.primaryAction = UIAction { _ in
            textView.resignFirstResponder()
        }
        
        toolbar.items = [
            boldButton, italicButton, underlineButton, strikethroughButton,
            spacer,
            alignLeftButton, alignCenterButton, alignRightButton,
            spacer,
            doneButton
        ]
        
        textView.inputAccessoryView = toolbar
    }
    
    private func applyFormatting(_ formatting: TextFormatting, to textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange else { return }
        
        let mutableAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)
        let selectedTextRange = NSRange(
            location: textView.offset(from: textView.beginningOfDocument, to: selectedRange.start),
            length: textView.offset(from: selectedRange.start, to: selectedRange.end)
        )
        
        // If no text is selected and range length is 0, just return
        if selectedTextRange.length == 0 {
            return
        }
        
        switch formatting {
        case .bold:
            let existingFontAttribute = mutableAttributedText.attribute(.font, at: selectedTextRange.location, effectiveRange: nil) as? UIFont
            let newFont: UIFont
            
            if let font = existingFontAttribute {
                if font.isBold {
                    // Remove bold
                    newFont = font.withTraits(traits: .traitItalic, ofSize: font.pointSize)
                } else {
                    // Add bold
                    newFont = font.withTraits(traits: [.traitBold, .traitItalic], ofSize: font.pointSize)
                }
            } else {
                newFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
            }
            
            mutableAttributedText.addAttribute(.font, value: newFont, range: selectedTextRange)
            
        case .italic:
            let existingFontAttribute = mutableAttributedText.attribute(.font, at: selectedTextRange.location, effectiveRange: nil) as? UIFont
            let newFont: UIFont
            
            if let font = existingFontAttribute {
                if font.isItalic {
                    // Remove italic
                    newFont = font.withTraits(traits: .traitBold, ofSize: font.pointSize)
                } else {
                    // Add italic
                    newFont = font.withTraits(traits: [.traitBold, .traitItalic], ofSize: font.pointSize)
                }
            } else {
                newFont = UIFont.italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
            }
            
            mutableAttributedText.addAttribute(.font, value: newFont, range: selectedTextRange)
            
        case .underline:
            let existingUnderline = mutableAttributedText.attribute(.underlineStyle, at: selectedTextRange.location, effectiveRange: nil) as? Int
            
            if existingUnderline != nil {
                // Remove underline
                mutableAttributedText.removeAttribute(.underlineStyle, range: selectedTextRange)
            } else {
                // Add underline
                mutableAttributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedTextRange)
            }
            
        case .strikethrough:
            let existingStrikethrough = mutableAttributedText.attribute(.strikethroughStyle, at: selectedTextRange.location, effectiveRange: nil) as? Int
            
            if existingStrikethrough != nil {
                // Remove strikethrough
                mutableAttributedText.removeAttribute(.strikethroughStyle, range: selectedTextRange)
            } else {
                // Add strikethrough
                mutableAttributedText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: selectedTextRange)
            }
            
        case .highlight(let color):
            let existingBgColor = mutableAttributedText.attribute(.backgroundColor, at: selectedTextRange.location, effectiveRange: nil) as? UIColor
            
            if existingBgColor != nil {
                // Remove background color
                mutableAttributedText.removeAttribute(.backgroundColor, range: selectedTextRange)
            } else {
                // Add background color
                mutableAttributedText.addAttribute(.backgroundColor, value: color, range: selectedTextRange)
            }
            
        case .fontSize(let size):
            let existingFontAttribute = mutableAttributedText.attribute(.font, at: selectedTextRange.location, effectiveRange: nil) as? UIFont
            
            if let font = existingFontAttribute {
                let newFont = font.withSize(size)
                mutableAttributedText.addAttribute(.font, value: newFont, range: selectedTextRange)
            } else {
                let newFont = UIFont.systemFont(ofSize: size)
                mutableAttributedText.addAttribute(.font, value: newFont, range: selectedTextRange)
            }
            
        case .textColor(let color):
            mutableAttributedText.addAttribute(.foregroundColor, value: color, range: selectedTextRange)
            
        case .alignLeft:
            let style = NSMutableParagraphStyle()
            style.alignment = .left
            mutableAttributedText.addAttribute(.paragraphStyle, value: style, range: selectedTextRange)
            
        case .alignCenter:
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            mutableAttributedText.addAttribute(.paragraphStyle, value: style, range: selectedTextRange)
            
        case .alignRight:
            let style = NSMutableParagraphStyle()
            style.alignment = .right
            mutableAttributedText.addAttribute(.paragraphStyle, value: style, range: selectedTextRange)
        }
        
        // Update the text view
        textView.attributedText = mutableAttributedText
        
        // Use DispatchQueue.main.async to avoid updating state during view updates
        DispatchQueue.main.async {
            onTextChange(mutableAttributedText)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var updatingFromParent = false
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // Clear placeholder if needed
            if textView.attributedText.string == parent.placeholder {
                textView.attributedText = NSAttributedString(string: "")
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Don't call onTextChange if we're updating from the parent
            if !updatingFromParent {
                // Use DispatchQueue.main.async to avoid updating state during view updates
                DispatchQueue.main.async {
                    self.parent.onTextChange(textView.attributedText)
                }
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // Set placeholder if text is empty
            if textView.text.isEmpty {
                textView.attributedText = NSAttributedString(
                    string: parent.placeholder,
                    attributes: [
                        .foregroundColor: UIColor.placeholderText,
                        .font: UIFont.preferredFont(forTextStyle: .body)
                    ]
                )
            }
        }
    }
}

// Extension to help with font traits
extension UIFont {
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    
    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    
    func withTraits(traits: UIFontDescriptor.SymbolicTraits, ofSize size: CGFloat) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: size)
    }
}

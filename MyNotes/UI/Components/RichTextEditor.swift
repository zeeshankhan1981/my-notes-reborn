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
        // New formatting options
        case bulletList
        case numberedList
        case increaseIndent
        case decreaseIndent
        case insertLink(URL, String)
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
        textView.allowsEditingTextAttributes = true
        textView.dataDetectorTypes = .link
        
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
        let boldButton = createFormattingButton(systemName: "bold", formatting: .bold, textView: textView)
        let italicButton = createFormattingButton(systemName: "italic", formatting: .italic, textView: textView) 
        let underlineButton = createFormattingButton(systemName: "underline", formatting: .underline, textView: textView)
        let strikethroughButton = createFormattingButton(systemName: "strikethrough", formatting: .strikethrough, textView: textView)
        
        // Text alignment buttons
        let alignLeftButton = createFormattingButton(systemName: "text.alignleft", formatting: .alignLeft, textView: textView)
        let alignCenterButton = createFormattingButton(systemName: "text.aligncenter", formatting: .alignCenter, textView: textView)
        let alignRightButton = createFormattingButton(systemName: "text.alignright", formatting: .alignRight, textView: textView)
        
        // Add new list formatting buttons
        let bulletListButton = createFormattingButton(systemName: "list.bullet", formatting: .bulletList, textView: textView)
        let numberedListButton = createFormattingButton(systemName: "list.number", formatting: .numberedList, textView: textView)
        
        // Add indentation buttons
        let indentButton = createFormattingButton(systemName: "increase.indent", formatting: .increaseIndent, textView: textView)
        let outdentButton = createFormattingButton(systemName: "decrease.indent", formatting: .decreaseIndent, textView: textView)
        
        // Link button
        let linkButton = UIBarButtonItem(image: UIImage(systemName: "link"), style: .plain, target: nil, action: nil)
        linkButton.primaryAction = UIAction { _ in
            self.showLinkDialog(for: textView)
        }
        
        // Color picker button
        let colorButton = UIBarButtonItem(image: UIImage(systemName: "paintpalette"), style: .plain, target: nil, action: nil)
        colorButton.primaryAction = UIAction { _ in
            self.showColorPicker(for: textView)
        }
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneButton.primaryAction = UIAction { _ in
            textView.resignFirstResponder()
        }
        
        // Group 1: Text style buttons
        let styleGroup = [boldButton, italicButton, underlineButton, strikethroughButton]
        
        // Group 2: List and indentation buttons
        let listGroup = [bulletListButton, numberedListButton, indentButton, outdentButton]
        
        // Group 3: Alignment buttons
        let alignmentGroup = [alignLeftButton, alignCenterButton, alignRightButton]
        
        // Group 4: Special formatting
        let specialGroup = [linkButton, colorButton]
        
        // Break up the complex expression into multiple steps
        var items = [UIBarButtonItem]()
        items.append(contentsOf: styleGroup)
        items.append(spacer)
        items.append(contentsOf: listGroup)
        items.append(spacer)
        items.append(contentsOf: alignmentGroup)
        items.append(spacer)
        items.append(contentsOf: specialGroup)
        items.append(spacer)
        items.append(doneButton)
        
        toolbar.items = items
        
        textView.inputAccessoryView = toolbar
    }
    
    private func createFormattingButton(systemName: String, formatting: TextFormatting, textView: UITextView) -> UIBarButtonItem {
        let button = UIBarButtonItem(image: UIImage(systemName: systemName), style: .plain, target: nil, action: nil)
        button.primaryAction = UIAction { _ in
            self.applyFormatting(formatting, to: textView)
        }
        return button
    }
    
    private func showLinkDialog(for textView: UITextView) {
        // This won't work directly in a UIViewRepresentable
        // We need to use a UIAlertController from the hosting view controller
        // For now, we'll just add a placeholder link
        guard let selectedRange = textView.selectedTextRange else { return }
        let selectedText = textView.text(in: selectedRange) ?? ""
        
        if !selectedText.isEmpty {
            let url = URL(string: "https://example.com") ?? URL(string: "https://apple.com")!
            self.applyFormatting(.insertLink(url, selectedText), to: textView)
        }
    }
    
    private func showColorPicker(for textView: UITextView) {
        // This would ideally show a color picker
        // We'll use a placeholder implementation with a few preset colors
        guard let selectedRange = textView.selectedTextRange else { return }
        let selectedText = textView.text(in: selectedRange) ?? ""
        
        if !selectedText.isEmpty {
            // Apply a sample color
            self.applyFormatting(.textColor(.systemBlue), to: textView)
        }
    }
    
    private func applyFormatting(_ formatting: TextFormatting, to textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange else { return }
        
        let mutableAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)
        let selectedTextRange = NSRange(
            location: textView.offset(from: textView.beginningOfDocument, to: selectedRange.start),
            length: textView.offset(from: selectedRange.start, to: selectedRange.end)
        )
        
        // If no text is selected and range length is 0, just return for most formatting operations
        // Use pattern matching instead of != operator for enum comparison
        if selectedTextRange.length == 0 {
            switch formatting {
            case .bulletList, .numberedList, .increaseIndent, .decreaseIndent:
                // These formatting options can work with cursor placement
                break
            default:
                // All other formatting options require selected text
                return
            }
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
            
        case .bulletList:
            // Get paragraph range
            let text = mutableAttributedText.string
            let paragraphRange = getParagraphRange(for: selectedTextRange, in: text)
            
            // Apply bullet list formatting
            let paragraphStyle = mutableAttributedText.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            
            paragraphStyle.headIndent = 20.0
            paragraphStyle.firstLineHeadIndent = 0.0
            paragraphStyle.tailIndent = 0.0
            
            mutableAttributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
            
            // Apply bullet symbol
            let bullet = "• "
            
            // Check if bullet already exists at the start of the paragraph
            // Using String's range-based methods instead of subscript
            let nsText = text as NSString
            let paraStart = min(paragraphRange.location, nsText.length)
            let checkEndIdx = min(paraStart + 2, nsText.length)
            
            if checkEndIdx > paraStart {
                let paragraphPrefix = nsText.substring(with: NSRange(location: paraStart, length: checkEndIdx - paraStart))
                if !paragraphPrefix.hasPrefix(bullet) {
                    let bulletText = NSAttributedString(string: bullet)
                    mutableAttributedText.insert(bulletText, at: paragraphRange.location)
                }
            }
            
        case .numberedList:
            // Get paragraph range
            let text = mutableAttributedText.string
            let paragraphRange = getParagraphRange(for: selectedTextRange, in: text)
            
            // Apply numbered list formatting
            let paragraphStyle = mutableAttributedText.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            
            paragraphStyle.headIndent = 20.0
            paragraphStyle.firstLineHeadIndent = 0.0
            paragraphStyle.tailIndent = 0.0
            
            mutableAttributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
            
            // Apply number
            let number = "1. "
            
            // Check for numbering properly using NSString
            let nsText = text as NSString
            let paraStart = min(paragraphRange.location, nsText.length)
            let checkEndIdx = min(paraStart + 3, nsText.length)
            
            if checkEndIdx > paraStart {
                let prefixRange = NSRange(location: paraStart, length: checkEndIdx - paraStart)
                let paraPrefix = nsText.substring(with: prefixRange)
                
                // Check if it has a number prefix like "1. "
                let regex = try? NSRegularExpression(pattern: "^\\d+\\.\\s", options: [])
                let matches = regex?.matches(in: paraPrefix, options: [], range: NSRange(location: 0, length: paraPrefix.count))
                
                if matches == nil || matches?.isEmpty == true {
                    let numberText = NSAttributedString(string: number)
                    mutableAttributedText.insert(numberText, at: paragraphRange.location)
                }
            }
            
        case .increaseIndent:
            // Get paragraph range
            let paragraphRange = getParagraphRange(for: selectedTextRange, in: mutableAttributedText.string)
            
            // Get or create paragraph style
            let paragraphStyle = mutableAttributedText.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            
            // Increase indentation
            paragraphStyle.headIndent += 20.0
            paragraphStyle.firstLineHeadIndent += 20.0
            
            mutableAttributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
            
        case .decreaseIndent:
            // Get paragraph range
            let paragraphRange = getParagraphRange(for: selectedTextRange, in: mutableAttributedText.string)
            
            // Get or create paragraph style
            let paragraphStyle = mutableAttributedText.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            
            // Decrease indentation (but not below 0)
            paragraphStyle.headIndent = max(0, paragraphStyle.headIndent - 20.0)
            paragraphStyle.firstLineHeadIndent = max(0, paragraphStyle.firstLineHeadIndent - 20.0)
            
            mutableAttributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
            
        case .insertLink(let url, let title):
            // Create a link attribute
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .link: url,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
            
            // Apply link attributes to the selected text
            mutableAttributedText.addAttributes(linkAttributes, range: selectedTextRange)
        }
        
        // Update the text view
        textView.attributedText = mutableAttributedText
        
        // Use DispatchQueue.main.async to avoid updating state during view updates
        DispatchQueue.main.async {
            onTextChange(mutableAttributedText)
        }
    }
    
    // Helper to get the full paragraph range containing the selection
    private func getParagraphRange(for range: NSRange, in text: String) -> NSRange {
        let nsString = text as NSString
        return nsString.paragraphRange(for: range)
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

import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: NSAttributedString
    var placeholder: String
    var onTextChange: (NSAttributedString) -> Void
    @Binding var activeFormatting: Set<TextFormatting> // Use the shared TextFormatting enum
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .yes
        textView.smartDashesType = .yes
        textView.smartQuotesType = .yes
        textView.smartInsertDeleteType = .yes
        
        // Store textView in coordinator for later use
        context.coordinator.textView = textView
        
        // Set initial text
        if text.length > 0 {
            textView.attributedText = text
        } else {
            textView.text = placeholder
            textView.textColor = .placeholderText
        }
        
        // Setup touch bar without showing it
        setupToolbar(textView, context: context)
        
        return textView
    }
    
    private func setupToolbar(_ textView: UITextView, context: Context) {
        // Create toolbar items but don't attach them to the textView
        // This keeps the functionality available for the floating toolbar
        
        // We're not setting textView.inputAccessoryView = toolbar anymore
        // because we're using our own floating formatting toolbar in the SwiftUI layer
        
        // Register for formatting notifications
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleFormatting(_:)),
            name: Notification.Name("ApplyRichTextFormatting"),
            object: nil
        )
    }
    
    private func createToolbarButton(icon: String, selector: Selector, coordinator: Coordinator) -> UIBarButtonItem {
        let button = UIBarButtonItem(image: UIImage(systemName: icon), style: .plain, target: coordinator, action: selector)
        return button
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update if the text has changed from external source
        if uiView.attributedText != text && text.length > 0 {
            uiView.attributedText = text
            uiView.textColor = .label
        }
        
        // Also update placeholder if needed
        if text.length == 0 && uiView.text != placeholder && !context.coordinator.isEditing {
            uiView.text = placeholder
            uiView.textColor = .placeholderText
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIColorPickerViewControllerDelegate {
        var parent: RichTextEditor
        var isEditing = false
        weak var textView: UITextView?
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
            super.init()
            
            // Listen for formatting notifications from SwiftUI
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFormatting(_:)),
                name: Notification.Name("ApplyRichTextFormatting"),
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        // MARK: - UITextViewDelegate
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
            
            // Clear placeholder if needed
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
            
            // If the text is empty, show placeholder
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
            
            // Update the parent's text
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
        }
        
        // Detect selection changes to update active formatting
        func textViewDidChangeSelection(_ textView: UITextView) {
            updateActiveFormatting(for: textView)
        }
        
        // Helper function to update active formatting based on current selection
        private func updateActiveFormatting(for textView: UITextView) {
            // Clear previous formatting
            parent.activeFormatting.removeAll()
            
            let selectedRange = textView.selectedRange
            
            // If there's no selection, we can't determine formatting
            guard selectedRange.length > 0, let attributedText = textView.attributedText else { return }
            
            // Check for bold
            let fontAttribute = attributedText.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
            if fontAttribute != nil {
                let traits = fontAttribute!.fontDescriptor.symbolicTraits
                if traits.contains(.traitBold) {
                    parent.activeFormatting.insert(.bold)
                }
            }
            
            // Check for italic
            let fontAttributeItalic = attributedText.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
            if fontAttributeItalic != nil {
                let traits = fontAttributeItalic!.fontDescriptor.symbolicTraits
                if traits.contains(.traitItalic) {
                    parent.activeFormatting.insert(.italic)
                }
            }
            
            // Check for underline
            let underlineStyle = attributedText.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) as? Int
            if underlineStyle != nil {
                if underlineStyle! != 0 {
                    parent.activeFormatting.insert(.underline)
                }
            }
            
            // Check for text color
            let textColor = attributedText.attribute(.foregroundColor, at: selectedRange.location, effectiveRange: nil) as? UIColor
            if textColor != nil {
                parent.activeFormatting.insert(.textColor(textColor!))
            }
            
            // Check for links
            let url = attributedText.attribute(.link, at: selectedRange.location, effectiveRange: nil) as? URL
            let linkText = attributedText.attributedSubstring(from: selectedRange).string as String?
            if url != nil {
                parent.activeFormatting.insert(.insertLink(url!, linkText ?? ""))
            }
            
            // Get paragraph style to check alignment and lists
            let paragraphStyle = attributedText.attribute(.paragraphStyle, at: selectedRange.location, effectiveRange: nil) as? NSParagraphStyle
            if paragraphStyle != nil {
                // Check alignment
                switch paragraphStyle!.alignment {
                case .left:
                    parent.activeFormatting.insert(.alignLeft)
                case .center:
                    parent.activeFormatting.insert(.alignCenter)
                case .right:
                    parent.activeFormatting.insert(.alignRight)
                default:
                    break
                }
                
                // Check for lists
                // This would require custom paragraph style with list attributes
                // Implementation depends on how bullet/numbered lists are implemented
            }
        }
        
        @objc func makeBold(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let selectedRange = textView.selectedRange
            
            // Get the font at the selection
            let currentFont = attrString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
            if currentFont != nil {
                var traits = currentFont!.fontDescriptor.symbolicTraits
                
                if traits.contains(.traitBold) {
                    // Remove bold
                    traits.remove(.traitBold)
                } else {
                    // Add bold
                    traits.insert(.traitBold)
                }
                
                // Create new font with/without bold
                if let descriptor = currentFont!.fontDescriptor.withSymbolicTraits(traits) {
                    let newFont = UIFont(descriptor: descriptor, size: currentFont!.pointSize)
                    attrString.addAttribute(.font, value: newFont, range: selectedRange)
                }
            } else {
                // No font attribute, add default bold font
                let boldFont = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
                attrString.addAttribute(.font, value: boldFont, range: selectedRange)
            }
            
            textView.attributedText = attrString
            
            // Ensure selection remains
            textView.selectedRange = selectedRange
            
            // Update parent text
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
            
            // Update active formatting
            let updatedFont = attrString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
            if updatedFont != nil {
                let updatedTraits = updatedFont!.fontDescriptor.symbolicTraits
                if updatedTraits.contains(UIFontDescriptor.SymbolicTraits.traitBold) {
                    parent.activeFormatting.insert(.bold)
                } else {
                    parent.activeFormatting.remove(.bold)
                }
                
                // Show feedback
                showFormatFeedback(message: updatedTraits.contains(UIFontDescriptor.SymbolicTraits.traitBold) ? "Bold" : "Normal")
            }
        }
        
        @objc func makeItalic(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let selectedRange = textView.selectedRange
            
            // Get the font at the selection
            let currentFont = attrString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
            if currentFont != nil {
                var traits = currentFont!.fontDescriptor.symbolicTraits
                
                if traits.contains(.traitItalic) {
                    // Remove italic
                    traits.remove(.traitItalic)
                } else {
                    // Add italic
                    traits.insert(.traitItalic)
                }
                
                // Create new font with/without italic
                if let descriptor = currentFont!.fontDescriptor.withSymbolicTraits(traits) {
                    let newFont = UIFont(descriptor: descriptor, size: currentFont!.pointSize)
                    attrString.addAttribute(.font, value: newFont, range: selectedRange)
                }
            } else {
                // No font attribute, add default italic font
                let italicFont = UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
                attrString.addAttribute(.font, value: italicFont, range: selectedRange)
            }
            
            textView.attributedText = attrString
            
            // Ensure selection remains
            textView.selectedRange = selectedRange
            
            // Update parent text
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
            
            // Update active formatting
            let updatedFont = attrString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
            if updatedFont != nil {
                let updatedTraits = updatedFont!.fontDescriptor.symbolicTraits
                if updatedTraits.contains(UIFontDescriptor.SymbolicTraits.traitItalic) {
                    parent.activeFormatting.insert(.italic)
                } else {
                    parent.activeFormatting.remove(.italic)
                }
                
                // Show feedback
                showFormatFeedback(message: updatedTraits.contains(UIFontDescriptor.SymbolicTraits.traitItalic) ? "Italic" : "Normal")
            }
        }
        
        @objc func makeUnderline(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let selectedRange = textView.selectedRange
            
            // Get underline style at selection
            let currentStyle = attrString.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) as? Int
            if currentStyle != nil {
                let newUnderlineStyle = (currentStyle! == NSUnderlineStyle.single.rawValue) ? 0 : NSUnderlineStyle.single.rawValue
                
                attrString.addAttribute(.underlineStyle, value: newUnderlineStyle, range: selectedRange)
            }
            
            textView.attributedText = attrString
            
            // Ensure selection remains
            textView.selectedRange = selectedRange
            
            // Update parent text
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
            
            // Update active formatting
            let updatedStyle = attrString.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) as? Int
            if updatedStyle != nil {
                if updatedStyle! != 0 {
                    parent.activeFormatting.insert(.underline)
                } else {
                    parent.activeFormatting.remove(.underline)
                }
                
                // Show feedback
                showFormatFeedback(message: updatedStyle! != 0 ? "Underlined" : "Normal")
            }
        }
        
        @objc func showColorPicker(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0,
                  let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let viewController = windowScene.windows.first?.rootViewController else { return }
            
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = self
            colorPicker.selectedColor = .label // Default to system text color
            
            // If there's already a color, use that
            let selectedColor = textView.attributedText.attribute(.foregroundColor, at: textView.selectedRange.location, effectiveRange: nil) as? UIColor
            if selectedColor != nil {
                colorPicker.selectedColor = selectedColor!
            }
            
            viewController.present(colorPicker, animated: true, completion: nil)
        }
        
        // UIColorPickerViewControllerDelegate
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            applyTextColor(viewController.selectedColor)
        }
        
        func applyTextColor(_ color: UIColor) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let selectedRange = textView.selectedRange
            
            attrString.addAttribute(.foregroundColor, value: color, range: selectedRange)
            
            textView.attributedText = attrString
            
            // Ensure selection remains
            textView.selectedRange = selectedRange
            
            // Update parent text
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
            
            // Update active formatting
            parent.activeFormatting.insert(.textColor(color))
            
            // Show feedback
            showFormatFeedback(message: "Color Applied")
        }
        
        @objc func insertLink(_ sender: Any) {
            guard let textView = self.textView,
                  textView.selectedRange.length > 0 else { return }
            
            // Create alert controller for link input
            let alertController = UIAlertController(title: "Add Link", message: nil, preferredStyle: .alert)
            
            // Add text fields for URL
            alertController.addTextField { textField in
                textField.placeholder = "URL (e.g., https://example.com)"
                textField.keyboardType = .URL
                textField.autocapitalizationType = .none
                
                // If a link is already applied, show it
                let existingURL = textView.attributedText.attribute(.link, at: textView.selectedRange.location, effectiveRange: nil) as? URL
                if existingURL != nil {
                    textField.text = existingURL!.absoluteString
                }
            }
            
            // Add actions
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
                guard let urlString = alertController.textFields?.first?.text,
                      let url = URL(string: urlString) else { return }
                
                // Get the selected text as the link text
                let linkText = textView.attributedText.attributedSubstring(from: textView.selectedRange).string
                
                // Apply the link
                self?.applyLink(url, text: linkText)
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(addAction)
            
            // Present alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let viewController = windowScene.windows.first?.rootViewController {
                viewController.present(alertController, animated: true, completion: nil)
            }
        }
        
        func applyLink(_ url: URL, text linkText: String?) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let selectedRange = textView.selectedRange
            
            // Add link attribute
            attrString.addAttribute(.link, value: url, range: selectedRange)
            
            // Add blue color to make it look like a link
            attrString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: selectedRange)
            
            textView.attributedText = attrString
            
            // Ensure selection remains
            textView.selectedRange = selectedRange
            
            // Update parent text
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
            
            // Update active formatting
            parent.activeFormatting.insert(.insertLink(url, linkText ?? ""))
            
            // Show feedback
            showFormatFeedback(message: "Link Added")
        }
        
        @objc func doneEditing() {
            self.textView?.resignFirstResponder()
        }
        
        private func showFormatFeedback(message: String) {
            guard let textView = self.textView else { return }
            
            // Create a toast-like feedback popup
            let feedbackLabel = UILabel()
            feedbackLabel.text = message
            feedbackLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
            feedbackLabel.textColor = UIColor.label
            feedbackLabel.textAlignment = .center
            feedbackLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            feedbackLabel.layer.cornerRadius = 8
            feedbackLabel.layer.masksToBounds = true
            feedbackLabel.alpha = 0
            feedbackLabel.sizeToFit()
            
            // Add padding
            feedbackLabel.frame.size.width += 32
            feedbackLabel.frame.size.height += 16
            
            // Position at bottom center
            feedbackLabel.center = CGPoint(
                x: textView.bounds.midX,
                y: textView.bounds.maxY - feedbackLabel.bounds.height - 20
            )
            
            // Add shadow for depth
            feedbackLabel.layer.shadowColor = UIColor.black.cgColor
            feedbackLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
            feedbackLabel.layer.shadowOpacity = 0.1
            feedbackLabel.layer.shadowRadius = 4
            
            textView.addSubview(feedbackLabel)
            
            // Animate in
            UIView.animate(withDuration: 0.3) {
                feedbackLabel.alpha = 1
            } completion: { _ in
                // Animate out after delay
                UIView.animate(withDuration: 0.3, delay: 1.0) {
                    feedbackLabel.alpha = 0
                } completion: { _ in
                    feedbackLabel.removeFromSuperview()
                }
            }
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        // MARK: - Formatting Handler
        
        @objc func handleFormatting(_ notification: Notification) {
            guard let formatting = notification.object as? TextFormatting else { return }
            
            switch formatting {
            case .bold:
                makeBold(self)
            case .italic:
                makeItalic(self)
            case .underline:
                makeUnderline(self)
            case .alignLeft:
                // Implement alignment formatting
                break
            case .alignCenter:
                // Implement alignment formatting
                break
            case .alignRight:
                // Implement alignment formatting
                break
            case .bulletList:
                // Implement bullet list formatting
                break
            case .numberedList:
                // Implement numbered list formatting
                break
            case .fontSize(_):
                // Implement font size formatting
                break
            case .textColor(let color):
                applyTextColor(color)
            case .insertLink(let url, let text):
                applyLink(url, text: text)
            }
        }
    }
}

// Extensions for helping with UI operations

// Safe extension to get the first responder
extension UIResponder {
    private static weak var _currentFirstResponder: UIResponder?
    
    static func currentFirst() -> UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }
    
    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
}

// Extension for getting current orientation
extension UIApplication {
    var currentOrientation: UIInterfaceOrientation? {
        if let windowScene = connectedScenes.first as? UIWindowScene {
            return windowScene.interfaceOrientation
        }
        return nil
    }
}

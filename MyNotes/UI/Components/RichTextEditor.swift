import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: NSAttributedString
    var placeholder: String
    var onTextChange: (NSAttributedString) -> Void
    
    // Add the TextFormatting enum that NoteEditorView expects
    enum TextFormatting {
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
    }
    
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
        
        // Set initial text
        if text.length > 0 {
            textView.attributedText = text
        } else {
            textView.text = placeholder
            textView.textColor = .placeholderText
        }
        
        // Create enhanced toolbar with icons instead of text buttons
        setupToolbar(textView, context: context)
        
        return textView
    }
    
    private func setupToolbar(_ textView: UITextView, context: Context) {
        let toolbar = UIToolbar()
        toolbar.tintColor = UIColor(named: "AppPrimaryColor") ?? .systemBlue
        toolbar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        // Add a subtle border to the toolbar
        toolbar.layer.borderColor = UIColor.separator.cgColor
        toolbar.layer.borderWidth = 0.5
        
        // Create formatting buttons with icons
        let boldButton = createToolbarButton(
            icon: "bold",
            selector: #selector(Coordinator.makeBold(_:)),
            coordinator: context.coordinator
        )
        
        let italicButton = createToolbarButton(
            icon: "italic",
            selector: #selector(Coordinator.makeItalic(_:)),
            coordinator: context.coordinator
        )
        
        let underlineButton = createToolbarButton(
            icon: "underline",
            selector: #selector(Coordinator.makeUnderline(_:)),
            coordinator: context.coordinator
        )
        
        let colorButton = createToolbarButton(
            icon: "paintbrush",
            selector: #selector(Coordinator.showColorPicker(_:)),
            coordinator: context.coordinator
        )
        
        let linkButton = createToolbarButton(
            icon: "link",
            selector: #selector(Coordinator.insertLink(_:)),
            coordinator: context.coordinator
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneEditing))
        doneButton.tintColor = UIColor(named: "AppPrimaryColor") ?? .systemBlue
        
        // Add separator between button groups
        let separator = UIBarButtonItem(image: UIImage(systemName: "circle.fill")?.withRenderingMode(.alwaysTemplate), style: .plain, target: nil, action: nil)
        separator.tintColor = UIColor.separator
        separator.width = 8
        
        // Arrange toolbar items
        toolbar.items = [boldButton, italicButton, underlineButton, separator, colorButton, linkButton, flexSpace, doneButton]
        textView.inputAccessoryView = toolbar
    }
    
    private func createToolbarButton(icon: String, selector: Selector, coordinator: Coordinator) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: coordinator,
            action: selector
        )
        
        // Add a subtle highlight effect
        button.tintColor = UIColor(named: "AppPrimaryColor") ?? .systemBlue
        
        return button
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update if the text has changed from external source
        if uiView.attributedText != text && text.length > 0 {
            uiView.attributedText = text
            uiView.textColor = .label
        }
        
        // Update placeholder state if needed
        if text.length == 0 && uiView.textColor != .placeholderText {
            uiView.text = placeholder
            uiView.textColor = .placeholderText
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIColorPickerViewControllerDelegate {
        var parent: RichTextEditor
        var isEditing = false
        weak var textView: UITextView?
        
        init(parent: RichTextEditor) {
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
            self.textView = textView
            
            // Clear placeholder if needed
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .label
            }
            
            isEditing = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // Restore placeholder if needed
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
            
            isEditing = false
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Don't update if it's just the placeholder
            if textView.textColor != .placeholderText {
                parent.text = textView.attributedText
                parent.onTextChange(textView.attributedText)
            }
        }
        
        // MARK: - Formatting Actions
        
        @objc func handleFormatting(_ notification: Notification) {
            guard let formatting = notification.object as? RichTextEditor.TextFormatting else { return }
            
            switch formatting {
            case .bold:
                makeBold(self)
            case .italic:
                makeItalic(self)
            case .underline:
                makeUnderline(self)
            case .textColor(let color):
                applyTextColor(color)
            case .insertLink(let url, let text):
                applyLink(url, text: text)
            default:
                break // Other formatting options not implemented yet
            }
        }
        
        @objc func makeBold(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            // Get current traits
            var traits: UIFontDescriptor.SymbolicTraits = .traitBold
            if let currentFont = textView.attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont {
                traits = currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) ? [] : .traitBold
            }
            
            // Apply font with updated traits
            if let currentFont = textView.attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont,
               let newFontDescriptor = currentFont.fontDescriptor.withSymbolicTraits(traits.union(currentFont.fontDescriptor.symbolicTraits)) {
                let newFont = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
                attrString.addAttribute(.font, value: newFont, range: range)
                
                textView.attributedText = attrString
                textView.selectedRange = range
                
                // Notify parent of change
                parent.text = textView.attributedText
                parent.onTextChange(textView.attributedText)
                
                // Show feedback
                showFormatFeedback(message: traits.contains(.traitBold) ? "Bold" : "Normal")
            }
        }
        
        @objc func makeItalic(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            // Get current traits
            var traits: UIFontDescriptor.SymbolicTraits = .traitItalic
            if let currentFont = textView.attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont {
                traits = currentFont.fontDescriptor.symbolicTraits.contains(.traitItalic) ? [] : .traitItalic
            }
            
            // Apply font with updated traits
            if let currentFont = textView.attributedText.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont,
               let newFontDescriptor = currentFont.fontDescriptor.withSymbolicTraits(traits.union(currentFont.fontDescriptor.symbolicTraits)) {
                let newFont = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
                attrString.addAttribute(.font, value: newFont, range: range)
                
                textView.attributedText = attrString
                textView.selectedRange = range
                
                // Notify parent of change
                parent.text = textView.attributedText
                parent.onTextChange(textView.attributedText)
                
                // Show feedback
                showFormatFeedback(message: traits.contains(.traitItalic) ? "Italic" : "Normal")
            }
        }
        
        @objc func makeUnderline(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            // Check if underline is already applied
            let currentUnderlineStyle = textView.attributedText.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int
            let newUnderlineStyle = (currentUnderlineStyle == NSUnderlineStyle.single.rawValue) ? 0 : NSUnderlineStyle.single.rawValue
            
            // Apply or remove underline
            attrString.addAttribute(.underlineStyle, value: newUnderlineStyle, range: range)
            
            textView.attributedText = attrString
            textView.selectedRange = range
            
            // Notify parent of change
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
            
            // Show feedback
            showFormatFeedback(message: newUnderlineStyle != 0 ? "Underlined" : "Normal")
        }
        
        @objc func showColorPicker(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            // Get the current color if any
            let currentColor = textView.attributedText.attribute(.foregroundColor, at: textView.selectedRange.location, effectiveRange: nil) as? UIColor ?? .label
            
            // Create and configure color picker
            let colorPicker = UIColorPickerViewController()
            colorPicker.selectedColor = currentColor
            colorPicker.delegate = self
            
            // Present color picker
            if let viewController = textView.findViewController() {
                viewController.present(colorPicker, animated: true)
            }
        }
        
        // MARK: - UIColorPickerViewControllerDelegate
        
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            applyTextColor(viewController.selectedColor)
        }
        
        func applyTextColor(_ color: UIColor) {
            guard let textView = self.textView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            // Apply color
            attrString.addAttribute(.foregroundColor, value: color, range: range)
            
            textView.attributedText = attrString
            textView.selectedRange = range
            
            // Notify parent of change
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
            
            // Show feedback
            showFormatFeedback(message: "Color Applied")
        }
        
        @objc func insertLink(_ sender: Any) {
            guard let textView = self.textView,
                  textView.selectedRange.length > 0 else { return }
            
            // Create alert controller for link input
            let alertController = UIAlertController(
                title: "Insert Link",
                message: "Enter the URL for the selected text",
                preferredStyle: .alert
            )
            
            // Add text field for URL
            alertController.addTextField { textField in
                textField.placeholder = "https://example.com"
                textField.keyboardType = .URL
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
            }
            
            // Add actions
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            let insertAction = UIAlertAction(title: "Insert", style: .default) { [weak self] _ in
                if let urlString = alertController.textFields?.first?.text,
                   let url = URL(string: urlString) {
                    self?.applyLink(url, text: nil)
                }
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(insertAction)
            
            // Present alert
            if let viewController = textView.findViewController() {
                viewController.present(alertController, animated: true)
            }
        }
        
        func applyLink(_ url: URL, text linkText: String?) {
            guard let textView = self.textView else { return }
            
            let range = textView.selectedRange
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            
            // If link text is provided, replace selected text
            if let linkText = linkText, !linkText.isEmpty {
                attrString.replaceCharacters(in: range, with: linkText)
                let newRange = NSRange(location: range.location, length: linkText.count)
                attrString.addAttribute(.link, value: url, range: newRange)
                textView.attributedText = attrString
                textView.selectedRange = NSRange(location: range.location + linkText.count, length: 0)
            } else {
                // Otherwise, just add link to selected text
                attrString.addAttribute(.link, value: url, range: range)
                textView.attributedText = attrString
                textView.selectedRange = NSRange(location: range.location + range.length, length: 0)
            }
            
            // Notify parent of change
            parent.text = textView.attributedText
            parent.onTextChange(textView.attributedText)
            
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
            feedbackLabel.textAlignment = .center
            feedbackLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            feedbackLabel.textColor = .white
            feedbackLabel.backgroundColor = UIColor.systemGray.withAlphaComponent(0.8)
            feedbackLabel.layer.cornerRadius = 8
            feedbackLabel.clipsToBounds = true
            feedbackLabel.alpha = 0
            
            // Add to view hierarchy
            if let superview = textView.superview {
                superview.addSubview(feedbackLabel)
                
                // Position at the bottom center
                feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    feedbackLabel.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                    feedbackLabel.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -20),
                    feedbackLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
                    feedbackLabel.heightAnchor.constraint(equalToConstant: 32)
                ])
                
                // Add padding
                feedbackLabel.layoutIfNeeded()
                feedbackLabel.bounds = feedbackLabel.bounds.insetBy(dx: -16, dy: 0)
                
                // Animate in and out
                UIView.animate(withDuration: 0.3, animations: {
                    feedbackLabel.alpha = 1
                }) { _ in
                    UIView.animate(withDuration: 0.3, delay: 0.8, options: [], animations: {
                        feedbackLabel.alpha = 0
                    }) { _ in
                        feedbackLabel.removeFromSuperview()
                    }
                }
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
        UIApplication.shared.sendAction(#selector(findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }
    
    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
}

// Extension to find the view controller from a view
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

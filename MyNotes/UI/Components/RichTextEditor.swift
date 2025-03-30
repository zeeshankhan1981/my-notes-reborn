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
        textView.backgroundColor = .clear
        
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
        toolbar.tintColor = UIColor(named: "AccentColor") ?? .systemBlue
        toolbar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
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
        return button
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if context.coordinator.isEditing {
            return
        }
        
        // Only update if text actually changed
        if text.string != textView.attributedText.string {
            textView.attributedText = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // Apply formatting to the text
    func applyFormatting(_ formatting: TextFormatting) {
        // This function will be called by NoteEditorView
        // We use a notification to send it to the active coordinator
        
        NotificationCenter.default.post(
            name: Notification.Name("ApplyRichTextFormatting"),
            object: formatting
        )
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIColorPickerViewControllerDelegate {
        var parent: RichTextEditor
        var isEditing = false
        weak var textView: UITextView?
        
        init(parent: RichTextEditor) {
            self.parent = parent
            super.init()
            
            // Listen for formatting notifications
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
        
        @objc func handleFormatting(_ notification: Notification) {
            guard let formatting = notification.object as? RichTextEditor.TextFormatting,
                  let textView = self.textView ?? UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else {
                return
            }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            switch formatting {
            case .bold:
                let attrs = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: textView.font?.pointSize ?? 16)]
                attrString.setAttributes(attrs, range: range)
                
            case .italic:
                let attrs = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: textView.font?.pointSize ?? 16)]
                attrString.setAttributes(attrs, range: range)
                
            case .underline:
                attrString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                
            case .textColor(let color):
                attrString.addAttribute(.foregroundColor, value: color, range: range)
                
            case .insertLink(let url, let title):
                attrString.addAttribute(.link, value: url, range: range)
                
            // Add cases for other formatting options as needed
            default:
                // Handle other formatting types if needed
                break
            }
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
        }
        
        // MARK: - Text View Delegate Methods
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            self.textView = textView
            isEditing = true
            
            // Clear placeholder if needed
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
            
            // Set placeholder if empty
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if textView.textColor != .placeholderText {
                parent.onTextChange(textView.attributedText)
            }
        }
        
        // MARK: - Formatting Actions
        
        @objc func makeBold(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrs = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: textView.font?.pointSize ?? 16)]
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.setAttributes(attrs, range: textView.selectedRange)
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
            
            // Display visual feedback
            showFormatFeedback(message: "Bold text applied")
        }
        
        @objc func makeItalic(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrs = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: textView.font?.pointSize ?? 16)]
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.setAttributes(attrs, range: textView.selectedRange)
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
            
            // Display visual feedback
            showFormatFeedback(message: "Italic text applied")
        }
        
        @objc func makeUnderline(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: textView.selectedRange)
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
            
            // Display visual feedback
            showFormatFeedback(message: "Underline applied")
        }
        
        @objc func showColorPicker(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            // Create and configure color picker
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = self
            colorPicker.supportsAlpha = false
            colorPicker.title = "Choose Text Color"
            
            // Present color picker
            if let viewController = textView.findViewController() {
                viewController.present(colorPicker, animated: true)
            }
        }
        
        // UIColorPickerViewControllerDelegate method
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            applyTextColor(viewController.selectedColor)
        }
        
        // Apply color from picker
        func applyTextColor(_ color: UIColor) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.addAttribute(.foregroundColor, value: color, range: textView.selectedRange)
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
            
            // Display visual feedback
            showFormatFeedback(message: "Color applied")
        }
        
        @objc func insertLink(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            // In a real implementation, we would show a dialog to input URL
            // For now, let's use a default URL as an example
            let url = URL(string: "https://example.com")!
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.addAttribute(.link, value: url, range: textView.selectedRange)
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
            
            // Display visual feedback
            showFormatFeedback(message: "Link inserted")
        }
        
        @objc func doneEditing() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        // MARK: - Helper Methods
        
        private func showFormatFeedback(message: String) {
            guard let textView = self.textView else { return }
            
            // Create a toast-like feedback popup
            let feedbackLabel = UILabel()
            feedbackLabel.text = message
            feedbackLabel.textAlignment = .center
            feedbackLabel.textColor = .white
            feedbackLabel.backgroundColor = UIColor(named: "AccentColor") ?? .systemBlue
            feedbackLabel.alpha = 0
            feedbackLabel.layer.cornerRadius = 10
            feedbackLabel.clipsToBounds = true
            feedbackLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            
            // Add to view hierarchy
            if let rootView = textView.window {
                rootView.addSubview(feedbackLabel)
                
                // Position and size
                feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    feedbackLabel.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
                    feedbackLabel.bottomAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                    feedbackLabel.heightAnchor.constraint(equalToConstant: 36),
                    feedbackLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
                    feedbackLabel.leadingAnchor.constraint(greaterThanOrEqualTo: rootView.leadingAnchor, constant: 40),
                    feedbackLabel.trailingAnchor.constraint(lessThanOrEqualTo: rootView.trailingAnchor, constant: -40)
                ])
                
                // Add padding
                feedbackLabel.layoutIfNeeded()
                feedbackLabel.frame = feedbackLabel.frame.insetBy(dx: -16, dy: 0)
                
                // Animate in
                UIView.animate(withDuration: 0.3, animations: {
                    feedbackLabel.alpha = 0.9
                }) { _ in
                    // Animate out after delay
                    UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
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
        UIApplication.shared.sendAction(#selector(UIResponder._storeFirstResponder), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }
    
    @objc private func _storeFirstResponder() {
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

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
        textView.backgroundColor = .clear
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
        
        return textView
    }
    
    private func setupToolbar(_ textView: UITextView, context: Context) {
        // We're not setting up any toolbar - keeping it minimal like Bear Notes
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
        
        // Update formatting UI if needed
        context.coordinator.updateFormattingControls()
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
        }
        
        // MARK: - UITextViewDelegate
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
            
            // Clear placeholder if needed
            if textView.text == parent.placeholder {
                textView.text = ""
                textView.textColor = .label
            }
            
            updateFormattingControls()
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
            
            // Re-add placeholder if needed
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Handle placeholder
            if textView.text.isEmpty {
                parent.text = NSAttributedString(string: "")
            } else {
                parent.text = textView.attributedText
            }
            
            // Call the change handler
            parent.onTextChange(parent.text)
            
            // Update formatting controls
            updateFormattingControls()
        }
        
        func updateFormattingControls() {
            guard let textView = textView,
                  let selectedRange = textView.selectedTextRange,
                  !selectedRange.isEmpty else {
                parent.activeFormatting = []
                return
            }
            
            // Here we determine which formatting options are active
            var activeFormats = Set<TextFormatting>()
            
            let range = textView.selectedRange
            
            // Check for bold
            if isBoldInRange(range, textView: textView) {
                activeFormats.insert(.bold)
            }
            
            // Check for italic
            if isItalicInRange(range, textView: textView) {
                activeFormats.insert(.italic)
            }
            
            // Check for underline
            if isUnderlinedInRange(range, textView: textView) {
                activeFormats.insert(.underline)
            }
            
            parent.activeFormatting = activeFormats
        }
        
        // MARK: - Formatting Detection
        
        func isBoldInRange(_ range: NSRange, textView: UITextView) -> Bool {
            let attributedText = textView.attributedText
            var result = true
            
            attributedText?.enumerateAttribute(.font, in: range, options: []) { (value, range, stop) in
                if let font = value as? UIFont {
                    if !font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                        result = false
                        stop.pointee = true
                    }
                } else {
                    result = false
                    stop.pointee = true
                }
            }
            
            return result && range.length > 0
        }
        
        func isItalicInRange(_ range: NSRange, textView: UITextView) -> Bool {
            let attributedText = textView.attributedText
            var result = true
            
            attributedText?.enumerateAttribute(.font, in: range, options: []) { (value, range, stop) in
                if let font = value as? UIFont {
                    if !font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                        result = false
                        stop.pointee = true
                    }
                } else {
                    result = false
                    stop.pointee = true
                }
            }
            
            return result && range.length > 0
        }
        
        func isUnderlinedInRange(_ range: NSRange, textView: UITextView) -> Bool {
            let attributedText = textView.attributedText
            var result = true
            
            attributedText?.enumerateAttribute(.underlineStyle, in: range, options: []) { (value, range, stop) in
                if (value as? NSNumber)?.intValue != NSUnderlineStyle.single.rawValue {
                    result = false
                    stop.pointee = true
                }
            }
            
            return result && range.length > 0
        }
        
        // MARK: - Formatting Actions
        
        @objc func makeBold(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            attrString.enumerateAttribute(.font, in: range, options: []) { (value, range, stop) in
                if let oldFont = value as? UIFont {
                    var newFont: UIFont
                    
                    // Toggle bold
                    if oldFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
                        // Remove bold
                        var traits = oldFont.fontDescriptor.symbolicTraits
                        traits.remove(.traitBold)
                        if let descriptor = oldFont.fontDescriptor.withSymbolicTraits(traits) {
                            newFont = UIFont(descriptor: descriptor, size: oldFont.pointSize)
                        } else {
                            newFont = UIFont.systemFont(ofSize: oldFont.pointSize)
                        }
                    } else {
                        // Add bold
                        var traits = oldFont.fontDescriptor.symbolicTraits
                        traits.insert(.traitBold)
                        if let descriptor = oldFont.fontDescriptor.withSymbolicTraits(traits) {
                            newFont = UIFont(descriptor: descriptor, size: oldFont.pointSize)
                        } else {
                            newFont = UIFont.boldSystemFont(ofSize: oldFont.pointSize)
                        }
                    }
                    
                    attrString.removeAttribute(.font, range: range)
                    attrString.addAttribute(.font, value: newFont, range: range)
                } else {
                    // No font attribute, add a bold one
                    let newFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
                    attrString.addAttribute(.font, value: newFont, range: range)
                }
            }
            
            // Update text
            textView.attributedText = attrString
            textView.selectedRange = range
            
            // Notify SwiftUI
            parent.text = attrString
            parent.onTextChange(attrString)
            
            // Update formatting UI
            updateFormattingControls()
        }
        
        @objc func makeItalic(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            attrString.enumerateAttribute(.font, in: range, options: []) { (value, range, stop) in
                if let oldFont = value as? UIFont {
                    var newFont: UIFont
                    
                    // Toggle italic
                    if oldFont.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                        // Remove italic
                        var traits = oldFont.fontDescriptor.symbolicTraits
                        traits.remove(.traitItalic)
                        if let descriptor = oldFont.fontDescriptor.withSymbolicTraits(traits) {
                            newFont = UIFont(descriptor: descriptor, size: oldFont.pointSize)
                        } else {
                            newFont = UIFont.systemFont(ofSize: oldFont.pointSize)
                        }
                    } else {
                        // Add italic
                        var traits = oldFont.fontDescriptor.symbolicTraits
                        traits.insert(.traitItalic)
                        if let descriptor = oldFont.fontDescriptor.withSymbolicTraits(traits) {
                            newFont = UIFont(descriptor: descriptor, size: oldFont.pointSize)
                        } else {
                            newFont = UIFont.italicSystemFont(ofSize: oldFont.pointSize)
                        }
                    }
                    
                    attrString.removeAttribute(.font, range: range)
                    attrString.addAttribute(.font, value: newFont, range: range)
                } else {
                    // No font attribute, add an italic one
                    let newFont = UIFont.italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
                    attrString.addAttribute(.font, value: newFont, range: range)
                }
            }
            
            // Update text
            textView.attributedText = attrString
            textView.selectedRange = range
            
            // Notify SwiftUI
            parent.text = attrString
            parent.onTextChange(attrString)
            
            // Update formatting UI
            updateFormattingControls()
        }
        
        @objc func makeUnderline(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            // Check if already underlined
            var isUnderlined = false
            attrString.enumerateAttribute(.underlineStyle, in: range, options: []) { (value, range, stop) in
                if (value as? NSNumber)?.intValue == NSUnderlineStyle.single.rawValue {
                    isUnderlined = true
                    stop.pointee = true
                }
            }
            
            // Toggle underline
            if isUnderlined {
                attrString.removeAttribute(.underlineStyle, range: range)
            } else {
                attrString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }
            
            // Update text
            textView.attributedText = attrString
            textView.selectedRange = range
            
            // Notify SwiftUI
            parent.text = attrString
            parent.onTextChange(attrString)
            
            // Update formatting UI
            updateFormattingControls()
        }
        
        @objc func makeHeading(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = textView.selectedRange
            
            // Use a larger, bold font for headings
            let headingFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize)
            attrString.removeAttribute(.font, range: range)
            attrString.addAttribute(.font, value: headingFont, range: range)
            
            // Update text
            textView.attributedText = attrString
            textView.selectedRange = range
            
            // Notify SwiftUI
            parent.text = attrString
            parent.onTextChange(attrString)
            
            // Update formatting UI
            updateFormattingControls()
        }
    }
}

// Extensions for helping with UI operations

// Safe extension to get the first responder
extension UIResponder {
    static var currentFirstResponder: UIResponder?
    
    static func currentFirst() -> UIResponder? {
        UIResponder.currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return UIResponder.currentFirstResponder
    }
    
    @objc func findFirstResponder(_ sender: Any) {
        UIResponder.currentFirstResponder = self
    }
}

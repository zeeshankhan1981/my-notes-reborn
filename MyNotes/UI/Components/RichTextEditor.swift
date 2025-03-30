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
        
        // Create and set up toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let boldButton = UIBarButtonItem(title: "Bold", style: .plain, target: context.coordinator, action: #selector(Coordinator.makeBold(_:)))
        let italicButton = UIBarButtonItem(title: "Italic", style: .plain, target: context.coordinator, action: #selector(Coordinator.makeItalic(_:)))
        let colorButton = UIBarButtonItem(title: "Blue", style: .plain, target: context.coordinator, action: #selector(Coordinator.makeBlue(_:)))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneEditing))
        
        toolbar.items = [boldButton, italicButton, colorButton, spacer, doneButton]
        textView.inputAccessoryView = toolbar
        
        return textView
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
    
    class Coordinator: NSObject, UITextViewDelegate {
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
        
        @objc func makeBold(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrs = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: textView.font?.pointSize ?? 16)]
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.setAttributes(attrs, range: textView.selectedRange)
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
        }
        
        @objc func makeItalic(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrs = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: textView.font?.pointSize ?? 16)]
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.setAttributes(attrs, range: textView.selectedRange)
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
        }
        
        @objc func makeBlue(_ sender: Any) {
            guard let textView = UIResponder.currentFirst() as? UITextView,
                  textView.selectedRange.length > 0 else { return }
            
            let attrs = [NSAttributedString.Key.foregroundColor: UIColor.blue]
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.setAttributes(attrs, range: textView.selectedRange)
            
            textView.attributedText = attrString
            parent.onTextChange(attrString)
        }
        
        @objc func doneEditing() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// Safe extension to get the first responder without using complex extensions
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

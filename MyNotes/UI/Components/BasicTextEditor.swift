import SwiftUI
import UIKit

struct BasicTextEditor: View {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    var placeholder: String
    @Binding var isEditing: Bool
    
    @State private var internalText: String
    @State private var showPlaceholder: Bool
    @Environment(\.colorScheme) var colorScheme
    
    init(text: Binding<String>, attributedText: Binding<NSAttributedString>, placeholder: String, isEditing: Binding<Bool>) {
        self._text = text
        self._attributedText = attributedText
        self.placeholder = placeholder
        self._isEditing = isEditing
        self._internalText = State(initialValue: text.wrappedValue)
        self._showPlaceholder = State(initialValue: text.wrappedValue.isEmpty)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if showPlaceholder {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(Color(.placeholderText))
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
            
            // Text editor with no background or border
            TextEditor(text: $internalText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onChange(of: internalText) { _, newValue in
                    text = newValue
                    
                    // Update attributed text
                    let attributedString = NSMutableAttributedString(string: newValue)
                    attributedString.addAttributes(
                        [.font: UIFont.preferredFont(forTextStyle: .body)],
                        range: NSRange(location: 0, length: newValue.count)
                    )
                    attributedText = attributedString
                    
                    // Show/hide placeholder
                    showPlaceholder = newValue.isEmpty
                }
                .onChange(of: text) { _, newValue in
                    if internalText != newValue {
                        internalText = newValue
                        showPlaceholder = newValue.isEmpty
                    }
                }
                .onAppear {
                    // Fix layout constraint issues by using more appropriate insets
                    UITextView.appearance().textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
                    
                    // Apply these modifications to help with the system input assistant view constraint conflicts
                    if let textField = UITextField.appearance(whenContainedInInstancesOf: [UIView.self]) as? UITextField {
                        textField.inputAccessoryView = nil
                    }
                }
                .onDisappear {
                    // Reset to default
                    UITextView.appearance().textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                }
        }
    }
}
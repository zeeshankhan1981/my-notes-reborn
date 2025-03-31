import SwiftUI

struct FormFieldView<Content: View>: View {
    var label: String
    var iconName: String
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingS) {
            // Header with icon and label
            sectionHeader
            
            // Content with standardized styling
            contentContainer
        }
    }
    
    private var sectionHeader: some View {
        Label(label, systemImage: iconName)
            .font(AppTheme.Typography.headline())
            .foregroundColor(AppTheme.Colors.textSecondary)
            .padding(.horizontal)
    }
    
    private var contentContainer: some View {
        content()
            .padding()
            .background(fieldBackground)
            .overlay(fieldBorder)
            .padding(.horizontal)
    }
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
            .fill(colorScheme == .dark ? 
                  AppTheme.Colors.cardSurface : 
                  AppTheme.Colors.secondaryBackground)
    }
    
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
            .stroke(AppTheme.Colors.divider, lineWidth: 1)
    }
}

// Standardized form section header
struct FormSectionHeader: View {
    var label: String
    var iconName: String
    
    var body: some View {
        Label(label, systemImage: iconName)
            .font(AppTheme.Typography.headline())
            .foregroundColor(AppTheme.Colors.textSecondary)
            .padding(.horizontal)
    }
}

// Preview
struct FormFieldView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FormFieldView(label: "Title", iconName: "textformat") {
                TextField("Note title", text: .constant("My Note"))
                    .font(AppTheme.Typography.title3())
            }
            
            FormFieldView(label: "Content", iconName: "text.justify") {
                Text("This is the content of my note")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(AppTheme.Colors.background)
        .previewLayout(.sizeThatFits)
    }
}

import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let iconName: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: iconName)
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

#Preview {
    VStack(alignment: .leading) {
        SectionHeaderView(title: "Pinned", iconName: "pin.fill")
        SectionHeaderView(title: "Notes", iconName: "note.text")
        SectionHeaderView(title: "Checklists", iconName: "checklist")
    }
    .padding()
    .previewLayout(.sizeThatFits)
}

import SwiftUI

/// A custom layout that arranges views in a flowing grid, similar to CSS flexbox
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let proposalWidth = proposal.width ?? 0
        var height: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if currentRowWidth + viewSize.width > proposalWidth {
                // Start new row
                height += currentRowHeight + spacing
                currentRowWidth = viewSize.width
                currentRowHeight = viewSize.height
            } else {
                // Add to current row
                currentRowWidth += viewSize.width + spacing
                currentRowHeight = max(currentRowHeight, viewSize.height)
            }
        }
        
        // Add last row
        height += currentRowHeight
        
        return CGSize(width: proposalWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if x + viewSize.width > bounds.maxX {
                // Start new row
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            
            x += viewSize.width + spacing
            rowHeight = max(rowHeight, viewSize.height)
        }
    }
}

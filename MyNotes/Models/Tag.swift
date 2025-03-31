import SwiftUI
import Foundation

struct Tag: Identifiable, Hashable {
    var id: UUID
    var name: String
    var color: Color
    
    init(id: UUID = UUID(), name: String, color: Color = .blue) {
        self.id = id
        self.name = name
        self.color = color
    }
    
    // Convert color to string for storage
    func colorString() -> String {
        switch color {
        case .red: return "red"
        case .orange: return "orange"
        case .yellow: return "yellow"
        case .green: return "green"
        case .blue: return "blue"
        case .purple: return "purple"
        case .pink: return "pink"
        case .gray: return "gray"
        default: return "blue"
        }
    }
    
    // Convert string to color for retrieval
    static func colorFromString(_ string: String?) -> Color {
        guard let string = string else { return .blue }
        
        switch string {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default: return .blue
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
}

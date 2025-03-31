import Foundation

struct ChecklistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isDone: Bool
}
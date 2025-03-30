import Foundation

struct ChecklistNote: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var folderID: UUID?
    var items: [ChecklistItem]
    var isPinned: Bool
    var date: Date
}
import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var folderID: UUID?
    var isPinned: Bool
    var date: Date
    var imageData: Data?
}
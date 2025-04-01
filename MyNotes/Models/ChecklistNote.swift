import Foundation

struct ChecklistNote: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var folderID: UUID?
    var items: [ChecklistItem]
    var isPinned: Bool
    var date: Date
    var tagIDs: [UUID] // IDs of associated tags
    var priority: Priority // Added priority property
    
    // For equatable conformance
    static func == (lhs: ChecklistNote, rhs: ChecklistNote) -> Bool {
        return lhs.id == rhs.id
    }
    
    // For coding keys
    enum CodingKeys: String, CodingKey {
        case id, title, folderID, items, isPinned, date, tagIDs, priority
    }
    
    init(id: UUID = UUID(), 
         title: String, 
         folderID: UUID? = nil, 
         items: [ChecklistItem] = [], 
         isPinned: Bool = false, 
         date: Date = Date(),
         tagIDs: [UUID] = [],
         priority: Priority = .none) {
        self.id = id
        self.title = title
        self.folderID = folderID
        self.items = items
        self.isPinned = isPinned
        self.date = date
        self.tagIDs = tagIDs
        self.priority = priority
    }
}
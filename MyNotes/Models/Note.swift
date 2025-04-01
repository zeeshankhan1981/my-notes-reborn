import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var folderID: UUID?
    var isPinned: Bool
    var date: Date
    var imageData: Data?
    var attributedContent: Data? // Stores NSAttributedString data
    var tagIDs: [UUID] // IDs of associated tags
    var priority: Priority // Added priority property
    
    // For equatable conformance
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
    
    // For encoding and decoding attributedContent
    enum CodingKeys: String, CodingKey {
        case id, title, content, folderID, isPinned, date, imageData, attributedContent, tagIDs, priority
    }
    
    init(id: UUID, title: String, content: String, folderID: UUID?, isPinned: Bool, date: Date, imageData: Data?, attributedContent: Data? = nil, tagIDs: [UUID] = [], priority: Priority = .none) {
        self.id = id
        self.title = title
        self.content = content
        self.folderID = folderID
        self.isPinned = isPinned
        self.date = date
        self.imageData = imageData
        self.attributedContent = attributedContent
        self.tagIDs = tagIDs
        self.priority = priority
    }
}
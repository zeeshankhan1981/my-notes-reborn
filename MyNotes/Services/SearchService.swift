import Foundation
import SwiftUI
import Combine

// MARK: - Searchable Protocol
protocol Searchable {
    var id: UUID { get }
    func matches(searchText: String) -> Bool
}

// MARK: - Search Result Item
struct SearchResultItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let type: SearchResultType
    let date: Date
    let iconName: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Search Result Type
enum SearchResultType {
    case note
    case checklist
    
    var displayName: String {
        switch self {
        case .note:
            return "Note"
        case .checklist:
            return "Checklist"
        }
    }
}

// MARK: - Search Service
class SearchService: ObservableObject {
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var searchResults: [SearchResultItem] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] searchText in
                self?.performSearch(searchText) ?? []
            }
            .assign(to: \.searchResults, on: self)
            .store(in: &cancellables)
    }
    
    func search(notes: [Note], checklists: [ChecklistNote]) {
        searchResults = performSearch(searchText, notes: notes, checklists: checklists)
    }
    
    private func performSearch(_ searchText: String, notes: [Note] = [], checklists: [ChecklistNote] = []) -> [SearchResultItem] {
        guard !searchText.isEmpty else { return [] }
        
        var results: [SearchResultItem] = []
        
        // Search through notes
        for note in notes {
            if note.title.localizedCaseInsensitiveContains(searchText) || 
               note.content.localizedCaseInsensitiveContains(searchText) {
                results.append(SearchResultItem(
                    id: note.id,
                    title: note.title,
                    subtitle: note.content.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines),
                    type: .note,
                    date: note.date,
                    iconName: "doc.text"
                ))
            }
        }
        
        // Search through checklists
        for checklist in checklists {
            let itemTexts = checklist.items.map { $0.text }.joined(separator: " ")
            if checklist.title.localizedCaseInsensitiveContains(searchText) ||
               itemTexts.localizedCaseInsensitiveContains(searchText) {
                let completedCount = checklist.items.filter { $0.isDone }.count
                let totalCount = checklist.items.count
                
                results.append(SearchResultItem(
                    id: checklist.id,
                    title: checklist.title,
                    subtitle: "\(completedCount)/\(totalCount) completed",
                    type: .checklist,
                    date: checklist.date,
                    iconName: "checklist"
                ))
            }
        }
        
        // Sort results by relevance and date
        return results.sorted { $0.date > $1.date }
    }
    
    func reset() {
        searchText = ""
        isSearching = false
        searchResults = []
    }
}

// MARK: - Extensions
extension Note: Searchable {
    func matches(searchText: String) -> Bool {
        title.localizedCaseInsensitiveContains(searchText) || 
        content.localizedCaseInsensitiveContains(searchText)
    }
}

extension ChecklistNote: Searchable {
    func matches(searchText: String) -> Bool {
        let itemTexts = items.map { $0.text }.joined(separator: " ")
        return title.localizedCaseInsensitiveContains(searchText) ||
               itemTexts.localizedCaseInsensitiveContains(searchText)
    }
}

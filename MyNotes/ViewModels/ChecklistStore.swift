import Foundation

class ChecklistStore: ObservableObject {
    @Published var checklists: [ChecklistNote] = []

    func addChecklist(title: String, folderID: UUID?) {
        let newChecklist = ChecklistNote(id: UUID(), title: title, folderID: folderID, items: [], isPinned: false, date: Date())
        checklists.append(newChecklist)
    }

    func updateChecklist(note: ChecklistNote) {
        if let index = checklists.firstIndex(of: note) {
            checklists[index] = note
        }
    }

    func delete(note: ChecklistNote) {
        checklists.removeAll { $0.id == note.id }
    }

    func togglePin(note: ChecklistNote) {
        if let index = checklists.firstIndex(of: note) {
            checklists[index].isPinned.toggle()
        }
    }
}
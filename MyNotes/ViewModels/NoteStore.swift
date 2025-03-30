import Foundation

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []

    func addNote(title: String, content: String, folderID: UUID?, imageData: Data?) {
        let newNote = Note(id: UUID(), title: title, content: content, folderID: folderID, isPinned: false, date: Date(), imageData: imageData)
        notes.append(newNote)
    }

    func update(note: Note, title: String, content: String, folderID: UUID?, imageData: Data?) {
        if let index = notes.firstIndex(of: note) {
            notes[index].title = title
            notes[index].content = content
            notes[index].folderID = folderID
            notes[index].imageData = imageData
            notes[index].date = Date()
        }
    }

    func delete(note: Note) {
        notes.removeAll { $0.id == note.id }
    }

    func togglePin(note: Note) {
        if let index = notes.firstIndex(of: note) {
            notes[index].isPinned.toggle()
        }
    }
}
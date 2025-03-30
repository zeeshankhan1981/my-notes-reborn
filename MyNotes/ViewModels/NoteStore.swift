import Foundation
import CoreData
import Combine

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadNotes()
        setupObservers()
    }
    
    private func setupObservers() {
        // Listen for context save notifications to reload data
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                self?.loadNotes()
            }
            .store(in: &cancellables)
    }
    
    func loadNotes() {
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDNote.date, ascending: false)]
        
        do {
            let cdNotes = try persistence.container.viewContext.fetch(request)
            self.notes = cdNotes.map { $0.toDomainModel() }
        } catch {
            print("Error fetching notes: \(error)")
        }
    }
    
    func addNote(title: String, content: String, folderID: UUID?, imageData: Data?) {
        let context = persistence.container.viewContext
        let newNote = Note(id: UUID(), title: title, content: content, folderID: folderID, isPinned: false, date: Date(), imageData: imageData)
        
        _ = CDNote.fromDomainModel(newNote, in: context)
        
        saveContext()
        loadNotes()
    }
    
    func update(note: Note, title: String, content: String, folderID: UUID?, imageData: Data?) {
        let context = persistence.container.viewContext
        var updatedNote = note
        updatedNote.title = title
        updatedNote.content = content
        updatedNote.folderID = folderID
        updatedNote.imageData = imageData
        updatedNote.date = Date()
        
        _ = CDNote.fromDomainModel(updatedNote, in: context)
        
        saveContext()
        loadNotes()
    }
    
    func delete(note: Note) {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
        
        do {
            if let noteToDelete = try context.fetch(request).first {
                context.delete(noteToDelete)
                saveContext()
            }
        } catch {
            print("Error deleting note: \(error)")
        }
        
        loadNotes()
    }
    
    func togglePin(note: Note) {
        let context = persistence.container.viewContext
        var updatedNote = note
        updatedNote.isPinned.toggle()
        
        _ = CDNote.fromDomainModel(updatedNote, in: context)
        
        saveContext()
        loadNotes()
    }
    
    private func saveContext() {
        persistence.save()
    }
}
import Foundation
import CoreData
import Combine

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("NoteStore: Initializing")
        loadNotes()
        setupObservers()
        
        // Add test data if store is empty
        ensureTestData()
    }
    
    private func setupObservers() {
        print("NoteStore: Setting up Core Data observers")
        // Listen for context save notifications to reload data
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                print("NoteStore: Core Data context saved, reloading notes")
                self?.loadNotes()
            }
            .store(in: &cancellables)
    }
    
    func loadNotes() {
        print("NoteStore: Loading notes from Core Data")
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDNote.date, ascending: false)]
        
        do {
            let cdNotes = try persistence.container.viewContext.fetch(request)
            self.notes = cdNotes.map { $0.toDomainModel() }
            print("NoteStore: Successfully loaded \(self.notes.count) notes")
        } catch {
            print("NoteStore: Error fetching notes: \(error)")
        }
    }
    
    // Ensure we have test data for debugging
    func ensureTestData() {
        if notes.isEmpty {
            print("NoteStore: Adding test data as notes array is empty")
            
            // Add a sample note
            addNote(
                title: "Welcome to MyNotes", 
                content: "This is a sample note to get you started. Try swiping this card left to delete it, or tap to edit.\n\nYou can create more notes by tapping the + button above.", 
                folderID: nil, 
                imageData: nil,
                attributedContent: nil,
                tagIDs: []
            )
            
            // Add a pinned note
            let pinnedNote = Note(
                id: UUID(),
                title: "Tips & Tricks",
                content: "• Swipe left on a note to delete it\n• Tap the edit button to select multiple notes\n• Pull down to search your notes\n• Long-press to quickly pin a note",
                folderID: nil,
                isPinned: true,
                date: Date(),
                imageData: nil,
                attributedContent: nil,
                tagIDs: []
            )
            saveNote(pinnedNote)
            
            print("NoteStore: Added test notes")
        } else {
            print("NoteStore: Found existing notes (\(notes.count)), not adding test data")
        }
    }
    
    func addNote(title: String, content: String, folderID: UUID?, imageData: Data?, attributedContent: Data? = nil, tagIDs: [UUID] = []) {
        print("NoteStore: Adding new note with title '\(title)'")
        
        let context = persistence.container.viewContext
        let newNote = Note(
            id: UUID(), 
            title: title, 
            content: content, 
            folderID: folderID, 
            isPinned: false, 
            date: Date(), 
            imageData: imageData,
            attributedContent: attributedContent,
            tagIDs: tagIDs
        )
        
        // Create Core Data entity from domain model
        _ = CDNote.fromDomainModel(newNote, in: context)
        
        // Save synchronously to ensure the note is persisted immediately
        saveContext()
        
        // Reload to reflect changes in the UI
        DispatchQueue.main.async {
            self.loadNotes()
        }
    }
    
    func update(note: Note, title: String, content: String, folderID: UUID?, imageData: Data?, attributedContent: Data? = nil, tagIDs: [UUID] = []) {
        print("NoteStore: Updating note '\(note.id)' with title '\(title)'")
        
        let context = persistence.container.viewContext
        var updatedNote = note
        updatedNote.title = title
        updatedNote.content = content
        updatedNote.folderID = folderID
        updatedNote.imageData = imageData
        updatedNote.date = Date()
        updatedNote.attributedContent = attributedContent
        updatedNote.tagIDs = tagIDs
        
        // Create/update Core Data entity from domain model
        _ = CDNote.fromDomainModel(updatedNote, in: context)
        
        // Save synchronously to ensure the note is persisted immediately
        saveContext()
        
        // Reload to reflect changes in the UI
        DispatchQueue.main.async {
            self.loadNotes()
        }
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
    
    func getNote(id: UUID) -> Note? {
        return notes.first { $0.id == id }
    }
    
    private func saveContext() {
        print("NoteStore: Saving Core Data context")
        
        // Ensure we're on the main thread when saving the view context
        if Thread.isMainThread {
            persistence.save()
        } else {
            DispatchQueue.main.sync {
                persistence.save()
            }
        }
    }
    
    private func saveNote(_ note: Note) {
        let context = persistence.container.viewContext
        _ = CDNote.fromDomainModel(note, in: context)
        saveContext()
    }
}

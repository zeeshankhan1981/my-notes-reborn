import Foundation
import CoreData
import Combine

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("NoteStore: Initializing")
        
        // Initialize with synchronous loading for init
        loadNotesSync()
        setupObservers()
        ensureTestData()
    }
    
    private func setupObservers() {
        print("NoteStore: Setting up Core Data observers")
        // Listen for context save notifications to reload data
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Debounce to avoid rapid reloads
            .sink { [weak self] _ in
                print("NoteStore: Core Data context saved, reloading notes")
                self?.loadNotesSync() // Use sync to avoid potential deadlock
            }
            .store(in: &cancellables)
    }
    
    // Synchronous loading method for initialization only
    private func loadNotesSync() {
        print("NoteStore: Loading notes synchronously")
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDNote.date, ascending: false)]
        
        do {
            let cdNotes = try persistence.container.viewContext.fetch(request)
            self.notes = cdNotes.map { $0.toDomainModel() }
            print("NoteStore: Successfully loaded \(self.notes.count) notes synchronously")
        } catch {
            print("NoteStore: Error fetching notes: \(error)")
        }
    }
    
    // Public loading method that updates the UI
    func loadNotes() {
        isLoading = true
        
        // Start a background task to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Create a fetch request
            let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDNote.date, ascending: false)]
            
            do {
                // Fetch on the main context
                let cdNotes = try self.persistence.container.viewContext.fetch(request)
                let mappedNotes = cdNotes.map { $0.toDomainModel() }
                
                // Update UI on the main thread
                DispatchQueue.main.async {
                    self.notes = mappedNotes
                    self.isLoading = false
                    print("NoteStore: Successfully loaded \(self.notes.count) notes")
                }
            } catch {
                DispatchQueue.main.async {
                    print("NoteStore: Error loading notes: \(error)")
                    self.isLoading = false
                }
            }
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
        
        // Save context
        persistence.save()
        
        // Reload to reflect changes in the UI
        loadNotesSync()
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
        
        // Save context
        persistence.save()
        
        // Reload to reflect changes in the UI
        loadNotesSync()
    }
    
    func delete(note: Note) {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
        
        do {
            if let noteToDelete = try context.fetch(request).first {
                context.delete(noteToDelete)
                persistence.save()
            }
        } catch {
            print("Error deleting note: \(error)")
        }
        
        loadNotesSync()
    }
    
    func togglePin(note: Note) {
        let context = persistence.container.viewContext
        var updatedNote = note
        updatedNote.isPinned.toggle()
        
        _ = CDNote.fromDomainModel(updatedNote, in: context)
        
        persistence.save()
        loadNotesSync()
    }
    
    func getNote(id: UUID) -> Note? {
        return notes.first { $0.id == id }
    }
    
    private func saveNote(_ note: Note) {
        let context = persistence.container.viewContext
        _ = CDNote.fromDomainModel(note, in: context)
        persistence.save()
    }
}

import Foundation
import CoreData
import Combine

final class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var loadingError: Error? = nil
    
    private let repository: any NoteRepository
    private let cache: NoteCache
    private let errorHandler: ErrorHandler
    private let operationRunner: CoreDataOperationRunner
    private let backgroundTaskManager: BackgroundTaskManager
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: any NoteRepository = CoreDataNoteRepository(),
         cache: NoteCache = ThreadSafeNoteCache(cache: UserDefaultsNoteCache()),
         errorHandler: ErrorHandler = AppErrorHandler.shared,
         operationRunner: CoreDataOperationRunner = CoreDataOperationRunner(),
         backgroundTaskManager: BackgroundTaskManager = BackgroundTaskManager.shared) {
        self.repository = repository
        self.cache = cache
        self.errorHandler = errorHandler
        self.operationRunner = operationRunner
        self.backgroundTaskManager = backgroundTaskManager
        
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
        isLoading = true
        loadingError = nil
        
        print("NoteStore: Loading notes from Core Data")
        let operation = FetchNotesOperation()
        
        operationRunner.runInBackground(
            operation: operation,
            description: "Loading all notes",
            category: "Notes"
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.loadingError = error
                    Task {
                        await self.errorHandler.handle(
                            error,
                            from: "NoteStore.loadNotes",
                            retryAction: { [weak self] in
                                self?.loadNotes()
                            }
                        )
                    }
                }
            },
            receiveValue: { [weak self] notes in
                guard let self = self else { return }
                self.notes = notes
                print("NoteStore: Successfully loaded \(self.notes.count) notes")
                
                // Cache all notes in the background
                Task {
                    for note in notes {
                        self.cache.cache(note)
                    }
                }
            }
        )
        .store(in: &cancellables)
    }
    
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
                tagIDs: [],
                priority: .none
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
                tagIDs: [],
                priority: .none
            )
            saveNote(pinnedNote)
            
            print("NoteStore: Added test notes")
        } else {
            print("NoteStore: Found existing notes (\(notes.count)), not adding test data")
        }
    }
    
    func addNote(title: String, content: String, folderID: UUID? = nil, imageData: Data? = nil, attributedContent: Data? = nil, tagIDs: [UUID] = [], priority: Priority = .none) {
        let newNote = Note(
            id: UUID(), 
            title: title, 
            content: content, 
            folderID: folderID, 
            isPinned: false, 
            date: Date(), 
            imageData: imageData,
            attributedContent: attributedContent,
            tagIDs: tagIDs,
            priority: priority
        )
        
        do {
            try repository.create(newNote)
            cache.cache(newNote)
            loadNotes()
        } catch {
            Task {
                await errorHandler.handle(
                    error,
                    from: "NoteStore.addNote",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        self.addNote(
                            title: title,
                            content: content,
                            folderID: folderID,
                            imageData: imageData,
                            attributedContent: attributedContent,
                            tagIDs: tagIDs,
                            priority: priority
                        )
                    }
                )
            }
        }
    }
    
    func saveNote(_ note: Note) {
        do {
            try repository.update(note)
            cache.cache(note)
            loadNotes()
        } catch {
            Task {
                await errorHandler.handle(
                    error,
                    from: "NoteStore.saveNote",
                    retryAction: { [weak self] in
                        self?.saveNote(note)
                    }
                )
            }
        }
    }
    
    func delete(note: Note) {
        do {
            try repository.delete(note)
            cache.remove(note.id)
            loadNotes()
        } catch {
            Task {
                await errorHandler.handle(
                    error,
                    from: "NoteStore.delete",
                    retryAction: { [weak self] in
                        self?.delete(note: note)
                    }
                )
            }
        }
    }
    
    func batchDeleteNotes(_ notes: [Note]) -> Void {
        // Use background task for better performance with large deletions
        let operation = BatchDeleteNotesOperation(noteIDs: notes.map { $0.id })
        
        backgroundTaskManager.submitTask(
            name: "Delete Notes",
            description: "Deleting \(notes.count) notes",
            category: "Notes"
        ) { [weak self] in
            guard let self = self else { return }
            
            do {
                let count = try self.operationRunner.runInForeground(operation: operation)
                print("NoteStore: Successfully deleted \(count) notes")
                
                // Clean up cache
                for note in notes {
                    self.cache.remove(note.id)
                }
                
                // Reload notes
                DispatchQueue.main.async {
                    self.loadNotes()
                }
            } catch {
                Task {
                    await self.errorHandler.handle(
                        error,
                        from: "NoteStore.batchDeleteNotes",
                        retryAction: { [weak self] in
                            guard let self = self else { return }
                            self.batchDeleteNotes(notes)
                        }
                    )
                }
                throw error
            }
        }
    }
    
    func importNotes(_ notes: [Note]) -> Void {
        let operation = ImportNotesOperation(notes: notes)
        
        backgroundTaskManager.submitTask(
            name: "Import Notes",
            description: "Importing \(notes.count) notes",
            category: "Notes"
        ) { [weak self] in
            guard let self = self else { return }
            
            do {
                let count = try self.operationRunner.runInForeground(operation: operation)
                print("NoteStore: Successfully imported \(count) notes")
                
                // Cache imported notes
                for note in notes {
                    self.cache.cache(note)
                }
                
                // Reload notes
                DispatchQueue.main.async {
                    self.loadNotes()
                }
            } catch {
                Task {
                    await self.errorHandler.handle(
                        error,
                        from: "NoteStore.importNotes",
                        retryAction: { [weak self] in
                            guard let self = self else { return }
                            self.importNotes(notes)
                        }
                    )
                }
                throw error
            }
        }
    }
    
    func createBackup() -> Void {
        backgroundTaskManager.submitTask(
            name: "Create Backup",
            description: "Creating backup of all notes",
            category: "Backup"
        ) { [weak self] in
            guard let self = self else { return }
            
            do {
                let backupService = FileSystemBackupService()
                let backupURL = try await backupService.createBackup()
                print("NoteStore: Backup created at \(backupURL.path)")
            } catch {
                Task {
                    await self.errorHandler.handle(
                        error,
                        from: "NoteStore.createBackup",
                        retryAction: { [weak self] in
                            self?.createBackup()
                        }
                    )
                }
                throw error
            }
        }
    }
    
    func restoreFromBackup(at url: URL) -> Void {
        backgroundTaskManager.submitTask(
            name: "Restore Backup",
            description: "Restoring from backup",
            category: "Backup"
        ) { [weak self] in
            guard let self = self else { return }
            
            do {
                let backupService = FileSystemBackupService()
                try await backupService.restoreFromBackup(at: url)
                
                // Clear cache after restore
                self.cache.clear()
                
                // Reload notes
                DispatchQueue.main.async {
                    self.loadNotes()
                }
            } catch {
                Task {
                    await self.errorHandler.handle(
                        error,
                        from: "NoteStore.restoreFromBackup",
                        retryAction: { [weak self] in
                            guard let self = self else { return }
                            self.restoreFromBackup(at: url)
                        }
                    )
                }
                throw error
            }
        }
    }
    
    func getNote(id: UUID) -> Note? {
        // Try to get from cache first
        if let cachedNote = cache.get(id) {
            return cachedNote
        }
        
        // If not in cache, fetch from repository
        do {
            let notes = try repository.fetch(byIDs: [id])
            if let note = notes.first {
                cache.cache(note)
                return note
            }
            return nil
        } catch {
            Task {
                await errorHandler.handle(
                    error,
                    from: "NoteStore.getNote",
                    retryAction: nil
                )
            }
            return nil
        }
    }
    
    // For backward compatibility with views
    func update(note: Note, title: String, content: String, folderID: UUID?, imageData: Data?, attributedContent: Data? = nil, tagIDs: [UUID] = [], priority: Priority = .none) {
        var updatedNote = note
        updatedNote.title = title
        updatedNote.content = content
        updatedNote.folderID = folderID
        updatedNote.imageData = imageData
        updatedNote.date = Date()
        updatedNote.attributedContent = attributedContent
        updatedNote.tagIDs = tagIDs
        updatedNote.priority = priority
        
        saveNote(updatedNote)
    }
    
    // For backward compatibility with views
    func togglePin(note: Note) {
        var updatedNote = note
        updatedNote.isPinned.toggle()
        saveNote(updatedNote)
    }
    
    // For backward compatibility with views
    func deleteMultiple(notes: [Note]) {
        batchDeleteNotes(notes)
    }
}

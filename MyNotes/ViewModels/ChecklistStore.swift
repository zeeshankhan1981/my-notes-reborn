import Foundation
import CoreData
import Combine

class ChecklistStore: ObservableObject {
    @Published var checklists: [ChecklistNote] = []
    @Published var isLoading: Bool = false
    
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("ChecklistStore: Initializing")
        
        // Initialize with synchronous loading for init
        loadChecklistsSync()
        setupObservers()
        ensureTestData()
    }
    
    private func setupObservers() {
        print("ChecklistStore: Setting up Core Data observers")
        // Listen for context save notifications to reload data
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Debounce to avoid rapid reloads
            .sink { [weak self] _ in
                print("ChecklistStore: Core Data context saved, reloading checklists")
                self?.loadChecklistsSync() // Use sync to avoid potential deadlock
            }
            .store(in: &cancellables)
    }
    
    // Synchronous loading method for initialization only
    private func loadChecklistsSync() {
        print("ChecklistStore: Loading checklists synchronously")
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChecklistNote.date, ascending: false)]
        
        do {
            let cdChecklists = try persistence.container.viewContext.fetch(request)
            self.checklists = cdChecklists.map { $0.toDomainModel() }
            print("ChecklistStore: Successfully loaded \(self.checklists.count) checklists synchronously")
        } catch {
            print("ChecklistStore: Error fetching checklists: \(error)")
        }
    }
    
    // Public loading method that updates the UI
    func loadChecklists() {
        isLoading = true
        
        // Start a background task to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Create a fetch request
            let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChecklistNote.date, ascending: false)]
            
            do {
                // Fetch on the main context
                let cdChecklists = try self.persistence.container.viewContext.fetch(request)
                let mappedChecklists = cdChecklists.map { $0.toDomainModel() }
                
                // Update UI on the main thread
                DispatchQueue.main.async {
                    self.checklists = mappedChecklists
                    self.isLoading = false
                    print("ChecklistStore: Successfully loaded \(self.checklists.count) checklists")
                }
            } catch {
                DispatchQueue.main.async {
                    print("ChecklistStore: Error loading checklists: \(error)")
                    self.isLoading = false
                }
            }
        }
    }

    // Ensure we have test data for debugging
    func ensureTestData() {
        if checklists.isEmpty {
            print("ChecklistStore: Adding test data as checklists array is empty")
            
            // Add a sample grocery checklist
            let groceryList = ChecklistNote(
                id: UUID(),
                title: "Grocery List",
                folderID: nil,
                items: [
                    ChecklistItem(id: UUID(), text: "Milk", isDone: false),
                    ChecklistItem(id: UUID(), text: "Eggs", isDone: true),
                    ChecklistItem(id: UUID(), text: "Bread", isDone: false)
                ],
                isPinned: true,
                date: Date(),
                tagIDs: []
            )
            saveChecklist(groceryList)
            
            // Add a to-do list
            let todoList = ChecklistNote(
                id: UUID(),
                title: "Today's Tasks",
                folderID: nil,
                items: [
                    ChecklistItem(id: UUID(), text: "Respond to emails", isDone: false),
                    ChecklistItem(id: UUID(), text: "Update calendar", isDone: false),
                    ChecklistItem(id: UUID(), text: "Schedule meeting", isDone: true)
                ],
                isPinned: false,
                date: Date().addingTimeInterval(-3600), // 1 hour ago
                tagIDs: []
            )
            saveChecklist(todoList)
            
            print("ChecklistStore: Added test checklists")
        } else {
            print("ChecklistStore: Found existing checklists (\(checklists.count)), not adding test data")
        }
    }

    func addChecklist(title: String, folderID: UUID?, tagIDs: [UUID] = []) {
        print("ChecklistStore: Adding new checklist with title '\(title)'")
        
        let context = persistence.container.viewContext
        let newChecklist = ChecklistNote(
            id: UUID(), 
            title: title, 
            folderID: folderID, 
            items: [], 
            isPinned: false, 
            date: Date(),
            tagIDs: tagIDs
        )
        
        // Create Core Data entity from domain model
        _ = CDChecklistNote.fromDomainModel(newChecklist, in: context)
        
        // Save context
        persistence.save()
        
        // Reload to reflect changes in the UI
        loadChecklistsSync()
    }
    
    private func saveChecklist(_ checklist: ChecklistNote) {
        print("ChecklistStore: Saving checklist '\(checklist.title)'")
        let context = persistence.container.viewContext
        _ = CDChecklistNote.fromDomainModel(checklist, in: context)
        persistence.save()
    }

    func updateChecklist(checklist: ChecklistNote) {
        print("ChecklistStore: Updating checklist '\(checklist.title)'")
        let context = persistence.container.viewContext
        _ = CDChecklistNote.fromDomainModel(checklist, in: context)
        
        // Save context
        persistence.save()
        
        // Reload to reflect changes in the UI
        loadChecklistsSync()
    }
    
    func updateChecklist(checklist: ChecklistNote, title: String, items: [ChecklistItem], folderID: UUID?, tagIDs: [UUID] = []) {
        print("ChecklistStore: Updating checklist '\(checklist.id)' with title '\(title)'")
        
        var updatedChecklist = checklist
        updatedChecklist.title = title
        updatedChecklist.items = items
        updatedChecklist.folderID = folderID
        updatedChecklist.date = Date()
        updatedChecklist.tagIDs = tagIDs
        
        updateChecklist(checklist: updatedChecklist)
    }

    func delete(checklist: ChecklistNote) {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", checklist.id as CVarArg)
        
        do {
            if let checklistToDelete = try context.fetch(request).first {
                context.delete(checklistToDelete)
                persistence.save()
            }
        } catch {
            print("Error deleting checklist: \(error)")
        }
        
        loadChecklistsSync()
    }

    func togglePin(checklist: ChecklistNote) {
        let context = persistence.container.viewContext
        var updatedChecklist = checklist
        updatedChecklist.isPinned.toggle()
        
        _ = CDChecklistNote.fromDomainModel(updatedChecklist, in: context)
        
        persistence.save()
        loadChecklistsSync()
    }
    
    func getChecklist(id: UUID) -> ChecklistNote? {
        return checklists.first { $0.id == id }
    }
}
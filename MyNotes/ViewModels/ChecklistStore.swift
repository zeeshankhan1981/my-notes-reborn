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
        
        // Load data asynchronously to avoid UI blocking
        Task {
            await loadChecklistsAsync()
            setupObservers()
            ensureTestData()
        }
    }
    
    private func setupObservers() {
        print("ChecklistStore: Setting up Core Data observers")
        // Listen for context save notifications to reload data
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Debounce to avoid rapid reloads
            .sink { [weak self] _ in
                print("ChecklistStore: Core Data context saved, reloading checklists")
                Task {
                    await self?.loadChecklistsAsync()
                }
            }
            .store(in: &cancellables)
    }
    
    // Asynchronous loading to avoid blocking the UI
    @MainActor
    func loadChecklistsAsync() async {
        print("ChecklistStore: Loading checklists from Core Data asynchronously")
        isLoading = true
        
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChecklistNote.date, ascending: false)]
        
        // Load on background thread
        let loadedChecklists = await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return [] }
            
            let cdChecklists = self.persistence.performOptimizedFetch(request)
            return cdChecklists.map { $0.toDomainModel() }
        }.value
        
        // Update on main thread
        self.checklists = loadedChecklists
        isLoading = false
        print("ChecklistStore: Successfully loaded \(self.checklists.count) checklists")
    }
    
    // The original sync loading method (kept for compatibility)
    func loadChecklists() {
        Task {
            await loadChecklistsAsync()
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
        
        // Save synchronously to ensure the checklist is persisted immediately
        saveContext()
        
        // Reload to reflect changes in the UI
        DispatchQueue.main.async {
            self.loadChecklists()
        }
    }
    
    private func saveChecklist(_ checklist: ChecklistNote) {
        print("ChecklistStore: Saving checklist '\(checklist.title)'")
        let context = persistence.container.viewContext
        _ = CDChecklistNote.fromDomainModel(checklist, in: context)
        saveContext()
    }

    func updateChecklist(checklist: ChecklistNote) {
        print("ChecklistStore: Updating checklist '\(checklist.title)'")
        let context = persistence.container.viewContext
        _ = CDChecklistNote.fromDomainModel(checklist, in: context)
        
        // Save synchronously to ensure the checklist is persisted immediately
        saveContext()
        
        // Reload to reflect changes in the UI
        DispatchQueue.main.async {
            self.loadChecklists()
        }
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
                saveContext()
            }
        } catch {
            print("Error deleting checklist: \(error)")
        }
        
        loadChecklists()
    }

    func togglePin(checklist: ChecklistNote) {
        let context = persistence.container.viewContext
        var updatedChecklist = checklist
        updatedChecklist.isPinned.toggle()
        
        _ = CDChecklistNote.fromDomainModel(updatedChecklist, in: context)
        
        saveContext()
        loadChecklists()
    }
    
    func getChecklist(id: UUID) -> ChecklistNote? {
        return checklists.first { $0.id == id }
    }

    private func saveContext() {
        print("ChecklistStore: Saving Core Data context")
        
        // Ensure we're on the main thread when saving the view context
        if Thread.isMainThread {
            persistence.save()
        } else {
            DispatchQueue.main.sync {
                persistence.save()
            }
        }
    }
}
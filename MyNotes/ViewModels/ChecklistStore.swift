import Foundation
import CoreData
import Combine

class ChecklistStore: ObservableObject {
    @Published var checklists: [ChecklistNote] = []
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("ChecklistStore: Initializing")
        loadChecklists()
        setupObservers()
        
        // Add test data if store is empty
        ensureTestData()
    }
    
    private func setupObservers() {
        print("ChecklistStore: Setting up Core Data observers")
        // Listen for context save notifications to reload data
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                print("ChecklistStore: Core Data context saved, reloading checklists")
                self?.loadChecklists()
            }
            .store(in: &cancellables)
    }
    
    func loadChecklists() {
        print("ChecklistStore: Loading checklists from Core Data")
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChecklistNote.date, ascending: false)]
        
        do {
            let cdChecklists = try persistence.container.viewContext.fetch(request)
            self.checklists = cdChecklists.map { $0.toDomainModel() }
            print("ChecklistStore: Successfully loaded \(self.checklists.count) checklists")
        } catch {
            print("ChecklistStore: Error fetching checklists: \(error)")
        }
    }

    // Ensure we have test data for debugging
    func ensureTestData() {
        if checklists.isEmpty {
            print("ChecklistStore: Adding test data as checklists array is empty")
            
            // Create a shopping list
            let shoppingList = ChecklistNote(
                id: UUID(),
                title: "Shopping List",
                folderID: nil,
                items: [
                    ChecklistItem(id: UUID(), text: "Milk", isDone: false),
                    ChecklistItem(id: UUID(), text: "Eggs", isDone: true),
                    ChecklistItem(id: UUID(), text: "Bread", isDone: false),
                    ChecklistItem(id: UUID(), text: "Apples", isDone: true),
                    ChecklistItem(id: UUID(), text: "Coffee", isDone: false)
                ],
                isPinned: true,
                date: Date()
            )
            saveChecklist(shoppingList)
            
            // Create a to-do list
            let todoList = ChecklistNote(
                id: UUID(),
                title: "Things To Do",
                folderID: nil,
                items: [
                    ChecklistItem(id: UUID(), text: "Respond to emails", isDone: false),
                    ChecklistItem(id: UUID(), text: "Update calendar", isDone: false),
                    ChecklistItem(id: UUID(), text: "Schedule meeting", isDone: true)
                ],
                isPinned: false,
                date: Date().addingTimeInterval(-3600) // 1 hour ago
            )
            saveChecklist(todoList)
            
            print("ChecklistStore: Added test checklists")
        } else {
            print("ChecklistStore: Found existing checklists (\(checklists.count)), not adding test data")
        }
    }

    func addChecklist(title: String, folderID: UUID?) {
        let context = persistence.container.viewContext
        let newChecklist = ChecklistNote(
            id: UUID(), 
            title: title, 
            folderID: folderID, 
            items: [], 
            isPinned: false, 
            date: Date()
        )
        
        _ = CDChecklistNote.fromDomainModel(newChecklist, in: context)
        
        saveContext()
        loadChecklists()
    }
    
    private func saveChecklist(_ checklist: ChecklistNote) {
        print("ChecklistStore: Saving checklist '\(checklist.title)'")
        let context = persistence.container.viewContext
        _ = CDChecklistNote.fromDomainModel(checklist, in: context)
        saveContext()
    }

    func updateChecklist(checklist: ChecklistNote) {
        let context = persistence.container.viewContext
        
        _ = CDChecklistNote.fromDomainModel(checklist, in: context)
        
        saveContext()
        loadChecklists()
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
    
    private func saveContext() {
        persistence.save()
    }
}
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
        print("ChecklistStore: Updating checklist '\(checklist.title)'")
        let context = persistence.container.viewContext
        _ = CDChecklistNote.fromDomainModel(checklist, in: context)
        saveContext()
        loadChecklists()
    }
    
    func updateChecklist(checklist: ChecklistNote, title: String, items: [ChecklistItem], folderID: UUID?, tagIDs: [UUID] = []) {
        var updatedChecklist = checklist
        updatedChecklist.title = title
        updatedChecklist.items = items
        updatedChecklist.folderID = folderID
        updatedChecklist.date = Date()
        updatedChecklist.tagIDs = tagIDs
        
        updateChecklist(checklist: updatedChecklist)
    }

    func delete(checklist: ChecklistNote) {
        print("ChecklistStore: Deleting checklist with ID: \(checklist.id)")
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", checklist.id as CVarArg)
        
        do {
            if let checklistToDelete = try context.fetch(request).first {
                // Use the enhanced safeDelete method from PersistenceController
                persistence.safeDelete(object: checklistToDelete)
                print("ChecklistStore: Successfully deleted checklist")
            } else {
                print("ChecklistStore: Checklist not found for deletion")
            }
        } catch {
            print("ChecklistStore: Error fetching checklist for deletion: \(error.localizedDescription)")
            
            // Attempt to recover by using batch delete as fallback
            let predicate = NSPredicate(format: "id == %@", checklist.id as CVarArg)
            persistence.batchDelete(entityType: CDChecklistNote.self, predicate: predicate)
        }
        
        loadChecklists()
    }
    
    func deleteMultiple(checklists: [ChecklistNote]) {
        print("ChecklistStore: Batch deleting \(checklists.count) checklists")
        
        if checklists.isEmpty { return }
        
        // Use batch delete for efficiency
        let checklistIDs = checklists.map { $0.id }
        let predicate = NSPredicate(format: "id IN %@", checklistIDs as [CVarArg])
        
        persistence.batchDelete(entityType: CDChecklistNote.self, predicate: predicate)
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
        persistence.save()
    }
}
import Foundation
import CoreData
import Combine

class ChecklistStore: ObservableObject {
    @Published var checklists: [ChecklistNote] = []
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadChecklists()
        setupObservers()
    }
    
    private func setupObservers() {
        // Listen for context save notifications to reload data
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                self?.loadChecklists()
            }
            .store(in: &cancellables)
    }
    
    func loadChecklists() {
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChecklistNote.date, ascending: false)]
        
        do {
            let cdChecklists = try persistence.container.viewContext.fetch(request)
            self.checklists = cdChecklists.map { $0.toDomainModel() }
        } catch {
            print("Error fetching checklists: \(error)")
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

    func updateChecklist(note: ChecklistNote) {
        let context = persistence.container.viewContext
        
        _ = CDChecklistNote.fromDomainModel(note, in: context)
        
        saveContext()
        loadChecklists()
    }

    func delete(note: ChecklistNote) {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
        
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

    func togglePin(note: ChecklistNote) {
        let context = persistence.container.viewContext
        var updatedChecklist = note
        updatedChecklist.isPinned.toggle()
        
        _ = CDChecklistNote.fromDomainModel(updatedChecklist, in: context)
        
        saveContext()
        loadChecklists()
    }
    
    private func saveContext() {
        persistence.save()
    }
}
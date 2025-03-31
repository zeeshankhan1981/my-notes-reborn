import SwiftUI
import CoreData
import Combine

class TagStore: ObservableObject {
    @Published var tags: [Tag] = []
    
    private let persistence: PersistenceController
    private var cancellables = Set<AnyCancellable>()
    
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        
        loadTags()
        
        // Set up notification to reload when Core Data changes
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange)
            .sink { [weak self] _ in
                self?.loadTags()
            }
            .store(in: &cancellables)
    }
    
    func loadTags() {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTag.name, ascending: true)]
        
        do {
            let cdTags = try context.fetch(request)
            self.tags = cdTags.map { cdTag in
                Tag(
                    id: cdTag.id!,
                    name: cdTag.name!,
                    color: Tag.colorFromString(cdTag.color)
                )
            }
        } catch {
            print("Error loading tags: \(error)")
        }
    }
    
    func addTag(name: String, color: Color) -> Tag {
        let context = persistence.container.viewContext
        let cdTag = CDTag(context: context)
        
        let newTag = Tag(name: name, color: color)
        cdTag.id = newTag.id
        cdTag.name = name
        cdTag.color = newTag.colorString()
        
        do {
            try context.save()
            loadTags()
            return newTag
        } catch {
            print("Error saving tag: \(error)")
            return newTag
        }
    }
    
    func update(tag: Tag, name: String, color: Color) {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        
        do {
            if let cdTag = try context.fetch(request).first {
                cdTag.name = name
                cdTag.color = tag.colorString()
                try context.save()
                loadTags()
            }
        } catch {
            print("Error updating tag: \(error)")
        }
    }
    
    func delete(tag: Tag) {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        
        do {
            if let cdTag = try context.fetch(request).first {
                context.delete(cdTag)
                try context.save()
                loadTags()
            }
        } catch {
            print("Error deleting tag: \(error)")
        }
    }
    
    func getTag(by id: UUID) -> Tag? {
        return tags.first { $0.id == id }
    }
    
    func getTagsByIDs(_ ids: [UUID]) -> [Tag] {
        return tags.filter { ids.contains($0.id) }
    }
    
    // Helper functions for common tag operations
    
    // Associate a tag with a note
    func addTagToNote(tag: Tag, note: CDNote) {
        let context = persistence.container.viewContext
        
        let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        
        do {
            if let cdTag = try context.fetch(tagRequest).first {
                note.addToTags(cdTag)
                try context.save()
            }
        } catch {
            print("Error adding tag to note: \(error)")
        }
    }
    
    // Remove a tag from a note
    func removeTagFromNote(tag: Tag, note: CDNote) {
        let context = persistence.container.viewContext
        
        let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        
        do {
            if let cdTag = try context.fetch(tagRequest).first {
                note.removeFromTags(cdTag)
                try context.save()
            }
        } catch {
            print("Error removing tag from note: \(error)")
        }
    }
    
    // Associate a tag with a checklist
    func addTagToChecklist(tag: Tag, checklist: CDChecklistNote) {
        let context = persistence.container.viewContext
        
        let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        
        do {
            if let cdTag = try context.fetch(tagRequest).first {
                checklist.addToTags(cdTag)
                try context.save()
            }
        } catch {
            print("Error adding tag to checklist: \(error)")
        }
    }
    
    // Remove a tag from a checklist
    func removeTagFromChecklist(tag: Tag, checklist: CDChecklistNote) {
        let context = persistence.container.viewContext
        
        let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        
        do {
            if let cdTag = try context.fetch(tagRequest).first {
                checklist.removeFromTags(cdTag)
                try context.save()
            }
        } catch {
            print("Error removing tag from checklist: \(error)")
        }
    }
    
    // Get all notes with a specific tag
    func getNotesWithTag(_ tag: Tag) -> [CDNote] {
        let context = persistence.container.viewContext
        
        let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        
        do {
            if let cdTag = try context.fetch(tagRequest).first,
               let notes = cdTag.notes as? Set<CDNote> {
                return Array(notes)
            }
        } catch {
            print("Error fetching notes with tag: \(error)")
        }
        
        return []
    }
    
    // Get all checklists with a specific tag
    func getChecklistsWithTag(_ tag: Tag) -> [CDChecklistNote] {
        let context = persistence.container.viewContext
        
        let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
        
        do {
            if let cdTag = try context.fetch(tagRequest).first,
               let checklists = cdTag.checklists as? Set<CDChecklistNote> {
                return Array(checklists)
            }
        } catch {
            print("Error fetching checklists with tag: \(error)")
        }
        
        return []
    }
}

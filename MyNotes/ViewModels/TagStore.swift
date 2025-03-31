import SwiftUI
import CoreData
import Combine

class TagStore: ObservableObject {
    @Published var tags: [Tag] = []
    
    private let persistence: PersistenceController
    private var cancellables = Set<AnyCancellable>()
    
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        
        loadTagsSync()
        
        // Set up notification to reload when Core Data changes
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange)
            .sink { [weak self] _ in
                self?.loadTags()
            }
            .store(in: &cancellables)
    }
    
    // Synchronous loading for initialization
    private func loadTagsSync() {
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
    
    // This needs to be a synchronous version, not async
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
    
    // MARK: - Tag Operations

    func addTag(name: String, color: Color) -> Tag {
        let context = persistence.container.viewContext
        
        let newTag = Tag(name: name, color: color)
        let newCDTag = CDTag(context: context)
        newCDTag.id = newTag.id
        newCDTag.name = name
        newCDTag.color = newTag.colorString()
        
        persistence.save()
        loadTags() // Reload tags after saving
        return newTag
    }
    
    func updateTag(id: UUID, name: String, color: Color) {
        let context = persistence.container.viewContext
        
        let request: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let tag = try context.fetch(request).first {
                tag.name = name
                tag.color = color == .blue ? "blue" : (color == .red ? "red" : "green")
                
                persistence.save()
                loadTags() // Reload tags after saving
            }
        } catch {
            print("Error updating tag: \(error)")
        }
    }
    
    func deleteTag(id: UUID) {
        let context = persistence.container.viewContext
        
        let request: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let tag = try context.fetch(request).first {
                context.delete(tag)
                persistence.save()
                loadTags() // Reload tags after saving
            }
        } catch {
            print("Error deleting tag: \(error)")
        }
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
                persistence.save()
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
                persistence.save()
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
                persistence.save()
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
                persistence.save()
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
    
    func getTag(by id: UUID) -> Tag? {
        return tags.first { $0.id == id }
    }
    
    func getTagsByIDs(_ ids: [UUID]) -> [Tag] {
        return tags.filter { ids.contains($0.id) }
    }
}

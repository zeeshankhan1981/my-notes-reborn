import Foundation
import CoreData

// MARK: - Note Extensions
extension CDNote {
    func toDomainModel() -> Note {
        // Extract tag IDs from relationships
        let tagIDs = (tags?.allObjects as? [CDTag])?.compactMap { $0.id } ?? []
        
        return Note(
            id: id ?? UUID(),
            title: title ?? "",
            content: content ?? "",
            folderID: folder?.id,
            isPinned: isPinned,
            date: date ?? Date(),
            imageData: imageData,
            attributedContent: attributedContent,
            tagIDs: tagIDs,
            priority: Priority(rawValue: Int(priorityValue)) ?? .none
        )
    }
    
    static func fromDomainModel(_ note: Note, in context: NSManagedObjectContext) -> CDNote {
        let cdNote: CDNote
        
        // Check if note already exists
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id.uuidString)
        request.fetchLimit = 1
        
        do {
            if let existingNote = try context.fetch(request).first {
                cdNote = existingNote
                print("Note: Found existing note with ID \(note.id)")
            } else {
                cdNote = CDNote(context: context)
                cdNote.id = note.id
                print("Note: Created new Core Data note with ID \(note.id)")
            }
            
            // Update properties
            cdNote.title = note.title
            cdNote.content = note.content
            cdNote.isPinned = note.isPinned
            cdNote.date = note.date
            cdNote.imageData = note.imageData
            cdNote.attributedContent = note.attributedContent
            cdNote.priorityValue = Int16(note.priority.rawValue)
            
            // Handle folder relationship if needed
            if let folderID = note.folderID {
                let folderRequest: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
                folderRequest.predicate = NSPredicate(format: "id == %@", folderID as CVarArg)
                if let folder = try context.fetch(folderRequest).first {
                    cdNote.folder = folder
                }
            } else {
                cdNote.folder = nil
            }
            
            // Handle tag relationships
            // First, remove any existing tag relationships
            if let existingTags = cdNote.tags {
                // Create an NSSet from the existing tags
                cdNote.removeFromTags(NSSet(array: existingTags.allObjects))
            }
            
            // Then add the current tags
            if !note.tagIDs.isEmpty {
                let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
                // Use IN predicate with UUID objects directly
                tagRequest.predicate = NSPredicate(format: "id IN %@", note.tagIDs as [Any])
                
                let tags = try? context.fetch(tagRequest)
                for tag in tags ?? [] {
                    cdNote.addToTags(tag)
                }
            }
            
            return cdNote
            
        } catch {
            print("Error in fromDomainModel for Note: \(error)")
            // Create a new instance as fallback
            let newNote = CDNote(context: context)
            newNote.id = note.id
            newNote.title = note.title
            newNote.content = note.content
            newNote.isPinned = note.isPinned
            newNote.date = note.date
            newNote.imageData = note.imageData
            newNote.attributedContent = note.attributedContent
            newNote.priorityValue = Int16(note.priority.rawValue)
            return newNote
        }
    }
}

// MARK: - ChecklistItem Extensions
extension CDChecklistItem {
    func toDomainModel() -> ChecklistItem {
        return ChecklistItem(
            id: id ?? UUID(),
            text: text ?? "",
            isDone: isDone
        )
    }
    
    static func fromDomainModel(_ item: ChecklistItem, in context: NSManagedObjectContext) -> CDChecklistItem {
        let cdItem: CDChecklistItem
        
        let request: NSFetchRequest<CDChecklistItem> = CDChecklistItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id.uuidString)
        
        if let existingItem = try? context.fetch(request).first {
            cdItem = existingItem
        } else {
            cdItem = CDChecklistItem(context: context)
            cdItem.id = item.id
        }
        
        cdItem.text = item.text
        cdItem.isDone = item.isDone
        
        return cdItem
    }
}

// MARK: - ChecklistNote Extensions
extension CDChecklistNote {
    func toDomainModel() -> ChecklistNote {
        let domainItems = (items?.allObjects as? [CDChecklistItem] ?? [])
            .map { $0.toDomainModel() }
        
        // Extract tag IDs from relationships
        let tagIDs = (tags?.allObjects as? [CDTag])?.compactMap { $0.id } ?? []
        
        return ChecklistNote(
            id: id ?? UUID(),
            title: title ?? "",
            folderID: folder?.id,
            items: domainItems,
            isPinned: isPinned,
            date: date ?? Date(),
            tagIDs: tagIDs,
            priority: Priority(rawValue: Int(priorityValue)) ?? .none
        )
    }
    
    static func fromDomainModel(_ checklist: ChecklistNote, in context: NSManagedObjectContext) -> CDChecklistNote {
        let cdChecklist: CDChecklistNote
        
        // Check if checklist already exists
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", checklist.id.uuidString)
        request.fetchLimit = 1
        
        do {
            if let existingChecklist = try context.fetch(request).first {
                cdChecklist = existingChecklist
                print("Checklist: Found existing checklist with ID \(checklist.id)")
                
                // Remove existing items to avoid duplicates
                if let existingItems = cdChecklist.items {
                    // First remove the relationship
                    cdChecklist.removeFromItems(NSSet(array: existingItems.allObjects))
                    
                    // Then delete each item from the context
                    for case let item as CDChecklistItem in existingItems.allObjects {
                        context.delete(item)
                    }
                }
            } else {
                cdChecklist = CDChecklistNote(context: context)
                cdChecklist.id = checklist.id
                print("Checklist: Created new Core Data checklist with ID \(checklist.id)")
            }
            
            // Update properties
            cdChecklist.title = checklist.title
            cdChecklist.date = checklist.date
            cdChecklist.isPinned = checklist.isPinned
            cdChecklist.priorityValue = Int16(checklist.priority.rawValue)
            
            // Handle folder relationship if needed
            if let folderID = checklist.folderID {
                let folderRequest: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
                folderRequest.predicate = NSPredicate(format: "id == %@", folderID as CVarArg)
                if let folder = try context.fetch(folderRequest).first {
                    cdChecklist.folder = folder
                }
            } else {
                cdChecklist.folder = nil
            }
            
            // Add items
            for item in checklist.items {
                let cdItem = CDChecklistItem.fromDomainModel(item, in: context)
                cdChecklist.addToItems(cdItem)
            }
            
            // Handle tag relationships
            // First, remove any existing tag relationships
            if let existingTags = cdChecklist.tags {
                // Create an NSSet from the existing tags
                cdChecklist.removeFromTags(NSSet(array: existingTags.allObjects))
            }
            
            // Then add the current tags
            if !checklist.tagIDs.isEmpty {
                let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
                // Use IN predicate with UUID objects directly
                tagRequest.predicate = NSPredicate(format: "id IN %@", checklist.tagIDs as [Any])
                
                let tags = try? context.fetch(tagRequest)
                for tag in tags ?? [] {
                    cdChecklist.addToTags(tag)
                }
            }
            
            return cdChecklist
            
        } catch {
            print("Error in fromDomainModel for ChecklistNote: \(error)")
            // Create a new instance as fallback
            let newChecklist = CDChecklistNote(context: context)
            newChecklist.id = checklist.id
            newChecklist.title = checklist.title
            newChecklist.date = checklist.date
            newChecklist.isPinned = checklist.isPinned
            newChecklist.priorityValue = Int16(checklist.priority.rawValue)
            
            // Add items
            for item in checklist.items {
                let cdItem = CDChecklistItem.fromDomainModel(item, in: context)
                newChecklist.addToItems(cdItem)
            }
            
            return newChecklist
        }
    }
}

// MARK: - Folder Extensions
extension CDFolder {
    func toDomainModel() -> Folder {
        return Folder(
            id: id ?? UUID(),
            name: name ?? ""
        )
    }
    
    static func fromDomainModel(_ folder: Folder, in context: NSManagedObjectContext) -> CDFolder {
        let cdFolder: CDFolder
        
        let request: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", folder.id.uuidString)
        
        if let existingFolder = try? context.fetch(request).first {
            cdFolder = existingFolder
        } else {
            cdFolder = CDFolder(context: context)
            cdFolder.id = folder.id
        }
        
        cdFolder.name = folder.name
        
        return cdFolder
    }
}

// MARK: - Tag Extensions
extension CDTag {
    func toDomainModel() -> Tag {
        return Tag(
            id: id ?? UUID(),
            name: name ?? "",
            color: Tag.colorFromString(color)
        )
    }
    
    static func fromDomainModel(_ tag: Tag, in context: NSManagedObjectContext) -> CDTag {
        let cdTag: CDTag
        
        let request: NSFetchRequest<CDTag> = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tag.id.uuidString)
        
        if let existingTag = try? context.fetch(request).first {
            cdTag = existingTag
        } else {
            cdTag = CDTag(context: context)
            cdTag.id = tag.id
        }
        
        cdTag.name = tag.name
        cdTag.color = tag.colorString()
        
        return cdTag
    }
}

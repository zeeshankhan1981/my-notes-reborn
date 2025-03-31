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
            tagIDs: tagIDs
        )
    }
    
    static func fromDomainModel(_ note: Note, in context: NSManagedObjectContext) -> CDNote {
        let cdNote: CDNote
        
        // Check if note already exists
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id.uuidString)
        request.fetchLimit = 1
        
        if let existingNote = try? context.fetch(request).first {
            cdNote = existingNote
        } else {
            cdNote = CDNote(context: context)
            cdNote.id = note.id
        }
        
        // Update properties
        cdNote.title = note.title
        cdNote.content = note.content
        cdNote.isPinned = note.isPinned
        cdNote.date = note.date
        cdNote.imageData = note.imageData
        cdNote.attributedContent = note.attributedContent
        
        // Handle folder relationship if needed
        if let folderID = note.folderID {
            let folderRequest: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
            folderRequest.predicate = NSPredicate(format: "id == %@", folderID.uuidString)
            if let folder = try? context.fetch(folderRequest).first {
                cdNote.folder = folder
            }
        } else {
            cdNote.folder = nil
        }
        
        // Handle tag relationships
        // First, remove any existing tag relationships
        if let existingTags = cdNote.tags {
            cdNote.removeFromTags(existingTags)
        }
        
        // Then add the current tags
        if !note.tagIDs.isEmpty {
            let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
            // Convert UUIDs to strings to avoid casting issues
            let tagIDStrings = note.tagIDs.map { $0.uuidString }
            tagRequest.predicate = NSPredicate(format: "id IN %@", tagIDStrings)
            
            if let tags = try? context.fetch(tagRequest) {
                for tag in tags {
                    cdNote.addToTags(tag)
                }
            }
        }
        
        return cdNote
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
            tagIDs: tagIDs
        )
    }
    
    static func fromDomainModel(_ checklist: ChecklistNote, in context: NSManagedObjectContext) -> CDChecklistNote {
        let cdChecklist: CDChecklistNote
        
        // Check if checklist already exists
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", checklist.id.uuidString)
        request.fetchLimit = 1
        
        if let existingChecklist = try? context.fetch(request).first {
            cdChecklist = existingChecklist
            
            // Remove existing items to avoid duplicates
            if let existingItems = cdChecklist.items {
                for case let item as CDChecklistItem in existingItems {
                    cdChecklist.removeFromItems(item)
                    context.delete(item)
                }
            }
        } else {
            cdChecklist = CDChecklistNote(context: context)
            cdChecklist.id = checklist.id
        }
        
        // Update properties
        cdChecklist.title = checklist.title
        cdChecklist.date = checklist.date
        cdChecklist.isPinned = checklist.isPinned
        
        // Handle folder relationship if needed
        if let folderID = checklist.folderID {
            let folderRequest: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
            folderRequest.predicate = NSPredicate(format: "id == %@", folderID.uuidString)
            if let folder = try? context.fetch(folderRequest).first {
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
            cdChecklist.removeFromTags(existingTags)
        }
        
        // Then add the current tags
        if !checklist.tagIDs.isEmpty {
            let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
            // Convert UUIDs to strings to avoid casting issues
            let tagIDStrings = checklist.tagIDs.map { $0.uuidString }
            tagRequest.predicate = NSPredicate(format: "id IN %@", tagIDStrings)
            
            if let tags = try? context.fetch(tagRequest) {
                for tag in tags {
                    cdChecklist.addToTags(tag)
                }
            }
        }
        
        return cdChecklist
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

import Foundation
import CoreData

// MARK: - Note Extensions
extension CDNote {
    func toDomainModel() -> Note {
        return Note(
            id: id ?? UUID(),
            title: title ?? "",
            content: content ?? "",
            folderID: folder?.id,
            isPinned: isPinned,
            date: date ?? Date(),
            imageData: imageData
        )
    }
    
    static func fromDomainModel(_ note: Note, in context: NSManagedObjectContext) -> CDNote {
        let cdNote: CDNote
        
        // Check if note already exists
        let request: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
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
        
        // Handle folder relationship if needed
        if let folderID = note.folderID {
            let folderRequest: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
            folderRequest.predicate = NSPredicate(format: "id == %@", folderID as CVarArg)
            if let folder = try? context.fetch(folderRequest).first {
                cdNote.folder = folder
            }
        } else {
            cdNote.folder = nil
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
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
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
        
        return ChecklistNote(
            id: id ?? UUID(),
            title: title ?? "",
            folderID: folder?.id,
            items: domainItems,
            isPinned: isPinned,
            date: date ?? Date()
        )
    }
    
    static func fromDomainModel(_ checklist: ChecklistNote, in context: NSManagedObjectContext) -> CDChecklistNote {
        let cdChecklist: CDChecklistNote
        
        let request: NSFetchRequest<CDChecklistNote> = CDChecklistNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", checklist.id as CVarArg)
        
        if let existingChecklist = try? context.fetch(request).first {
            cdChecklist = existingChecklist
        } else {
            cdChecklist = CDChecklistNote(context: context)
            cdChecklist.id = checklist.id
        }
        
        // Update properties
        cdChecklist.title = checklist.title
        cdChecklist.isPinned = checklist.isPinned
        cdChecklist.date = checklist.date
        
        // Handle folder relationship
        if let folderID = checklist.folderID {
            let folderRequest: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
            folderRequest.predicate = NSPredicate(format: "id == %@", folderID as CVarArg)
            if let folder = try? context.fetch(folderRequest).first {
                cdChecklist.folder = folder
            }
        } else {
            cdChecklist.folder = nil
        }
        
        // Handle items - first remove existing items
        let existingItems = cdChecklist.items?.allObjects as? [CDChecklistItem] ?? []
        for item in existingItems {
            context.delete(item)
        }
        
        // Now add new items
        let cdItems = NSMutableSet()
        for item in checklist.items {
            let cdItem = CDChecklistItem.fromDomainModel(item, in: context)
            cdItem.checklist = cdChecklist
            cdItems.add(cdItem)
        }
        cdChecklist.items = cdItems
        
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
        request.predicate = NSPredicate(format: "id == %@", folder.id as CVarArg)
        
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

// MARK: - Core Data Model Extensions
// These extensions provide conversion methods between Core Data models and domain models
// They handle both conversion to domain models and persistence of domain models to Core Data

// MARK: - Note Extensions
/// Extension for converting between CDNote (Core Data) and Note (domain model)
extension CDNote {
    /// Converts a CDNote to its domain model representation
    /// - Returns: A Note object containing all the note's data
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
    
    /// Creates or updates a CDNote from a domain model Note
    /// - Parameters:
    ///   - note: The domain model Note to convert
    ///   - context: The NSManagedObjectContext to use for persistence
    /// - Returns: A CDNote object that represents the note in Core Data
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
            return newNote
        }
    }
}

// MARK: - Checklist Extensions
/// Extension for converting between CDChecklistNote and ChecklistNote
extension CDChecklistNote {
    /// Converts a CDChecklistNote to its domain model representation
    /// - Returns: A ChecklistNote object containing all the checklist's data
    func toDomainModel() -> ChecklistNote {
        let items = (items?.allObjects as? [CDChecklistItem])?.compactMap { $0.toDomainModel() } ?? []
        let tagIDs = (tags?.allObjects as? [CDTag])?.compactMap { $0.id } ?? []
        
        return ChecklistNote(
            id: id ?? UUID(),
            title: title ?? "",
            folderID: folder?.id,
            items: items,
            isPinned: isPinned,
            date: date ?? Date(),
            tagIDs: tagIDs
        )
    }
    
    /// Creates or updates a CDChecklistNote from a domain model ChecklistNote
    /// - Parameters:
    ///   - checklist: The domain model ChecklistNote to convert
    ///   - context: The NSManagedObjectContext to use for persistence
    /// - Returns: A CDChecklistNote object that represents the checklist in Core Data
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
            } else {
                cdChecklist = CDChecklistNote(context: context)
                cdChecklist.id = checklist.id
            }
        } catch {
            print("Error fetching checklist: \(error)")
            cdChecklist = CDChecklistNote(context: context)
            cdChecklist.id = checklist.id
        }
        
        // Update properties
        cdChecklist.title = checklist.title
        cdChecklist.isPinned = checklist.isPinned
        cdChecklist.date = checklist.date
        
        // Handle folder relationship if needed
        if let folderID = checklist.folderID {
            let folderRequest: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
            folderRequest.predicate = NSPredicate(format: "id == %@", folderID.uuidString)
            
            if let folder = try? context.fetch(folderRequest).first {
                cdChecklist.folder = folder
            } else {
                cdChecklist.folder = nil
            }
        } else {
            cdChecklist.folder = nil
        }
        
        // Handle tag relationships
        let existingTags = cdChecklist.tags?.allObjects as? [CDTag] ?? []
        
        // Remove old tag relationships
        for tag in existingTags {
            cdChecklist.removeFromTags(tag)
        }
        
        // Add new tag relationships
        if !checklist.tagIDs.isEmpty {
            let tagRequest: NSFetchRequest<CDTag> = CDTag.fetchRequest()
            tagRequest.predicate = NSPredicate(format: "id IN %@", checklist.tagIDs.map { $0.uuidString })
            
            if let tags = try? context.fetch(tagRequest) {
                for tag in tags {
                    cdChecklist.addToTags(tag)
                }
            }
        }
        
        // Handle checklist items
        let existingItems = cdChecklist.items?.allObjects as? [CDChecklistItem] ?? []
        
        // Delete removed items
        let currentItemIDs = Set(checklist.items.map { $0.id })
        let itemsToDelete = existingItems.filter { !currentItemIDs.contains($0.id ?? UUID()) }
        
        for item in itemsToDelete {
            context.delete(item)
        }
        
        // Update or add new items
        for (_, item) in checklist.items.enumerated() {
            let cdItem: CDChecklistItem
            
            if let existingItem = existingItems.first(where: { $0.id == item.id }) {
                cdItem = existingItem
            } else {
                cdItem = CDChecklistItem(context: context)
                cdItem.id = item.id
                cdChecklist.addToItems(cdItem)
            }
            
            cdItem.text = item.text
            cdItem.isDone = item.isDone
        }
        
        return cdChecklist
    }
}

// MARK: - ChecklistItem Extensions
/// Extension for converting between CDChecklistItem and ChecklistItem
extension CDChecklistItem {
    /// Converts a CDChecklistItem to its domain model representation
    /// - Returns: A ChecklistItem object containing the item's data
    func toDomainModel() -> ChecklistItem {
        return ChecklistItem(
            id: id ?? UUID(),
            text: text ?? "",
            isDone: isDone
        )
    }
    
    /// Creates or updates a CDChecklistItem from a domain model ChecklistItem
    /// - Parameters:
    ///   - item: The domain model ChecklistItem to convert
    ///   - context: The NSManagedObjectContext to use for persistence
    /// - Returns: A CDChecklistItem object that represents the item in Core Data
    static func fromDomainModel(_ item: ChecklistItem, in context: NSManagedObjectContext) -> CDChecklistItem {
        let cdItem = CDChecklistItem(context: context)
        cdItem.id = item.id
        cdItem.text = item.text
        cdItem.isDone = item.isDone
        return cdItem
    }
}

// MARK: - Folder Extensions
/// Extension for converting between CDFolder and Folder
extension CDFolder {
    /// Converts a CDFolder to its domain model representation
    /// - Returns: A Folder object containing the folder's data
    func toDomainModel() -> Folder {
        return Folder(
            id: id ?? UUID(),
            name: name ?? ""
        )
    }
    
    /// Creates or updates a CDFolder from a domain model Folder
    /// - Parameters:
    ///   - folder: The domain model Folder to convert
    ///   - context: The NSManagedObjectContext to use for persistence
    /// - Returns: A CDFolder object that represents the folder in Core Data
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
/// Extension for converting between CDTag and Tag
extension CDTag {
    /// Converts a CDTag to its domain model representation
    /// - Returns: A Tag object containing the tag's data
    func toDomainModel() -> Tag {
        return Tag(
            id: id ?? UUID(),
            name: name ?? "",
            color: Tag.colorFromString(color)
        )
    }
    
    /// Creates or updates a CDTag from a domain model Tag
    /// - Parameters:
    ///   - tag: The domain model Tag to convert
    ///   - context: The NSManagedObjectContext to use for persistence
    /// - Returns: A CDTag object that represents the tag in Core Data
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

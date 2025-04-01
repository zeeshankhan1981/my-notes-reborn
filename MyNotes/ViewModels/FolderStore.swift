import Foundation
import CoreData
import Combine

class FolderStore: ObservableObject {
    @Published var folders: [Folder] = []
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFolders()
        setupObservers()
        
        // If no folders exist, create default ones
        if folders.isEmpty {
            addDefaultFolders()
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                self?.loadFolders()
            }
            .store(in: &cancellables)
    }
    
    private func loadFolders() {
        let request: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDFolder.name, ascending: true)]
        
        do {
            let cdFolders = try persistence.container.viewContext.fetch(request)
            self.folders = cdFolders.map { $0.toDomainModel() }
        } catch {
            print("Error fetching folders: \(error)")
        }
    }
    
    private func addDefaultFolders() {
        addFolder(name: "Personal")
        addFolder(name: "Work")
    }

    func addFolder(name: String) {
        let context = persistence.container.viewContext
        let newFolder = Folder(id: UUID(), name: name)
        
        _ = CDFolder.fromDomainModel(newFolder, in: context)
        
        saveContext()
        loadFolders()
    }
    
    func updateFolder(folder: Folder, newName: String) {
        let context = persistence.container.viewContext
        var updatedFolder = folder
        updatedFolder.name = newName
        
        _ = CDFolder.fromDomainModel(updatedFolder, in: context)
        
        saveContext()
        loadFolders()
    }

    func deleteFolder(id: UUID) {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let folderToDelete = try context.fetch(request).first {
                context.delete(folderToDelete)
                saveContext()
            }
        } catch {
            print("Error deleting folder: \(error)")
        }
        
        loadFolders()
    }
    
    private func saveContext() {
        persistence.save()
    }
    
    // Method to get a folder by ID
    func getFolder(id: UUID) -> Folder? {
        return folders.first { $0.id == id }
    }
}
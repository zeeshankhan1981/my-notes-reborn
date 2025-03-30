import Foundation

class FolderStore: ObservableObject {
    @Published var folders: [Folder] = [
        Folder(id: UUID(), name: "Personal"),
        Folder(id: UUID(), name: "Work")
    ]

    func addFolder(name: String) {
        let newFolder = Folder(id: UUID(), name: name)
        folders.append(newFolder)
    }

    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
    }
}
import SwiftUI

struct FolderManagerView: View {
    @EnvironmentObject var folderStore: FolderStore
    @State private var newFolder = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(folderStore.folders) { folder in
                        Text(folder.name)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            folderStore.deleteFolder(id: folderStore.folders[index].id)
                        }
                    }
                }
                HStack {
                    TextField("New Folder", text: $newFolder)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Add") {
                        folderStore.addFolder(name: newFolder)
                        newFolder = ""
                    }
                }
                .padding()
            }
            .navigationTitle("Folders")
        }
    }
}
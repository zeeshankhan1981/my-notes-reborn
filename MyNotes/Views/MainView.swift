import SwiftUI

struct MainView: View {
    @StateObject private var noteStore = NoteStore()
    @StateObject private var checklistStore = ChecklistStore()
    @StateObject private var folderStore = FolderStore()
    @StateObject private var tagStore = TagStore()
    @StateObject private var cloudSyncMonitor = CloudSyncMonitor()
    @State private var showingGlobalSearch = false
    @State private var showingSyncInfo = false
    @State private var showingCloudPopover = false
    @State private var cloudPopoverAnchor: CGPoint = .zero
    
    init() {
        print("MainView initialized")
    }
    
    var body: some View {
        ZStack {
            TabView {
                NavigationView {
                    NoteListView()
                        .navigationBarItems(trailing: cloudStatusButton)
                }
                .tabItem { Label("Notes", systemImage: "note.text") }
                .onAppear { print("NoteListView appeared") }
                
                NavigationView {
                    ChecklistListView()
                        .navigationBarItems(trailing: cloudStatusButton)
                }
                .tabItem { Label("Checklists", systemImage: "checklist") }
                .onAppear { print("ChecklistListView appeared") }
                
                NavigationView {
                    FolderManagerView()
                        .navigationBarItems(trailing: cloudStatusButton)
                }
                .tabItem { Label("Folders", systemImage: "folder") }
                .onAppear { print("FolderManagerView appeared") }
            }
            
            if showingCloudPopover {
                VStack {
                    HStack {
                        Spacer()
                        CloudSyncPopover(monitor: cloudSyncMonitor, isPresented: $showingCloudPopover)
                            .padding(.trailing, 8)
                            .padding(.top, 8)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        showingCloudPopover = false
                    }
                }
            }
        }
        .environmentObject(noteStore)
        .environmentObject(checklistStore)
        .environmentObject(folderStore)
        .environmentObject(tagStore)
        .environmentObject(cloudSyncMonitor)
        .sheet(isPresented: $showingGlobalSearch) {
            GlobalSearchView()
                .environmentObject(cloudSyncMonitor)
        }
        .sheet(isPresented: $showingSyncInfo) {
            CloudSyncInfoView()
                .environmentObject(cloudSyncMonitor)
        }
        .onAppear {
            print("TabView appeared")
            
            // Check sync status
            cloudSyncMonitor.checkCloudStatus()
            
            // Debug color assets
            print("Color assets check:")
            print("- AppPrimaryColor: \(AppTheme.Colors.primary)")
            print("- AppSecondaryColor: \(AppTheme.Colors.secondary)")
            print("- SecondaryBackground: \(AppTheme.Colors.secondaryBackground)")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowCloudSyncDetails"))) { _ in
            showingSyncInfo = true
        }
    }
    
    private var cloudStatusButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                showingCloudPopover.toggle()
            }
            
            if showingCloudPopover {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }) {
            CloudSyncStatusView(monitor: cloudSyncMonitor)
        }
    }
}
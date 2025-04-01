import SwiftUI

@main
struct MyNotesAppApp: App {
    // Initialize stores with StateObject for proper lifecycle management
    @StateObject private var noteStore = NoteStore()
    @StateObject private var checklistStore = ChecklistStore()
    @StateObject private var folderStore = FolderStore()
    @StateObject private var tagStore = TagStore()
    
    // Theme settings
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("useCustomFont") private var useCustomFont = false
    @AppStorage("fontSize") private var fontSize = 16.0
    
    // Initialize the persistence controller
    let persistenceController = PersistenceController.shared
    
    init() {
        print("MyNotesApp: Application initializing")
        
        // Set up enhanced debug logging
        setupDebugLogging()
        
        // Setup theme observers
        setupThemeObservers()
        
        print("MyNotesApp: Persistence controller initialized with container state: \(persistenceController.container.viewContext.hasChanges ? "has changes" : "no changes")")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(noteStore)
                .environmentObject(checklistStore)
                .environmentObject(folderStore)
                .environmentObject(tagStore)
                // Make Core Data container available to SwiftUI previews
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(getPreferredColorScheme())
                .onAppear {
                    print("MyNotesApp: Main view appeared")
                    validateEnvironment()
                }
        }
    }
    
    private func setupThemeObservers() {
        // Add observer for theme changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppThemeChanged"),
            object: nil,
            queue: .main
        ) { _ in
            print("Theme changed to: \(appTheme)")
            // No action needed as @AppStorage will trigger view updates
        }
        
        // Add observer for font changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("FontSettingsChanged"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let newFontSize = userInfo["fontSize"] as? Double,
               let useCustom = userInfo["useCustomFont"] as? Bool {
                print("Font settings changed: size=\(newFontSize), useCustom=\(useCustom)")
            }
        }
    }
    
    private func getPreferredColorScheme() -> ColorScheme? {
        switch appTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
    
    private func setupDebugLogging() {
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        #endif
    }
    
    private func validateEnvironment() {
        // Verify Core Data and stores are properly initialized
        print("MyNotesApp: Environment validation")
        print("- Note store contains \(noteStore.notes.count) notes")
        print("- Checklist store contains \(checklistStore.checklists.count) checklists")
        print("- Core Data context: \(persistenceController.container.viewContext)")
    }
}
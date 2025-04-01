import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    
    // App theme and appearance
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("useCustomFont") private var useCustomFont = false
    @AppStorage("fontSize") private var fontSize = 16.0
    
    // Dependencies
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var checklistStore: ChecklistStore
    
    var body: some View {
        NavigationView {
            List {
                // APPEARANCE SECTION
                Section(header: Text("APPEARANCE")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                            .padding(.bottom, 4)) {
                    // Theme picker
                    Picker("", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                    
                    // Font size slider with more compact design
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Font Size: \(Int(fontSize))")
                            .font(.subheadline)
                        Slider(value: $fontSize, in: 12...24, step: 1)
                            .tint(.blue)
                    }
                    .padding(.vertical, 8)
                    
                    // Custom font toggle with Todoist-style switch
                    Toggle("Use Custom Font", isOn: $useCustomFont)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .headerProminence(.increased)
                .textCase(nil)
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
                
                // DATA MANAGEMENT SECTION
                Section(header: Text("DATA MANAGEMENT")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                            .padding(.bottom, 4)
                            .padding(.top, 8)) {
                    Button(action: {
                        exportNotes()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .frame(width: 30, alignment: .leading)
                                .foregroundColor(.blue)
                            Text("Export Notes")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        importNotes()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .frame(width: 30, alignment: .leading)
                                .foregroundColor(.blue)
                            Text("Import Notes")
                                .foregroundColor(.primary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .headerProminence(.increased)
                .textCase(nil)
                .listSectionSeparator(.hidden)
                
                // ADVANCED SECTION
                Section(header: Text("ADVANCED")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                            .padding(.bottom, 4)
                            .padding(.top, 8)) {
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .frame(width: 30, alignment: .leading)
                                .foregroundColor(.red)
                            Text("Reset App")
                                .foregroundColor(.red)
                        }
                    }
                    .alert(isPresented: $showResetConfirmation) {
                        Alert(
                            title: Text("Reset App?"),
                            message: Text("This will delete all notes, checklists, folders, and tags. This action cannot be undone."),
                            primaryButton: .destructive(Text("Reset")) {
                                resetApp()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .headerProminence(.increased)
                .textCase(nil)
                .listSectionSeparator(.hidden)
                
                // ABOUT SECTION
                Section(header: Text("ABOUT")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                            .padding(.bottom, 4)
                            .padding(.top, 8)) {
                    HStack {
                        Text("Version")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .headerProminence(.increased)
                .textCase(nil)
                .listSectionSeparator(.hidden)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                // Apply all settings and dismiss
                applySettings()
                dismiss()
            })
        }
    }
    
    // MARK: - Functions
    
    private func applySettings() {
        // Notify the system about theme changes
        NotificationCenter.default.post(name: NSNotification.Name("AppThemeChanged"), object: nil)
        
        // Apply font settings
        NotificationCenter.default.post(name: NSNotification.Name("FontSettingsChanged"), object: nil, userInfo: [
            "fontSize": fontSize,
            "useCustomFont": useCustomFont
        ])
        
        // Save settings to UserDefaults
        UserDefaults.standard.synchronize()
    }
    
    private func exportNotes() {
        // Set up for file export
        showExportSheet = true
        
        // This would typically involve document picker or share sheet
        // For now, just simulate with an alert
        let alert = UIAlertController(title: "Export Notes", message: "Your notes would be exported here", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func importNotes() {
        // Set up for file import
        showImportSheet = true
        
        // This would typically involve document picker
        // For now, just simulate with an alert
        let alert = UIAlertController(title: "Import Notes", message: "You would select notes to import here", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func resetApp() {
        // Clear all data
        // 1. Delete all notes
        for note in noteStore.notes {
            noteStore.delete(note: note)
        }
        
        // 2. Delete all checklists
        for checklist in checklistStore.checklists {
            checklistStore.delete(checklist: checklist)
        }
        
        // 3. Reset all user defaults except critical ones
        let defaults = UserDefaults.standard
        let appDomain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: appDomain)
        
        // Restore default values
        appTheme = "system"
        useCustomFont = false
        fontSize = 16.0
        
        // 4. Give feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 5. Show confirmation
        let alert = UIAlertController(title: "App Reset", message: "All data has been cleared", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(NoteStore())
            .environmentObject(ChecklistStore())
    }
}

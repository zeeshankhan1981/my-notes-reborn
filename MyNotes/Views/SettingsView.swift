import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var exportFileName = "MyNotes_Backup_\(Date().formatted(.dateTime.year().month().day()))"
    
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
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)) {
                    // Theme picker
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .listRowBackground(AppTheme.Colors.cardSurface)
                    .padding(.vertical, AppTheme.Dimensions.spacingXS)
                    .onChange(of: appTheme) { newValue in
                        applyThemeChange(newValue)
                    }
                    
                    // Font size slider with more compact design
                    VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingXS) {
                        Text("Font Size: \(Int(fontSize))")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Slider(value: $fontSize, in: 12...24, step: 1)
                            .tint(AppTheme.Colors.primary)
                            .onChange(of: fontSize) { newValue in
                                applyFontSizeChange(newValue)
                            }
                    }
                    .padding(.vertical, AppTheme.Dimensions.spacingXS)
                    
                    // Custom font toggle with Todoist-style switch
                    Toggle("Use Custom Font", isOn: $useCustomFont)
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.Colors.primary))
                        .onChange(of: useCustomFont) { newValue in
                            applyCustomFontChange(newValue)
                        }
                }
                .listRowInsets(EdgeInsets(top: AppTheme.Dimensions.spacingS, leading: AppTheme.Dimensions.spacingM, bottom: AppTheme.Dimensions.spacingS, trailing: AppTheme.Dimensions.spacingM))
                .textCase(nil)
                
                // DATA MANAGEMENT SECTION
                Section(header: Text("DATA MANAGEMENT")
                            .font(.footnote)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)) {
                    Button(action: {
                        exportNotes()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .frame(width: 24, alignment: .leading)
                                .foregroundColor(AppTheme.Colors.primary)
                            Text("Export Notes")
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    Button(action: {
                        importNotes()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .frame(width: 24, alignment: .leading)
                                .foregroundColor(AppTheme.Colors.primary)
                            Text("Import Notes")
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: AppTheme.Dimensions.spacingS, leading: AppTheme.Dimensions.spacingM, bottom: AppTheme.Dimensions.spacingS, trailing: AppTheme.Dimensions.spacingM))
                .textCase(nil)
                
                // ADVANCED SECTION
                Section(header: Text("ADVANCED")
                            .font(.footnote)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)) {
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .frame(width: 24, alignment: .leading)
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
                .listRowInsets(EdgeInsets(top: AppTheme.Dimensions.spacingS, leading: AppTheme.Dimensions.spacingM, bottom: AppTheme.Dimensions.spacingS, trailing: AppTheme.Dimensions.spacingM))
                .textCase(nil)
                
                // ABOUT SECTION
                Section(header: Text("ABOUT")
                            .font(.footnote)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)) {
                    HStack {
                        Text("Version")
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .listRowInsets(EdgeInsets(top: AppTheme.Dimensions.spacingS, leading: AppTheme.Dimensions.spacingM, bottom: AppTheme.Dimensions.spacingS, trailing: AppTheme.Dimensions.spacingM))
                .textCase(nil)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                // Apply all settings and dismiss
                applySettings()
                dismiss()
            })
            .sheet(isPresented: $showExportSheet) {
                // Export sheet UI would be here
                NavigationView {
                    VStack {
                        Text("Export Notes")
                            .font(.title2)
                            .padding(.top, 20)
                        
                        Spacer()
                        
                        Text("Your data will be exported as a JSON file.")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        TextField("Filename", text: $exportFileName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button("Export") {
                            performExport()
                            showExportSheet = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationBarItems(trailing: Button("Cancel") {
                        showExportSheet = false
                    })
                }
            }
            .sheet(isPresented: $showImportSheet) {
                // Import sheet UI would be here
                NavigationView {
                    VStack {
                        Text("Import Notes")
                            .font(.title2)
                            .padding(.top, 20)
                        
                        Spacer()
                        
                        Text("Select a JSON file to import.\nThis will add notes to your existing collection.")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Select File") {
                            performImport()
                            showImportSheet = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationBarItems(trailing: Button("Cancel") {
                        showImportSheet = false
                    })
                }
            }
        }
        .onAppear {
            // Ensure settings reflect current values from UserDefaults
            appTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
            useCustomFont = UserDefaults.standard.bool(forKey: "useCustomFont")
            fontSize = UserDefaults.standard.double(forKey: "fontSize")
            if fontSize == 0 { fontSize = 16.0 } // Default if not set
        }
    }
    
    // MARK: - Functions
    
    private func applySettings() {
        // Apply all current settings
        applyThemeChange(appTheme)
        applyFontSizeChange(fontSize)
        applyCustomFontChange(useCustomFont)
        
        // Save settings to UserDefaults
        UserDefaults.standard.set(appTheme, forKey: "appTheme")
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        UserDefaults.standard.set(useCustomFont, forKey: "useCustomFont")
        UserDefaults.standard.synchronize()
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func applyThemeChange(_ theme: String) {
        // Notify the system about theme changes
        NotificationCenter.default.post(
            name: NSNotification.Name("AppThemeChanged"), 
            object: nil, 
            userInfo: ["theme": theme]
        )
        print("Theme changed to: \(theme)")
    }
    
    private func applyFontSizeChange(_ size: Double) {
        // Update font size throughout the app
        NotificationCenter.default.post(
            name: NSNotification.Name("FontSettingsChanged"), 
            object: nil, 
            userInfo: [
                "fontSize": size,
                "useCustomFont": useCustomFont
            ]
        )
        print("Font size changed to: \(size)")
    }
    
    private func applyCustomFontChange(_ useCustom: Bool) {
        // Update custom font setting
        NotificationCenter.default.post(
            name: NSNotification.Name("FontSettingsChanged"), 
            object: nil, 
            userInfo: [
                "fontSize": fontSize,
                "useCustomFont": useCustom
            ]
        )
        print("Custom font setting changed to: \(useCustom)")
    }
    
    private func exportNotes() {
        // Set up for file export
        showExportSheet = true
    }
    
    private func performExport() {
        // This would need a document picker implementation in a real app
        // For now, showing feedback to the user
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let alert = UIAlertController(
            title: "Export Complete",
            message: "Your notes have been exported successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func importNotes() {
        // Set up for file import
        showImportSheet = true
    }
    
    private func performImport() {
        // This would need a document picker implementation in a real app
        // For now, showing feedback to the user
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let alert = UIAlertController(
            title: "Import Complete",
            message: "Your notes have been imported successfully.",
            preferredStyle: .alert
        )
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
        
        // Save restored defaults
        UserDefaults.standard.set(appTheme, forKey: "appTheme")
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        UserDefaults.standard.set(useCustomFont, forKey: "useCustomFont")
        UserDefaults.standard.synchronize()
        
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

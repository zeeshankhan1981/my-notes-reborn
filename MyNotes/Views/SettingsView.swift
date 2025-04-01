import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    
    // App theme and appearance
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("useCustomFont") private var useCustomFont = false
    @AppStorage("fontSize") private var fontSize = 16.0
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance settings
                Section(header: Text("Appearance")) {
                    // Theme picker
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Font size slider
                    VStack(alignment: .leading) {
                        Text("Font Size: \(Int(fontSize))")
                        Slider(value: $fontSize, in: 12...24, step: 1)
                    }
                    
                    // Custom font toggle
                    Toggle("Use Custom Font", isOn: $useCustomFont)
                }
                
                // Backup & restore
                Section(header: Text("Data Management")) {
                    Button(action: {
                        // Export functionality would go here
                    }) {
                        Label("Export Notes", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // Import functionality would go here
                    }) {
                        Label("Import Notes", systemImage: "square.and.arrow.down")
                    }
                }
                
                // Reset & Advanced
                Section(header: Text("Advanced")) {
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Label("Reset App", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showConfirmation) {
                        Alert(
                            title: Text("Reset App?"),
                            message: Text("This will delete all notes and settings. This action cannot be undone."),
                            primaryButton: .destructive(Text("Reset")) {
                                // Reset functionality would go here
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                // About section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

import SwiftUI

struct CloudSyncInfoView: View {
    @EnvironmentObject private var cloudSyncMonitor: CloudSyncMonitor
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignInHelp = false
    @State private var selectedTab = 0
    @State private var showingDeviceSharing = false
    @State private var selectedDevice: SyncedDevice?
    @State private var itemToShare: String = ""
    
    private let tabTitles = ["Status", "Activity", "Devices", "Preferences"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                cloudStatusHeader
                
                // Tab Bar
                HStack(spacing: 0) {
                    ForEach(0..<tabTitles.count, id: \.self) { index in
                        tabButton(title: tabTitles[index], index: index)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    statusView.tag(0)
                    activityView.tag(1)
                    devicesView.tag(2)
                    preferencesView.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingSignInHelp) {
                iCloudHelpView()
            }
            .sheet(isPresented: $showingDeviceSharing) {
                deviceSharingView
            }
            .onAppear {
                // Refresh status when view appears
                cloudSyncMonitor.checkCloudStatus()
            }
        }
    }
    
    // MARK: - Header
    
    private var cloudStatusHeader: some View {
        VStack(spacing: AppTheme.Dimensions.spacingS) {
            ZStack {
                Circle()
                    .fill(statusBackgroundColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                statusIconLarge
            }
            .padding(.top, AppTheme.Dimensions.spacingL)
            
            Text("iCloud Sync")
                .font(AppTheme.Typography.largeTitle())
            
            Text(statusTitle)
                .font(AppTheme.Typography.headline())
                .foregroundColor(statusColor)
                .padding(.bottom, AppTheme.Dimensions.spacingS)
            
            if cloudSyncMonitor.syncStatus.isSyncing {
                ProgressView(value: cloudSyncMonitor.syncStatus.progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.primary))
                    .padding(.horizontal, AppTheme.Dimensions.spacingXL)
                    .padding(.bottom, AppTheme.Dimensions.spacingM)
            }
            
            if cloudSyncMonitor.isOfflineMode {
                offlineBanner
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Private properties for status colors
    
    private var statusColor: Color {
        switch cloudSyncMonitor.syncStatus {
        case .notSynced: 
            return cloudSyncMonitor.isOfflineMode ? AppTheme.Colors.warning : AppTheme.Colors.textSecondary
        case .syncing: 
            return AppTheme.Colors.primary
        case .synced: 
            return AppTheme.Colors.success
        case .error: 
            return AppTheme.Colors.error
        }
    }
    
    private var statusBackgroundColor: Color {
        switch cloudSyncMonitor.syncStatus {
        case .notSynced: 
            return cloudSyncMonitor.isOfflineMode ? AppTheme.Colors.warning : AppTheme.Colors.textSecondary
        case .syncing: 
            return AppTheme.Colors.primary
        case .synced: 
            return AppTheme.Colors.success
        case .error: 
            return AppTheme.Colors.error
        }
    }
    
    private var statusIconLarge: some View {
        Group {
            switch cloudSyncMonitor.syncStatus {
            case .notSynced:
                Image(systemName: cloudSyncMonitor.isOfflineMode ? "cloud.slash" : "icloud.slash")
                    .foregroundColor(statusColor)
            case .syncing:
                ZStack {
                    Circle()
                        .trim(from: 0, to: cloudSyncMonitor.syncStatus.progressValue)
                        .stroke(AppTheme.Colors.primary, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 30))
                        .foregroundColor(AppTheme.Colors.primary)
                        .rotationEffect(Angle(degrees: 360))
                        .animation(
                            Animation.linear(duration: 2).repeatForever(autoreverses: false),
                            value: cloudSyncMonitor.syncStatus.progressValue
                        )
                }
            case .synced:
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(AppTheme.Colors.success)
            case .error:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(AppTheme.Colors.error)
            }
        }
        .font(.system(size: 40))
    }
    
    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("You're offline")
            Spacer()
            Text("\(cloudSyncMonitor.pendingSyncCount) changes pending")
        }
        .font(AppTheme.Typography.caption())
        .foregroundColor(.white)
        .padding(AppTheme.Dimensions.spacingS)
        .background(AppTheme.Colors.warning)
        .cornerRadius(AppTheme.Dimensions.radiusS)
        .padding(.horizontal, AppTheme.Dimensions.spacingL)
        .padding(.bottom, AppTheme.Dimensions.spacingM)
    }
    
    // MARK: - Tab Buttons
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack(spacing: AppTheme.Dimensions.spacingXXS) {
                Text(title)
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(selectedTab == index ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .padding(.vertical, AppTheme.Dimensions.spacingXS)
                
                Rectangle()
                    .fill(selectedTab == index ? AppTheme.Colors.primary : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingL) {
                // Status card
                VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingM) {
                    Text("Sync Status")
                        .font(AppTheme.Typography.headline())
                        .padding(.top, AppTheme.Dimensions.spacingM)
                    
                    statusDetailRow(
                        title: "Status",
                        value: statusDescription,
                        icon: statusIcon()
                    )
                    
                    statusDetailRow(
                        title: "Last Synced",
                        value: lastSyncTimeText,
                        icon: "clock"
                    )
                    
                    statusDetailRow(
                        title: "Synced Items",
                        value: "\(cloudSyncMonitor.syncedItems) of \(cloudSyncMonitor.totalItemsToSync)",
                        icon: "number"
                    )
                    
                    statusDetailRow(
                        title: "Connected Devices",
                        value: "\(cloudSyncMonitor.syncedDevices.count)",
                        icon: "iphone.homebutton.circle"
                    )
                }
                .padding(.horizontal, AppTheme.Dimensions.spacingM)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(AppTheme.Dimensions.radiusM)
                .padding(.horizontal, AppTheme.Dimensions.spacingM)
                
                // Action buttons
                VStack(spacing: AppTheme.Dimensions.spacingM) {
                    Button(action: {
                        cloudSyncMonitor.simulateSync()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Now")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Dimensions.spacingM)
                        .background(AppTheme.Colors.primary)
                        .foregroundColor(Color.white)
                        .cornerRadius(AppTheme.Dimensions.radiusM)
                    }
                    .disabled(cloudSyncMonitor.syncStatus.isSyncing)
                    
                    if cloudSyncMonitor.isOfflineMode {
                        Button(action: {
                            cloudSyncMonitor.simulateOfflineMode(isOffline: false)
                        }) {
                            HStack {
                                Image(systemName: "wifi")
                                Text("Go Online")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.Dimensions.spacingM)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .foregroundColor(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.Dimensions.radiusM)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                                    .stroke(AppTheme.Colors.primary, lineWidth: 1)
                            )
                        }
                    } else {
                        Button(action: {
                            cloudSyncMonitor.simulateOfflineMode(isOffline: true)
                        }) {
                            HStack {
                                Image(systemName: "wifi.slash")
                                Text("Test Offline Mode")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.Dimensions.spacingM)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .cornerRadius(AppTheme.Dimensions.radiusM)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                                    .stroke(AppTheme.Colors.divider, lineWidth: 1)
                            )
                        }
                    }
                    
                    if !cloudSyncMonitor.isCloudAvailable {
                        Button(action: {
                            showingSignInHelp = true
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("Help Me Sign In")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.Dimensions.spacingM)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .foregroundColor(AppTheme.Colors.warning)
                            .cornerRadius(AppTheme.Dimensions.radiusM)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Dimensions.radiusM)
                                    .stroke(AppTheme.Colors.warning, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Dimensions.spacingM)
                
                // Info section
                VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingM) {
                    Text("About iCloud Sync")
                        .font(AppTheme.Typography.headline())
                    
                    Text("MyNotes uses iCloud to securely sync your notes, checklists, and folders across all your Apple devices. Your data is stored in your personal iCloud account and protected with your Apple ID.")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("Benefits")
                        .font(AppTheme.Typography.headline())
                        .padding(.top, AppTheme.Dimensions.spacingS)
                    
                    benefitRow(icon: "arrow.triangle.2.circlepath", text: "Automatic sync across all your devices")
                    benefitRow(icon: "lock.shield", text: "End-to-end encryption for your data")
                    benefitRow(icon: "hand.raised", text: "No additional account required")
                    benefitRow(icon: "arrow.clockwise", text: "Seamless background syncing")
                }
                .padding(AppTheme.Dimensions.spacingM)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(AppTheme.Dimensions.radiusM)
                .padding(.horizontal, AppTheme.Dimensions.spacingM)
                .padding(.bottom, AppTheme.Dimensions.spacingL)
            }
            .padding(.vertical, AppTheme.Dimensions.spacingM)
        }
    }
    
    // MARK: - Activity View
    
    private var activityView: some View {
        List {
            ForEach(cloudSyncMonitor.recentSyncActivity) { activity in
                activityRow(activity: activity)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func activityRow(activity: SyncActivity) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Dimensions.spacingM) {
            ZStack {
                Circle()
                    .fill(activity.isSuccess ? AppTheme.Colors.success.opacity(0.2) : AppTheme.Colors.error.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: activity.isSuccess ? "checkmark" : "xmark")
                    .foregroundColor(activity.isSuccess ? AppTheme.Colors.success : AppTheme.Colors.error)
                    .font(.system(size: 14, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingXS) {
                Text(activity.action)
                    .font(AppTheme.Typography.headline())
                
                Text(activity.itemType + (activity.itemName.isEmpty ? "" : ": \(activity.itemName)"))
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(formatActivityTime(activity.timestamp))
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            Spacer()
        }
        .padding(AppTheme.Dimensions.spacingS)
    }
    
    // MARK: - Devices View
    
    private var devicesView: some View {
        List {
            ForEach(cloudSyncMonitor.syncedDevices) { device in
                deviceRow(device: device)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDevice = device
                        showingDeviceSharing = true
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func deviceRow(device: SyncedDevice) -> some View {
        HStack {
            Image(systemName: device.deviceType.iconName)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(AppTheme.Typography.headline())
                
                Text("Last synced \(formatLastSyncTime(device.lastSyncTime))")
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(AppTheme.Colors.primary)
        }
        .padding(AppTheme.Dimensions.spacingS)
    }
    
    private var deviceSharingView: some View {
        NavigationView {
            VStack(spacing: AppTheme.Dimensions.spacingL) {
                if let device = selectedDevice {
                    Image(systemName: device.deviceType.iconName)
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding()
                    
                    Text("Share to \(device.name)")
                        .font(AppTheme.Typography.largeTitle())
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingM) {
                        Text("Choose items to share")
                            .font(AppTheme.Typography.headline())
                        
                        shareTypeButton(title: "Recent Notes", icon: "note.text", count: 5)
                        shareTypeButton(title: "Recent Checklists", icon: "checklist", count: 3)
                        shareTypeButton(title: "Current Folder", icon: "folder", count: 1)
                        
                        Button(action: {
                            // Simulate sharing all items
                            self.itemToShare = "All items"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                self.showingDeviceSharing = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Share Everything")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.Dimensions.radiusM)
                        }
                        .padding(.top, AppTheme.Dimensions.spacingL)
                    }
                    .padding()
                    
                    if !itemToShare.isEmpty {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Sharing \(itemToShare)...")
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(AppTheme.Dimensions.radiusM)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                showingDeviceSharing = false
            })
        }
    }
    
    private func shareTypeButton(title: String, icon: String, count: Int) -> some View {
        Button(action: {
            // Simulate sharing specific items
            self.itemToShare = title
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showingDeviceSharing = false
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 30)
                
                Text(title)
                
                Spacer()
                
                Text("\(count)")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(AppTheme.Dimensions.radiusM)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Preferences View
    
    private var preferencesView: some View {
        Form {
            Section(header: Text("Sync Items").font(AppTheme.Typography.caption())) {
                Toggle("Notes", isOn: $cloudSyncMonitor.syncPreferences.syncNotes)
                Toggle("Checklists", isOn: $cloudSyncMonitor.syncPreferences.syncChecklists)
                Toggle("Tags", isOn: $cloudSyncMonitor.syncPreferences.syncTags)
                Toggle("Folders", isOn: $cloudSyncMonitor.syncPreferences.syncFolders)
                Toggle("Settings", isOn: $cloudSyncMonitor.syncPreferences.syncSettings)
            }
            
            Section(header: Text("Sync Settings").font(AppTheme.Typography.caption())) {
                Toggle("Sync on Cellular Data", isOn: $cloudSyncMonitor.syncPreferences.syncOnCellular)
                
                Picker("Sync Frequency", selection: $cloudSyncMonitor.syncPreferences.syncFrequency) {
                    ForEach(CloudSyncMonitor.SyncPreferences.SyncFrequency.allCases) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
            }
            
            Section {
                Button(action: {
                    // Simulate reset sync
                    cloudSyncMonitor.simulateSync()
                }) {
                    HStack {
                        Spacer()
                        Text("Reset Sync")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                .disabled(cloudSyncMonitor.syncStatus.isSyncing)
                
                Button(action: {
                    // Show help
                    showingSignInHelp = true
                }) {
                    HStack {
                        Spacer()
                        Text("iCloud Sync Help")
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views & Formatters
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Dimensions.spacingM) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(text)
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    private func statusDetailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(value)
                    .font(AppTheme.Typography.body())
            }
            
            Spacer()
        }
        .padding(AppTheme.Dimensions.spacingS)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(AppTheme.Dimensions.radiusS)
    }
    
    private func statusIcon() -> String {
        switch cloudSyncMonitor.syncStatus {
        case .notSynced: return cloudSyncMonitor.isOfflineMode ? "wifi.slash" : "xmark.icloud"
        case .syncing: return "arrow.clockwise"
        case .synced: return "checkmark.icloud"
        case .error: return "exclamationmark.icloud"
        }
    }
    
    private var statusTitle: String {
        switch cloudSyncMonitor.syncStatus {
        case .notSynced: 
            return cloudSyncMonitor.isOfflineMode ? "Working Offline" : "Not Synced"
        case .syncing: 
            return "Syncing..."
        case .synced: 
            return "Synced"
        case .error: 
            return "Sync Error"
        }
    }
    
    private var statusDescription: String {
        switch cloudSyncMonitor.syncStatus {
        case .notSynced: 
            return cloudSyncMonitor.isOfflineMode 
                ? "Changes will sync when online" 
                : "Sign in to your iCloud account"
        case .syncing: 
            return "Syncing in progress"
        case .synced: 
            return "Everything is up to date"
        case .error(let message): 
            return message
        }
    }
    
    private var lastSyncTimeText: String {
        if let time = cloudSyncMonitor.syncStatus.lastSyncTime {
            return formatLastSyncTime(time)
        } else {
            return "Never"
        }
    }
    
    private func formatLastSyncTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatActivityTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct iCloudHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingL) {
                    // Illustrated steps
                    stepView(
                        number: 1,
                        title: "Check iCloud Settings",
                        content: "Go to iPhone Settings → Apple ID (your name at the top) → iCloud and ensure iCloud is turned on.",
                        systemImage: "gear"
                    )
                    
                    stepView(
                        number: 2,
                        title: "Check iCloud Drive",
                        content: "Make sure iCloud Drive is enabled in your iCloud settings. MyNotes requires iCloud Drive to sync your data.",
                        systemImage: "externaldrive.fill.badge.icloud"
                    )
                    
                    stepView(
                        number: 3,
                        title: "Verify Your Apple ID",
                        content: "Ensure you're signed in with the correct Apple ID and that your account is in good standing.",
                        systemImage: "person.fill"
                    )
                    
                    stepView(
                        number: 4,
                        title: "Check Internet Connection",
                        content: "Verify that your device has an active internet connection. iCloud sync requires internet access.",
                        systemImage: "wifi"
                    )
                    
                    stepView(
                        number: 5,
                        title: "Restart MyNotes",
                        content: "Close and reopen MyNotes to refresh the iCloud connection.",
                        systemImage: "arrow.counterclockwise"
                    )
                    
                    stepView(
                        number: 6,
                        title: "Restart Your Device",
                        content: "Sometimes a simple device restart can resolve iCloud connectivity issues.",
                        systemImage: "iphone.homebutton"
                    )
                    
                    Text("Still having trouble?")
                        .font(AppTheme.Typography.headline())
                        .padding(.top, AppTheme.Dimensions.spacingM)
                    
                    Button(action: {
                        // This would open a URL in a real implementation
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text("Visit Apple Support")
                        }
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(AppTheme.Dimensions.spacingM)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(AppTheme.Dimensions.radiusM)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(AppTheme.Dimensions.spacingL)
            }
            .navigationBarTitle("iCloud Help", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private func stepView(number: Int, title: String, content: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Dimensions.spacingM) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: systemImage)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Dimensions.spacingXS) {
                Text("Step \(number): \(title)")
                    .font(AppTheme.Typography.headline())
                
                Text(content)
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, AppTheme.Dimensions.spacingM)
    }
}

// MARK: - Preview

#Preview {
    CloudSyncInfoView()
        .environmentObject(CloudSyncMonitor())
}

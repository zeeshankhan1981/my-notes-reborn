import SwiftUI

enum CloudSyncStatus: Equatable {
    case notSynced
    case syncing(progress: Double)
    case synced(lastSyncTime: Date)
    case error(message: String)
    
    var isNotSynced: Bool {
        if case .notSynced = self { return true }
        return false
    }
    
    var isSyncing: Bool {
        if case .syncing(_) = self { return true }
        return false
    }
    
    var isSynced: Bool {
        if case .synced = self { return true }
        return false
    }
    
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
    
    var progressValue: Double {
        if case .syncing(let progress) = self { return progress }
        return 0
    }
    
    var lastSyncTime: Date? {
        if case .synced(let time) = self { return time }
        return nil
    }
    
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}

struct SyncedDevice: Identifiable {
    let id = UUID()
    let name: String
    let deviceType: DeviceType
    let lastSyncTime: Date
    
    enum DeviceType {
        case iPhone, iPad, mac
        
        var iconName: String {
            switch self {
            case .iPhone: return "iphone"
            case .iPad: return "ipad"
            case .mac: return "desktopcomputer"
            }
        }
    }
}

struct SyncActivity: Identifiable {
    let id = UUID()
    let timestamp: Date
    let action: String
    let itemType: String
    let itemName: String
    let status: CloudSyncStatus
    
    var isSuccess: Bool {
        if case .synced = status { return true }
        return false
    }
}

class CloudSyncMonitor: ObservableObject {
    @Published var syncStatus: CloudSyncStatus = .notSynced
    @Published var isCloudAvailable: Bool = false
    @Published var syncedItems: Int = 0
    @Published var totalItemsToSync: Int = 0
    @Published var syncPreferences = SyncPreferences()
    @Published var syncedDevices: [SyncedDevice] = []
    @Published var recentSyncActivity: [SyncActivity] = []
    @Published var isOfflineMode: Bool = false
    @Published var pendingSyncCount: Int = 0
    
    private var timer: Timer?
    
    struct SyncPreferences {
        var syncNotes: Bool = true
        var syncChecklists: Bool = true
        var syncTags: Bool = true
        var syncFolders: Bool = true
        var syncSettings: Bool = true
        var syncOnCellular: Bool = true
        var syncFrequency: SyncFrequency = .realTime
        
        enum SyncFrequency: String, CaseIterable, Identifiable {
            case realTime = "Real-time"
            case hourly = "Hourly"
            case daily = "Daily"
            case manual = "Manual only"
            
            var id: String { self.rawValue }
        }
    }
    
    init() {
        checkCloudStatus()
        setupMockData()
        
        // Set up periodic sync status check
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkCloudStatus()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func checkCloudStatus() {
        // For demonstration purposes - in a real implementation, this would check iCloud status
        // We're mocking the behavior for now
        DispatchQueue.main.async {
            // Simulate cloud availability check
            self.isCloudAvailable = true
            
            // Simulate sync status
            self.syncStatus = .synced(lastSyncTime: Date())
            
            // Check if we're offline
            self.isOfflineMode = false
            
            // Update the number of pending items
            self.pendingSyncCount = 0
        }
    }
    
    func simulateSync() {
        // This method simulates a sync operation for demonstration
        self.totalItemsToSync = Int.random(in: 5...15)
        self.syncedItems = 0
        
        // Create a fake sync activity
        let activity = SyncActivity(
            timestamp: Date(),
            action: "Sync started",
            itemType: "All items",
            itemName: "",
            status: .syncing(progress: 0)
        )
        self.recentSyncActivity.insert(activity, at: 0)
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing(progress: 0)
            
            // Simulate sync completion after delay with progress updates
            var progress = 0.0
            
            // Cancel any existing timer
            self.timer?.invalidate()
            
            // Create a new timer for the sync animation
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }
                
                progress += Double.random(in: 0.03...0.1)
                if progress >= 1.0 {
                    progress = 1.0
                    timer.invalidate()
                    
                    // Complete sync
                    self.syncedItems = self.totalItemsToSync
                    self.syncStatus = .synced(lastSyncTime: Date())
                    
                    // Add completed activity
                    let completedActivity = SyncActivity(
                        timestamp: Date(),
                        action: "Sync completed",
                        itemType: "All items",
                        itemName: "",
                        status: .synced(lastSyncTime: Date())
                    )
                    self.recentSyncActivity.insert(completedActivity, at: 0)
                    
                    // Limit the activity list size
                    if self.recentSyncActivity.count > 20 {
                        self.recentSyncActivity = Array(self.recentSyncActivity.prefix(20))
                    }
                    
                    // Restart regular status check timer
                    self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                        self?.checkCloudStatus()
                    }
                } else {
                    // Update progress
                    self.syncedItems = Int(progress * Double(self.totalItemsToSync))
                    self.syncStatus = .syncing(progress: progress)
                }
            }
        }
    }
    
    func simulateError() {
        DispatchQueue.main.async {
            self.syncStatus = .error(message: "Failed to connect to iCloud")
            
            // Add error activity
            let errorActivity = SyncActivity(
                timestamp: Date(),
                action: "Sync failed",
                itemType: "Cloud Connection",
                itemName: "",
                status: .error(message: "Failed to connect to iCloud")
            )
            self.recentSyncActivity.insert(errorActivity, at: 0)
        }
    }
    
    func simulateOfflineMode(isOffline: Bool) {
        DispatchQueue.main.async {
            self.isOfflineMode = isOffline
            if isOffline {
                self.pendingSyncCount = Int.random(in: 3...10)
                self.syncStatus = .notSynced
            } else {
                self.simulateSync()
            }
        }
    }
    
    // Setup mock data for UI demonstration
    private func setupMockData() {
        // Mock synced devices
        syncedDevices = [
            SyncedDevice(name: "iPhone 14 Pro", deviceType: .iPhone, lastSyncTime: Date().addingTimeInterval(-180)),
            SyncedDevice(name: "iPad Pro", deviceType: .iPad, lastSyncTime: Date().addingTimeInterval(-3600)),
            SyncedDevice(name: "MacBook Air", deviceType: .mac, lastSyncTime: Date().addingTimeInterval(-7200))
        ]
        
        // Mock recent activity
        recentSyncActivity = [
            SyncActivity(
                timestamp: Date().addingTimeInterval(-60),
                action: "Sync completed",
                itemType: "Notes",
                itemName: "All notes",
                status: .synced(lastSyncTime: Date().addingTimeInterval(-60))
            ),
            SyncActivity(
                timestamp: Date().addingTimeInterval(-300),
                action: "Sync completed",
                itemType: "Checklists",
                itemName: "All checklists",
                status: .synced(lastSyncTime: Date().addingTimeInterval(-300))
            ),
            SyncActivity(
                timestamp: Date().addingTimeInterval(-1800),
                action: "Sync failed",
                itemType: "Settings",
                itemName: "",
                status: .error(message: "Network connection lost")
            )
        ]
    }
}

struct CloudSyncStatusView: View {
    @ObservedObject var monitor: CloudSyncMonitor
    @State private var showDropdown = false
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
            
            if monitor.pendingSyncCount > 0 {
                Text("\(monitor.pendingSyncCount)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(3)
                    .background(AppTheme.Colors.warning)
                    .clipShape(Circle())
            }
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch monitor.syncStatus {
            case .notSynced:
                Image(systemName: monitor.isOfflineMode ? "cloud.slash" : "icloud.slash")
                    .foregroundColor(.gray)
                
            case .syncing:
                ZStack {
                    Circle()
                        .trim(from: 0, to: monitor.syncStatus.progressValue)
                        .stroke(AppTheme.Colors.primary, lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.primary)
                        .rotationEffect(.degrees(360))
                        .animation(
                            Animation.linear(duration: 1).repeatForever(autoreverses: false),
                            value: UUID()
                        )
                }
                .frame(width: 18, height: 18)
            
            case .synced:
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(AppTheme.Colors.success)
                
            case .error:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.red)
            }
        }
        .font(.system(size: 18))
        .frame(width: 24, height: 24)
    }
}

// MARK: - Preview

#Preview {
    CloudSyncStatusView(monitor: CloudSyncMonitor())
}

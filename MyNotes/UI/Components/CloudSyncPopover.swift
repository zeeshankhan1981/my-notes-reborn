import SwiftUI

struct CloudSyncPopover: View {
    @ObservedObject var monitor: CloudSyncMonitor
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(statusTitle)
                    .font(AppTheme.Typography.subheadline())
                
                Spacer()
                
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowCloudSyncDetails"), object: nil)
                    isPresented = false
                }) {
                    Text("Details")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            Divider()
            
            syncStatusRow
            
            Divider()
            
            Button(action: {
                monitor.simulateSync()
                withAnimation {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPresented = false
                    }
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Sync Now")
                }
                .foregroundColor(AppTheme.Colors.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 6)
            
            Button(action: {
                monitor.simulateOfflineMode(isOffline: !monitor.isOfflineMode)
            }) {
                HStack {
                    Image(systemName: monitor.isOfflineMode ? "wifi" : "wifi.slash")
                    Text(monitor.isOfflineMode ? "Go Online" : "Test Offline Mode")
                }
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 6)
        }
        .padding(12)
        .background(
            Color(UIColor.systemBackground)
                .shadow(radius: 5)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .frame(width: 200)
    }
    
    private var syncStatusRow: some View {
        Group {
            if monitor.syncStatus.isSyncing {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Syncing...")
                            .font(AppTheme.Typography.caption())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(monitor.syncStatus.progressValue * 100))%")
                            .font(AppTheme.Typography.caption())
                    }
                    
                    ProgressView(value: monitor.syncStatus.progressValue)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.primary))
                        .frame(height: 2)
                }
                .padding(.vertical, 4)
            } else if monitor.isOfflineMode {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("\(monitor.pendingSyncCount) changes pending")
                        .foregroundColor(AppTheme.Colors.warning)
                    Spacer()
                }
                .font(AppTheme.Typography.caption())
                .padding(.vertical, 4)
            }
        }
    }
    
    private var statusTitle: String {
        switch monitor.syncStatus {
        case .notSynced: 
            return monitor.isOfflineMode ? "Working Offline" : "Not Synced"
        case .syncing: 
            return "Syncing..."
        case .synced(let time): 
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last synced \(formatter.localizedString(for: time, relativeTo: Date()))"
        case .error: 
            return "Sync Error"
        }
    }
}

#Preview {
    CloudSyncPopover(monitor: CloudSyncMonitor(), isPresented: .constant(true))
        .previewLayout(.sizeThatFits)
        .padding()
}

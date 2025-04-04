import Foundation
import CoreData

/// Protocol for backup and restore operations
protocol BackupService {
    /// Creates a backup of the database
    func createBackup() async throws -> URL
    
    /// Restores from a backup file
    func restoreFromBackup(at url: URL) async throws
    
    /// Lists available backups
    func listBackups() throws -> [URL]
    
    /// Deletes a specific backup
    func deleteBackup(at url: URL) throws
}

/// Implementation of backup service using file system
final class FileSystemBackupService: BackupService {
    private let persistence: PersistenceController
    private let fileManager: FileManager
    private let backupDirectoryName = "Backups"
    
    private var backupDirectoryURL: URL? {
        return fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(backupDirectoryName, isDirectory: true)
    }
    
    init(persistence: PersistenceController = .shared, fileManager: FileManager = .default) {
        self.persistence = persistence
        self.fileManager = fileManager
        
        // Create backup directory if it doesn't exist
        Task {
            await createBackupDirectoryIfNeeded()
        }
    }
    
    private func createBackupDirectoryIfNeeded() async {
        guard let backupDirectoryURL = backupDirectoryURL else { return }
        
        if !fileManager.fileExists(atPath: backupDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true)
            } catch {
                await AppErrorHandler.shared.handle(
                    error,
                    from: "BackupService.createBackupDirectoryIfNeeded",
                    retryAction: nil
                )
            }
        }
    }
    
    func createBackup() async throws -> URL {
        guard let backupDirectoryURL = backupDirectoryURL else {
            throw AppError.generalError("Could not access backup directory")
        }
        
        // Create unique backup name with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let backupFileName = "MyNotes-Backup-\(timestamp).sqlite"
        let backupURL = backupDirectoryURL.appendingPathComponent(backupFileName)
        
        // We need to ensure we're using a clean context
        persistence.container.viewContext.reset()
        
        // Force save any pending changes
        try persistence.save()
        
        guard let storeURL = persistence.storeURL else {
            throw AppError.generalError("Could not access database store URL")
        }
        
        // Perform the copy operation
        do {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            
            try fileManager.copyItem(at: storeURL, to: backupURL)
            
            print("Backup created successfully at: \(backupURL.path)")
            return backupURL
        } catch {
            throw AppError.generalError("Failed to create backup: \(error.localizedDescription)")
        }
    }
    
    func restoreFromBackup(at url: URL) async throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw AppError.generalError("Backup file does not exist")
        }
        
        guard let storeURL = persistence.storeURL else {
            throw AppError.generalError("Could not access database store URL")
        }
        
        // We need to close the persistent store coordinator before restoring
        try persistence.closeStores()
        
        // Copy the backup file to the store location
        do {
            if fileManager.fileExists(atPath: storeURL.path) {
                try fileManager.removeItem(at: storeURL)
            }
            
            try fileManager.copyItem(at: url, to: storeURL)
            
            // Reload the persistent store
            try await persistence.reloadPersistentStores()
            
            print("Restore completed successfully from: \(url.path)")
        } catch {
            // Try to reload the stores even if restore failed
            try? await persistence.reloadPersistentStores()
            throw AppError.generalError("Failed to restore from backup: \(error.localizedDescription)")
        }
    }
    
    func listBackups() throws -> [URL] {
        guard let backupDirectoryURL = backupDirectoryURL else {
            throw AppError.generalError("Could not access backup directory")
        }
        
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: backupDirectoryURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        
        // Only include SQLite backup files
        let backupFiles = fileURLs.filter { $0.pathExtension == "sqlite" }
        
        // Sort by creation date, newest first
        return try backupFiles.sorted { (url1, url2) -> Bool in
            let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate
            let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate
            
            guard let date1 = date1, let date2 = date2 else {
                return false
            }
            
            return date1 > date2
        }
    }
    
    func deleteBackup(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw AppError.generalError("Backup file does not exist")
        }
        
        do {
            try fileManager.removeItem(at: url)
            print("Backup deleted successfully: \(url.path)")
        } catch {
            throw AppError.generalError("Failed to delete backup: \(error.localizedDescription)")
        }
    }
}

// Extension to PersistenceController to add backup-related functionality
extension PersistenceController {
    var storeURL: URL? {
        return container.persistentStoreDescriptions.first?.url
    }
    
    func closeStores() throws {
        guard let persistentStoreCoordinator = container.persistentStoreCoordinator as NSPersistentStoreCoordinator? else {
            throw AppError.persistenceError("Could not access persistent store coordinator")
        }
        
        for store in persistentStoreCoordinator.persistentStores {
            try persistentStoreCoordinator.remove(store)
        }
    }
    
    func reloadPersistentStores() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { description, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // Reset view context
                    self.container.viewContext.reset()
                    
                    // Configure the context
                    self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    self.container.viewContext.automaticallyMergesChangesFromParent = true
                    self.container.viewContext.shouldDeleteInaccessibleFaults = true
                    
                    continuation.resume()
                }
            }
        }
    }
    
    func recreatePersistentStore() async throws {
        if let storeURL = storeURL {
            try closeStores()
            
            // Remove the existing store
            try FileManager.default.removeItem(at: storeURL)
            
            // Create a new one
            try await reloadPersistentStores()
        } else {
            throw AppError.persistenceError("Could not determine store URL")
        }
    }
}

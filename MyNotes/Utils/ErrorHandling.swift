import Foundation
import CoreData

/// Enum for app errors with proper localization
enum AppError: Error, LocalizedError {
    case dataAccessError(String)
    case networkError(String)
    case persistenceError(String)
    case generalError(String)
    case corruptedDataError(String)
    case decodingError(String)
    case encodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .dataAccessError(let message):
            return "Data access error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .persistenceError(let message):
            return "Persistence error: \(message)"
        case .generalError(let message):
            return "Error: \(message)"
        case .corruptedDataError(let message):
            return "Corrupted data: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataAccessError:
            return "Try restarting the app or check your device storage."
        case .networkError:
            return "Check your internet connection and try again."
        case .persistenceError:
            return "Try restarting the app or reset the database."
        case .generalError:
            return "Please try again later."
        case .corruptedDataError:
            return "The app will try to recover automatically. You may need to restart the app."
        case .decodingError, .encodingError:
            return "Try updating the app to the latest version."
        }
    }
    
    var recoveryOptions: [String]? {
        switch self {
        case .persistenceError, .corruptedDataError:
            return ["Restart", "Reset Database", "Contact Support"]
        case .dataAccessError:
            return ["Retry", "Restart App"]
        case .networkError:
            return ["Retry", "Work Offline"]
        default:
            return ["OK"]
        }
    }
    
    /// Factory method to convert NSError to AppError
    static func from(_ error: Error) -> AppError {
        if let nsError = error as NSError? {
            // CoreData specific errors
            if nsError.domain == NSCocoaErrorDomain {
                switch nsError.code {
                case 512: // Persistent store corrupted
                    return .corruptedDataError("Store is corrupted: \(nsError.localizedDescription)")
                case 133, 134: // Can't modify immutable object, missing relationship
                    return .persistenceError("Data relationship error: \(nsError.localizedDescription)")
                default:
                    return .persistenceError("CoreData error (\(nsError.code)): \(nsError.localizedDescription)")
                }
            } else if nsError.domain == NSURLErrorDomain {
                return .networkError(nsError.localizedDescription)
            }
        }
        
        return .generalError(error.localizedDescription)
    }
}

/// Protocol for error handling
protocol ErrorHandler {
    /// Handle error and perform recovery action if possible
    func handle(_ error: Error, from source: String, retryAction: (() -> Void)?) async
    
    /// Log error for analytics
    func logError(_ error: Error, from source: String)
    
    /// Attempts recovery for CoreData errors
    func attemptCoreDataRecovery(for error: Error) async -> Bool
}

/// Concrete implementation of ErrorHandler
final class AppErrorHandler: ErrorHandler {
    static let shared = AppErrorHandler()
    
    private init() {}
    
    func handle(_ error: Error, from source: String, retryAction: (() -> Void)? = nil) async {
        let appError = AppError.from(error)
        
        // Log the error
        logError(appError, from: source)
        
        // Attempt automatic recovery for known errors
        if error is CoreDataError {
            if await attemptCoreDataRecovery(for: error) {
                print("Successfully recovered from CoreData error")
                retryAction?()
                return
            }
        }
        
        // In production, we would show UI alerts or notifications here
        // For now, we just print to console
        print("Error: \(appError.errorDescription ?? "Unknown error")")
        print("Recovery suggestion: \(appError.recoverySuggestion ?? "None")")
    }
    
    func logError(_ error: Error, from source: String) {
        // In production, we would send this to a logging service
        print("[\(source)] \(error.localizedDescription)")
        
        // Additional debug info in development
        #if DEBUG
        if let nsError = error as NSError? {
            print("Error details: Domain=\(nsError.domain), Code=\(nsError.code)")
            print("User info: \(nsError.userInfo)")
        }
        #endif
    }
    
    func attemptCoreDataRecovery(for error: Error) async -> Bool {
        guard let nsError = error as NSError? else { return false }
        
        if nsError.domain == NSCocoaErrorDomain {
            switch nsError.code {
            case 133: // Can't modify immutable object
                return true // We'll reset the context in the repository
                
            case 134: // Missing relationship
                return true // We'll reset the context in the repository
                
            case 512: // Store might be corrupted
                // Attempt recovery
                do {
                    let persistence = PersistenceController.shared
                    try await persistence.recreatePersistentStore()
                    return true
                } catch {
                    logError(error, from: "AppErrorHandler.attemptCoreDataRecovery")
                    return false
                }
                
            default:
                return false
            }
        }
        
        return false
    }
}

/// Custom CoreData errors
enum CoreDataError: Error {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case createFailed(String)
    case migrationFailed(String)
    case relationshipFailed(String)
}

/// Extension to add retry mechanism to async operations
extension Task where Failure == Error {
    /// Retry an async operation with exponential backoff
    static func retry(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = 3,
        retryDelay: TimeInterval = 1.0,
        operation: @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for attempt in 0...maxRetryCount {
                do {
                    return try await operation()
                } catch {
                    if attempt == maxRetryCount {
                        throw error
                    }
                    
                    let delay = retryDelay * pow(2.0, Double(attempt))
                    // Convert to nanoseconds and apply sleep
                    try await Task<Never, Never>.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    // Log retry attempt
                    print("Retrying operation after error: \(error.localizedDescription). Attempt \(attempt + 1)/\(maxRetryCount)")
                }
            }
            
            // This should never be reached, but Swift requires a return
            fatalError("Retry loop exited unexpectedly")
        }
    }
}

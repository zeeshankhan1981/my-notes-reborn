import Foundation
import Combine
import CoreData

/// Represents the state of a background task
enum TaskState: Equatable {
    case pending
    case running(progress: Double)
    case completed
    case failed(error: String)
    
    // For Equatable conformance
    static func == (lhs: TaskState, rhs: TaskState) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending), (.completed, .completed):
            return true
        case let (.running(lhsProgress), .running(rhsProgress)):
            return lhsProgress == rhsProgress
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// Represents a background task
struct BackgroundTask: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let createdAt: Date
    var state: TaskState
    let category: String
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        state: TaskState = .pending,
        category: String = "General"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = Date()
        self.state = state
        self.category = category
    }
}

/// Manages background tasks
final class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    @Published private(set) var tasks: [BackgroundTask] = []
    @Published private(set) var currentTasks: [BackgroundTask] = []
    
    private let operationQueue: OperationQueue
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let queue = OperationQueue()
        queue.name = "com.mynotes.backgroundTaskQueue"
        queue.maxConcurrentOperationCount = 3  // Limit concurrent operations
        self.operationQueue = queue
        
        // Use background context for operations
        self.context = PersistenceController.shared.backgroundContext
        
        // Set up observers
        setupObservers()
    }
    
    private func setupObservers() {
        // Update currentTasks whenever tasks changes
        $tasks
            .map { tasks in
                tasks.filter { task in
                    if case .completed = task.state { return false }
                    if case .failed = task.state { return false }
                    return true
                }
            }
            .assign(to: &$currentTasks)
    }
    
    /// Submits a task to be executed in the background
    func submitTask(
        name: String,
        description: String,
        category: String = "General",
        operation: @escaping () async throws -> Void
    ) -> BackgroundTask {
        let task = BackgroundTask(
            name: name,
            description: description,
            category: category
        )
        
        tasks.append(task)
        
        // Create an operation that will run the async task
        let blockOperation = BlockOperation { [weak self] in
            guard let self = self else { return }
            
            // Update state to running
            self.updateTaskState(task.id, .running(progress: 0.0))
            
            // Create a Task that will run the operation
            Task {
                do {
                    // Run the operation
                    try await operation()
                    
                    // Update state to completed
                    self.updateTaskState(task.id, .completed)
                } catch {
                    // Update state to failed
                    self.updateTaskState(task.id, .failed(error: error.localizedDescription))
                    
                    // Log the error
                    AppErrorHandler.shared.logError(
                        error,
                        from: "BackgroundTaskManager.submitTask(\(task.name))"
                    )
                }
            }
        }
        
        // Add the operation to the queue
        operationQueue.addOperation(blockOperation)
        
        return task
    }
    
    /// Updates the progress of a task
    func updateTaskProgress(_ taskID: UUID, progress: Double) {
        updateTaskState(taskID, .running(progress: progress))
    }
    
    /// Updates the state of a task
    private func updateTaskState(_ taskID: UUID, _ state: TaskState) {
        // Find the task and update its state
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let index = self.tasks.firstIndex(where: { $0.id == taskID }) else {
                return
            }
            
            // Update the task's state
            self.tasks[index].state = state
        }
    }
    
    /// Cancels all running tasks
    func cancelAllTasks() {
        operationQueue.cancelAllOperations()
        
        // Update all running tasks to failed
        for index in tasks.indices {
            if case .running = tasks[index].state {
                tasks[index].state = .failed(error: "Cancelled by user")
            }
        }
    }
    
    /// Clears completed and failed tasks
    func clearFinishedTasks() {
        tasks.removeAll { task in
            if case .completed = task.state { return true }
            if case .failed = task.state { return true }
            return false
        }
    }
    
    /// Gets a task by ID
    func getTask(id: UUID) -> BackgroundTask? {
        return tasks.first { $0.id == id }
    }
}

/// ProgressTrackable protocol for operations that can report progress
protocol ProgressTrackable {
    var progressPublisher: CurrentValueSubject<Double, Never> { get }
    var progress: Double { get }
}

/// A background operation with progress tracking
final class ProgressTrackableOperation: Operation, ProgressTrackable, @unchecked Sendable {
    let progressPublisher = CurrentValueSubject<Double, Never>(0.0)
    private(set) var progress: Double = 0.0 {
        didSet {
            progressPublisher.send(progress)
        }
    }
    
    private let work: (ProgressTrackable) -> Void
    
    init(work: @escaping (ProgressTrackable) -> Void) {
        self.work = work
        super.init()
    }
    
    override func main() {
        // Check if the operation was cancelled before starting
        guard !isCancelled else { return }
        
        // Execute the work
        work(self)
    }
    
    /// Updates the progress of the operation
    func updateProgress(_ newProgress: Double) {
        progress = max(0.0, min(1.0, newProgress))
    }
}

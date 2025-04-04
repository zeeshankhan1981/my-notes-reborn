import Foundation

/// Protocol for note caching
protocol NoteCache {
    /// Caches a note
    func cache(_ note: Note)
    
    /// Retrieves a cached note by ID
    func get(_ id: UUID) -> Note?
    
    /// Removes a note from cache
    func remove(_ id: UUID)
    
    /// Clears all cached notes
    func clear()
}

/// Implementation of NoteCache using UserDefaults
final class UserDefaultsNoteCache: NoteCache {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func cache(_ note: Note) {
        do {
            let data = try encoder.encode(note)
            userDefaults.set(data, forKey: note.id.uuidString)
        } catch {
            print("Error caching note: \(error)")
        }
    }
    
    func get(_ id: UUID) -> Note? {
        guard let data = userDefaults.data(forKey: id.uuidString) else { return nil }
        
        do {
            return try decoder.decode(Note.self, from: data)
        } catch {
            print("Error retrieving cached note: \(error)")
            return nil
        }
    }
    
    func remove(_ id: UUID) {
        userDefaults.removeObject(forKey: id.uuidString)
    }
    
    func clear() {
        let noteIDs = userDefaults.dictionaryRepresentation()
            .keys
            .filter { $0.contains("-") } // UUID contains hyphens
        
        noteIDs.forEach { userDefaults.removeObject(forKey: $0) }
    }
}

/// Cache wrapper that provides thread-safe access
final class ThreadSafeNoteCache: NoteCache {
    private let cache: NoteCache
    private let queue = DispatchQueue(label: "com.mynotes.cache", qos: .userInitiated)
    
    init(cache: NoteCache) {
        self.cache = cache
    }
    
    func cache(_ note: Note) {
        queue.async {
            self.cache.cache(note)
        }
    }
    
    func get(_ id: UUID) -> Note? {
        var result: Note?
        queue.sync {
            result = self.cache.get(id)
        }
        return result
    }
    
    func remove(_ id: UUID) {
        queue.async {
            self.cache.remove(id)
        }
    }
    
    func clear() {
        queue.async {
            self.cache.clear()
        }
    }
}

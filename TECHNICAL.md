# MyNotes - Technical Documentation

## Architecture Overview

MyNotes follows a clean architecture pattern with the following main components:

### 1. Models
- `Note`: Represents a text note with title, content, image, and folder association
- `ChecklistNote`: Represents a checklist with items and folder association
- `ChecklistItem`: Individual items within a checklist
- `Folder`: Container for organizing notes and checklists

### 2. ViewModels
- `NoteStore`: Manages note-related operations
- `ChecklistStore`: Manages checklist-related operations
- `FolderStore`: Manages folder-related operations

### 3. Views
- `MainView`: Tab-based navigation between Notes, Checklists, and Folders
- `NoteListView`: Displays list of notes with swipe actions
- `NoteEditorView`: Edit/create notes with rich text capabilities
- `ChecklistListView`: Displays list of checklists
- `ChecklistEditorView`: Edit/create checklists with item management
- `FolderManagerView`: Manage folders and organization

## Core Data Implementation

### Data Model
The app uses Core Data for persistent storage with the following entities:

#### CDNote
- Properties:
  - id (UUID)
  - title (String)
  - content (String)
  - imageData (Binary)
  - isPinned (Boolean)
  - date (Date)
- Relationships:
  - folder (to-one relationship with CDFolder)

#### CDChecklistNote
- Properties:
  - id (UUID)
  - title (String)
  - isPinned (Boolean)
  - date (Date)
- Relationships:
  - folder (to-one relationship with CDFolder)
  - items (to-many relationship with CDChecklistItem)

#### CDChecklistItem
- Properties:
  - id (UUID)
  - text (String)
  - isDone (Boolean)
- Relationships:
  - checklist (to-one relationship with CDChecklistNote)

#### CDFolder
- Properties:
  - id (UUID)
  - name (String)
- Relationships:
  - notes (to-many relationship with CDNote)
  - checklists (to-many relationship with CDChecklistNote)

### Persistence Management
- `PersistenceController`: Manages the Core Data stack
- Automatic saving on context changes
- Proper error handling for data operations
- Efficient fetching with sort descriptors and predicates
- Test data generation for development
- Environment validation

## SwiftUI Implementation

### View Architecture
- Uses SwiftUI's declarative syntax for UI
- Follows MVVM pattern with clear separation of concerns
- Uses environment objects for state management
- Implements custom gestures and animations
- Enhanced debug logging

### State Management
- Uses `@StateObject` for view model lifetime management
- Uses `@Published` for reactive state updates
- Implements proper memory management with weak references
- Separates creation from selection modes

## UI Improvements

### Navigation
- Tab-based navigation between Notes, Checklists, and Folders
- Dedicated + button for quick creation
- Separated selection mode from creation
- Enhanced visual feedback

### Components
- Custom note and checklist cards
- Swipe-to-delete functionality
- Pinned items support
- Search integration
- Test data display

## Debugging and Development

### Debug Tools
- Comprehensive debug logging
- Core Data operation monitoring
- Environment validation
- Test data generation
- Memory usage tracking

### Performance
- Efficient data fetching
- Optimized animations
- Memory management
- Lazy loading of content

## Code Organization

### Directory Structure
```
MyNotes/
├── Models/           # Data models
├── ViewModels/       # View models and business logic
├── Views/           # SwiftUI views
├── CoreData/         # Core Data implementation
└── Assets.xcassets/ # App assets
```

### File Naming Conventions
- Models: PascalCase (e.g., `Note.swift`)
- ViewModels: PascalCase + Store suffix (e.g., `NoteStore.swift`)
- Views: PascalCase (e.g., `NoteListView.swift`)
- CoreData: PascalCase with CD prefix (e.g., `CDNote.swift`)

## Performance Considerations

### Memory Management
- Uses weak references to prevent retain cycles
- Proper cleanup of resources in view lifecycle
- Efficient image handling with proper caching

### Data Fetching
- Implements batch fetching for large datasets
- Uses proper sort descriptors for consistent ordering
- Implements caching for frequently accessed data

### UI Performance
- Uses `List` with proper row configuration
- Implements lazy loading for images
- Uses efficient animations with proper timing

## Testing Strategy

### Unit Tests
- Tests for business logic in view models
- Tests for Core Data operations
- Tests for model transformations

### UI Tests
- Tests for view hierarchy
- Tests for user interactions
- Tests for state management

## Future Improvements

### Planned Features
1. Rich Text Editing
   - Bold, italic, underline text formatting
   - Lists and bullet points
   - Text styling options

2. Search Functionality
   - Full-text search across notes and checklists
   - Search within folders
   - Advanced filtering options

3. Tags System
   - Add tags to notes and checklists
   - Filter by tags
   - Tag management interface

4. iCloud Sync
   - Cross-device synchronization
   - Conflict resolution
   - Offline support

5. Dark Mode Optimization
   - Dynamic color system
   - Theme-aware UI components
   - System appearance integration

6. Widgets
   - Home screen widgets for quick access
   - Widget customization
   - Dynamic content updates

7. Sharing and Export
   - Note sharing capabilities
   - Export to various formats
   - Cloud export options

8. Quick Actions
   - 3D Touch shortcuts
   - Quick note creation
   - Quick checklist creation

## Technical Debt

### Current Issues
1. Core Data Migration Strategy
   - Need proper versioning for future schema changes
   - Migration handlers for data transformations

2. Error Handling
   - Need more comprehensive error handling
   - Better user feedback for failed operations

3. Performance Optimization
   - Need profiling for slow operations
   - Memory usage optimization

4. Code Organization
   - Some view models could be split for better maintainability
   - Shared components could be extracted

## Development Guidelines

### Code Style
- Follow Swift style guide
- Use meaningful variable names
- Keep functions focused and small
- Document complex logic

### Commit Messages
- Use conventional commits
- Clear and descriptive messages
- Reference issues when applicable

### Pull Requests
- Small, focused changes
- Proper testing
- Documentation updates
- Code review required

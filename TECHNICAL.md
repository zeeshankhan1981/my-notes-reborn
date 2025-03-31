# MyNotes - Technical Documentation

## Architecture Overview

MyNotes follows a clean architecture pattern with the following main components:

### 1. Models
- `Note`: Represents a text note with title, content, image, and folder association
- `ChecklistNote`: Represents a checklist with items and folder association
- `ChecklistItem`: Individual items within a checklist
- `Folder`: Container for organizing notes and checklists
- `Tag`: Categorization system for notes and checklists

### 2. ViewModels
- `NoteStore`: Manages note-related operations
- `ChecklistStore`: Manages checklist-related operations
- `FolderStore`: Manages folder-related operations
- `TagStore`: Manages tags and their relationships

### 3. Views
- `MainView`: Tab-based navigation between Notes, Checklists, and Folders
- `NoteListView`: Displays list of notes with swipe actions and filtering
- `NoteEditorView`: Edit/create notes with rich text capabilities
- `ChecklistListView`: Displays list of checklists with filtering
- `ChecklistEditorView`: Edit/create checklists with item management
- `FolderManagerView`: Manage folders and organization
- `TagManagementView`: Tag creation and management
- `TagSelectorView`: Tag selection interface
- `TagFilterView`: Tag-based filtering interface

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
  - tags (to-many relationship with CDTags)

#### CDChecklistNote
- Properties:
  - id (UUID)
  - title (String)
  - isPinned (Boolean)
  - date (Date)
- Relationships:
  - folder (to-one relationship with CDFolder)
  - items (to-many relationship with CDChecklistItem)
  - tags (to-many relationship with CDTags)

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

#### CDTags
- Properties:
  - id (UUID)
  - name (String)
  - color (String)
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

### UI Components
- Custom typography system with monospaced fonts
- Consistent theming across the app
- Minimalist design inspired by iA Writer
- Custom layout components
- Reusable UI elements

### Performance Optimizations
- Lazy loading of content
- Efficient list rendering
- Optimized image handling
- Memory management

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

## Recent Changes (v0.2.3)

### Search System Improvements
- Streamlined search experience:
  - Removed redundant search options from dropdown menus
  - Standardized search icon in toolbar across all views
  - Enhanced SearchBarView with:
    - Clear visual feedback for active searches
    - Character count display
    - Haptic feedback on focus
    - Search status messages
  - Implemented consistent search behavior across notes and checklists

### UI/UX Improvements
- Swipe functionality:
  - Implemented proper swipe-to-delete in NoteListView and ChecklistListView
  - Removed duplicate swipe actions from NoteCardView and ChecklistCardView
  - Added consistent swipe behavior across all list views
  - Enhanced visual feedback for swipe actions
- Visual consistency:
  - Standardized toolbar icons and actions
  - Improved spacing and layout in list views
  - Added proper visual separators in search bar

### Performance Optimizations
- Removed custom SwipeableCardView component for better reliability
- Simplified swipe action implementation using native SwiftUI
- Enhanced search bar performance with optimized text handling

## Recent Changes (v0.2.2)

### UI/UX Enhancements
- Implemented consistent UI across Note and Checklist editors
- Created standardized button styles for navigation actions
- Added consistent form field styling with icons
- Improved visual hierarchy and spacing
- Fixed build error with missing isRichTextEditorAvailable() function
- Enhanced navigation bar consistency

## Recent Changes (v0.2.1)

### Search System Improvements
- Created a unified search architecture:
  - `SearchService`: Core service for managing search operations
  - `SearchBarView`: Reusable UI component to maintain consistency
  - `GlobalSearchView`: App-wide search implementation
- Added proper search result handling with categorization
- Fixed binding and type errors in search implementation
- Enhanced store classes with item retrieval methods

### UI/UX Enhancements
- Consistent search experience across Notes and Checklists views
- Added global search button in MainView
- Implemented visual feedback for search actions
- Created search result card design with proper visual hierarchy
- Added animations and haptic feedback to improve user experience

## Recent Changes (v0.2.0)

### Core Data Improvements
- Fixed UUID casting issues in predicates
- Improved tag relationship handling
- Enhanced error handling in model-to-CDNote conversion
- Added proper UUID string conversion for Core Data queries

### UI/UX Improvements
- Moved checklist creation button to top-right toolbar for consistency
- Fixed layout constraint warnings
- Improved visual hierarchy and spacing

## Recent Changes (v0.1.9)

### Bug Fixes
- Fixed complex type-checking issues in ChecklistEditorView
- Added missing theme colors (danger, selectedRowBackground)
- Updated iOS 17 onChange syntax compatibility
- Fixed animation and binding issues
- Removed duplicate component declarations

### New Features
- Added new UI components (AnimatedCheckbox, ButtonStyles, Layouts)
- Updated tag selection system to use FlowLayout

## Recent Changes (v0.1.7)

### UI Improvements
- Fixed spacing issues in ChecklistListView
- Removed redundant empty state checks
- Improved checklist grid layout
- Better visual hierarchy with proper spacing
- Enhanced scroll performance

### Code Quality
- Improved code organization
- Better error handling
- Enhanced documentation
- Consistent API usage
- Enhanced testing coverage

## Recent Changes (v0.1.6)

### Core Data Optimizations
- Fixed NoteStore implementation to match original structure
- Maintained Core Data performance improvements
- Restored type safety in Note model
- Fixed parameter order and type conversions
- Preserved original functionality while fixing errors

### Performance
- Optimized data fetching
- Improved memory management
- Enhanced error recovery
- Better background processing
- Improved UI responsiveness

## Recent Changes (v0.1.5)

### Typography System
- Implemented function-based Typography API
- Consistent monospaced font usage
- Improved typography measurements
- Better font size and weight management

### UI Improvements
- Redesigned editor to match iA Writer's aesthetic
- Enhanced formatting toolbar with SF Symbols
- Improved visual feedback for actions
- Better color picker integration
- Consistent spacing and layout

### Code Quality
- Fixed duplicate view declarations
- Improved error handling
- Better code organization
- Consistent API usage
- Enhanced documentation

## UI Improvements (v0.1.2)

### Editor Views
- Fixed rich text editor formatting toolbar visibility and functionality
- Improved layout consistency across note and checklist editors
- Removed unwanted spacing at the top of editor views
- Enhanced visual hierarchy with proper spacing and typography
- Added smooth transitions for formatting toolbar

### List Views
- Fixed unwanted space above notes in list view
- Improved search bar and tag filter transitions
- Enhanced grid layout for notes and checklists
- Added proper safe area handling

### Component Improvements
- Standardized padding and spacing across all views
- Improved background color consistency
- Enhanced card-based UI components
- Added proper corner radiuses and shadows

### Technical Changes
- Removed deprecated `onChange(of:perform:)` usage
- Fixed initializer mismatches between views and stores
- Improved state management for formatting tools
- Enhanced animation handling for UI transitions

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
- Rich text editor with formatting options
- Tag filtering interface
- Tag selection in editors

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

## Version History

### v0.2.3 (2025-04-02)
- Implemented swipe-to-delete functionality for notes and checklists
- Added consistent swipe behavior across all list views
- Fixed ChecklistStore update method calls
- Improved error handling in Core Data operations
- Enhanced type safety in model updates

### v0.2.2 (2025-04-01)
- Implemented consistent UI across Note and Checklist editors
- Created standardized button styles for navigation actions
- Added consistent form field styling with icons
- Improved visual hierarchy and spacing
- Fixed build error with missing isRichTextEditorAvailable() function
- Enhanced navigation bar consistency

### v0.2.1 (2025-03-30)
- Implemented robust search functionality across the app
- Added unified global search capabilities
- Created consistent search UI between Notes and Checklists
- Fixed UI component errors in search implementation
- Enhanced store classes with proper item retrieval methods

### v0.2.0 (2025-04-01)
- Fixed UUID casting issues in predicates
- Improved tag relationship handling
- Enhanced error handling in model-to-CDNote conversion
- Added proper UUID string conversion for Core Data queries
- Moved checklist creation button to top-right toolbar for consistency
- Fixed layout constraint warnings
- Improved visual hierarchy and spacing

### v0.1.9 (2025-03-30)
- Fixed complex type-checking issues in ChecklistEditorView
- Added missing theme colors (danger, selectedRowBackground)
- Updated iOS 17 onChange syntax compatibility
- Fixed animation and binding issues
- Removed duplicate component declarations
- Added new UI components (AnimatedCheckbox, ButtonStyles, Layouts)
- Updated tag selection system to use FlowLayout

### v0.1.1 (2025-03-30)
- Added tag filtering system
- Enhanced rich text editor
- Fixed RichTextEditor compile-time errors
- Added tag management UI components
- Updated list views with filtering capabilities

### v0.1.0 (2025-03-29)
- Initial release with basic note-taking functionality
- Core Data integration
- Basic UI components
- Folder management system

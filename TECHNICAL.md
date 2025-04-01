# MyNotes - Technical Documentation

## Architecture Overview

MyNotes follows a clean architecture pattern with the following main components:

### 1. Models
- `Note`: Represents a text note with title, content, image, and folder association
- `ChecklistNote`: Represents a checklist with items and folder association
- `ChecklistItem`: Individual items within a checklist
- `Folder`: Container for organizing notes and checklists
- `Tag`: Categorization system for notes and checklists
- `Theme`: Color and typography system

### 2. Store Classes
- `NoteStore`: Manages note-related operations
  - CRUD operations for notes
  - Tag management
  - Folder organization
  - Search functionality
- `ChecklistStore`: Manages checklist-related operations
  - CRUD operations for checklists
  - Item management
  - Tag integration
  - Selection mode
- `FolderStore`: Manages folder-related operations
  - Folder creation and deletion
  - Note organization
  - Drag and drop
- `TagStore`: Manages tags and their relationships
  - Tag creation and deletion
  - Color management
  - Filtering

### 3. Views
- `MainView`: Tab-based navigation between Notes and Checklists
- `NoteListView`: Displays list of notes with filtering and selection mode
- `NoteEditorView`: Edit/create notes with rich text capabilities
- `ChecklistListView`: Displays list of checklists with filtering and selection mode
- `ChecklistEditorView`: Edit/create checklists with item management
- `TagManagementView`: Tag creation and management
- `TagFilterView`: Tag-based filtering interface
- `SearchBarView`: Unified search interface

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
  - attributedContent (Binary)
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
- Clean, minimalist UI design

### UI Components
- `NoteCardView`: Consistent note display with selection support
- `ChecklistCardView`: Consistent checklist display with selection support
- `SearchBarView`: Unified search interface
- `TagFilterView`: Tag-based filtering
- `TagSelectorView`: Tag selection interface
- `ButtonStyles`: Standardized button styles
- `Typography`: Consistent typography system

### State Management
- Uses SwiftUI's State and Binding system
- Environment objects for global state
- Proper state lifting for complex components
- Efficient state updates with Combine

### Animations & Transitions
- Smooth list transitions
- Consistent button feedback
- Proper gesture recognition
- Smooth state changes

### Error Handling
- Comprehensive error handling in Core Data operations
- User-friendly error messages
- Proper recovery mechanisms
- Logging for debugging

## Recent Technical Improvements

### Core Data
- Fixed model conflicts in ModelExtensions.swift
- Aligned property names with Core Data model
- Improved relationship handling
- Enhanced error handling

### UI/UX
- Implemented consistent selection mode across views
- Enhanced delete functionality with proper animations
- Improved tag filter implementation
- Standardized toolbar layout
- Enhanced search bar functionality

### Performance
- Optimized list view rendering
- Efficient Core Data fetching
- Reduced memory usage
- Improved animation performance

### Code Quality
- Fixed merge conflicts
- Improved code organization
- Enhanced type safety
- Better error handling
- More comprehensive testing

## Future Improvements

### Core Data
- Implement batch operations for better performance
- Add data migration support
- Enhance error recovery
- Add background processing

### UI/UX
- Add dark mode support
- Improve accessibility
- Enhance animations
- Add more visual feedback

### Performance
- Implement caching strategies
- Optimize data fetching
- Reduce memory footprint
- Improve startup time

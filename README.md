# MyNotes

A modern, minimalist note-taking app built with SwiftUI and Core Data, inspired by iA Writer's clean design.

## Features

- 📝 Rich Text Editing
  - Clean, distraction-free writing experience
  - Monospaced font for better focus
  - Minimal formatting tools (bold, italic, underline)
  - Text color customization
  - Link insertion
  - Custom font sizes
  - Text alignment (left, center, right)

- 🏷️ Tag Management
  - Create and manage tags with custom colors
  - Filter notes and checklists by tags
  - Quick tag selection in editor
  - Tag-based organization

- 📋 Checklist Management
  - Create and edit checklists
  - Task completion tracking
  - Rich text formatting in checklists
  - Tag support for checklists
  - Clean, minimal UI with no unnecessary spacing

- 📁 Folder Organization
  - Organize notes into folders
  - Drag and drop folder management
  - Nested folder support

- 🔍 Search Functionality
  - Consistent search UI with a single search icon in toolbar
  - Real-time search with visual feedback
  - Character count display
  - Haptic feedback on focus
  - Unified search experience across notes and checklists
  - Clear search status messages

- 💾 Data Persistence
  - Core Data integration
  - Local data storage
  - Automatic backups

## Installation

1. Clone the repository
2. Open `MyNotes.xcodeproj` in Xcode
3. Build and run the project

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Version History

### v0.2.3 (2025-03-31)
- Streamlined search experience:
  - Removed redundant search options
  - Standardized search icon in toolbar
  - Enhanced SearchBarView with visual feedback and haptic feedback
- Improved swipe functionality:
  - Implemented proper swipe-to-delete in NoteListView and ChecklistListView
  - Removed duplicate swipe actions from card views
  - Added consistent swipe behavior across all list views
- UI/UX improvements:
  - Added character count display in search bar
  - Improved visual consistency across the app
  - Enhanced search status messages

### v0.2.2 (2025-03-31)
- Implemented UI consistency across Note and Checklist editors
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

### v0.2.0 (2025-03-30)
- Fixed UUID casting issues in Core Data predicates
- Moved checklist creation button to top-right toolbar for consistency
- Improved tag relationship handling in Core Data
- Fixed layout constraint warnings
- Enhanced error handling in model-to-CDNote conversion

### v0.1.9 (2025-03-30)
- Fixed complex type-checking issues in ChecklistEditorView
- Added missing theme colors (danger, selectedRowBackground)
- Updated iOS 17 onChange syntax compatibility
- Fixed animation and binding issues
- Removed duplicate component declarations
- Added new UI components (AnimatedCheckbox, ButtonStyles, Layouts)
- Updated tag selection system to use FlowLayout

### v0.1.7 (2025-03-30)
- Fixed UI spacing issues in ChecklistListView
- Removed redundant empty state checks
- Improved checklist grid layout
- Better visual hierarchy with proper spacing
- Enhanced scroll performance

### v0.1.6 (2025-03-30)
- Fixed NoteStore implementation to match original structure
- Maintained Core Data performance improvements
- Restored type safety in Note model
- Fixed parameter order and type conversions
- Preserved original functionality while fixing errors

### v0.1.5 (2025-03-30)
- Redesigned UI to match iA Writer's minimalist aesthetic
- Implemented consistent monospaced typography throughout the app
- Enhanced typography system with proper function-based API
- Fixed Typography-related compile-time errors
- Improved code organization and consistency

### v0.1.4 (2025-03-30)
- Added tag filtering system for notes and checklists
- Enhanced rich text editor with new formatting options
- Fixed RichTextEditor compile-time errors
- Added tag management UI components
- Updated list views with filtering capabilities

### v0.1.3 (2025-03-29)
- Initial release with basic note-taking functionality
- Core Data integration
- Basic UI components
- Folder management system

# MyNotes

A modern, minimalist note-taking app built with SwiftUI and Core Data, designed for focused writing and task management.

## Features

### Note Management
- 📝 Rich Text Editing
  - Clean, distraction-free writing experience
  - Monospaced font for better focus
  - Minimal formatting tools (bold, italic, underline)
  - Text color customization
  - Link insertion
  - Custom font sizes
  - Text alignment (left, center, right)

- 📁 Folder Organization
  - Organize notes into folders
  - Drag and drop folder management
  - Nested folder support

### Checklist Management
- 📋 Task Management
  - Create and edit checklists
  - Task completion tracking
  - Rich text formatting in checklists
  - Tag support for checklists
  - Clean, minimal UI with no unnecessary spacing

### Tag Management
- 🏷️ Categorization
  - Create and manage tags with custom colors
  - Filter notes and checklists by tags
  - Quick tag selection in editor
  - Tag-based organization

### Search & Filtering
- 🔍 Advanced Search
  - Consistent search UI with a single search icon in toolbar
  - Real-time search with visual feedback
  - Character count display
  - Haptic feedback on focus
  - Unified search experience across notes and checklists
  - Clear search status messages

### UI/UX
- 🎨 Modern Design
  - Clean, minimalist interface
  - Consistent visual language
  - Smooth animations and transitions
  - Thoughtful use of whitespace
  - Intuitive navigation

## Installation

1. Clone the repository
2. Open `MyNotes.xcodeproj` in Xcode
3. Build and run the project

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Version History

### v0.2.6 (2025-03-31)
- UI improvements:
  - Fixed Core Data model conflicts
  - Improved selection mode UI in both Notes and Checklists views
  - Consistent toolbar layout across all views
  - Enhanced delete functionality with proper animations
  - Improved tag filter and search bar implementations

### v0.2.5 (2025-03-31)
- UI improvements:
  - Clean, minimalist cloud icon design
  - Consistent placement in navigation bar
  - Smooth animations for popover transitions
  - Haptic feedback for better user experience

### v0.2.4 (2025-03-31)
- Simplified search interface:
  - Removed redundant floating search button from MainView
  - Maintained single search icon in toolbar
  - Improved visual consistency across the app

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

### v0.2.1 (2025-03-31)
- Added tag management UI components
- Updated list views with filtering capabilities

### v0.1.3 (2025-03-29)
- Initial release with basic note-taking functionality

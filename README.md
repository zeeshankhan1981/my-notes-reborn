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
  - Satisfying completion animations
  - Priority levels for better task management

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
  - Core Data integration with robust error handling
  - Local data storage with batch operations
  - Automatic backups
  - Safe deletion with recovery mechanisms

- 🎨 UI & Accessibility
  - Dark mode support with consistent appearance
  - Dynamic typography adapting to system settings
  - Haptic feedback for important actions
  - Proper accessibility labels and traits
  - Consistent spacing and visual hierarchy
- 🚀 Todoist-Inspired UI Enhancements
  - Task completion animations with haptic feedback
  - Engaging empty state designs with illustrations
  - Priority visualization (none, low, medium, high)
  - Interactive priority selector
  - Animated strikethrough text for completed items

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

### v0.3.2 (2025-04-01)
- Fixed UI inconsistencies and critical functionality:
  - Enhanced dark mode support with dynamic colors
  - Fixed Settings screen layout and removed excessive blank space
  - Improved Core Data deletion functionality with error handling
  - Added batch deletion for better performance
  - Enhanced accessibility throughout the app
  - Added proper UI feedback via haptics

### v0.3.1 (2025-04-01)
- Improved swipe actions:
  - Added consistent swipe-to-delete functionality
  - Implemented swipe-to-pin notes and checklists
  - Enhanced visual feedback during swipe actions
  - Added haptic feedback for improved user experience

### v0.2.6 (2025-04-01)
- Fixed critical issues:
  - Resolved build error in SettingsView with incorrect header implementation
  - Updated project configuration to be iPhone-only
  - Fixed app icon warnings in asset catalog
  - Improved settings page functionality with working export/import buttons
  - Enhanced overall app stability and reliability

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

### v0.2.2 (2025-03-30)
- Design system improvements:
  - Modernized button styles for improved touch targets
  - Enhanced visual feedback for interactive elements
  - Improved contrast in selection states
  - Standardized padding and spacing metrics
  - Better responsiveness in list views

### v0.2.1 (2025-03-30)
- Fixed formatting toolbar issues:
  - Replaced custom icons with SF Symbols
  - Improved toolbar layout with better spacing
  - Added haptic feedback for formatting actions
  - Enhanced color picker with better UI
  - Fixed toolbar appearance in landscape mode

### v0.2.0 (2025-03-30)
- New design system implementation:
  - Modernized color palette with semantic naming
  - Enhanced typography system for better hierarchy
  - Simplified spacing system with consistent rules
  - Improved component styling
  - Better dark mode support

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

Test

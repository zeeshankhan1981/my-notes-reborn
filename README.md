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
  - Full-text search across notes and checklists
  - Tag-based filtering
  - Real-time search results

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

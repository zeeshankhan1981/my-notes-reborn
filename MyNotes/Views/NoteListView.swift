import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var showingAdd = false
    @State private var selectedNote: Note?
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            List {
                ForEach(noteStore.notes.sorted { $0.isPinned && !$1.isPinned }) { note in
                    Button {
                        selectedNote = note
                        isEditing = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(note.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if note.isPinned {
                                    Image(systemName: "pin.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                                
                                Spacer()
                            }
                            
                            Text(note.content)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                            
                            Text(note.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            noteStore.delete(note: note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            noteStore.togglePin(note: note)
                        } label: {
                            Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                        }
                        .tint(.yellow)
                    }
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                Button(action: {
                    selectedNote = nil
                    showingAdd = true
                }) {
                    Label("Add Note", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAdd) {
                NoteEditorView(mode: .new, existingNote: nil)
            }
            .sheet(isPresented: $isEditing) {
                if let note = selectedNote {
                    NoteEditorView(mode: .edit, existingNote: note)
                }
            }
        }
    }
}
import SwiftUI

struct ChecklistListView: View {
    @EnvironmentObject var checklistStore: ChecklistStore
    @State private var showingAdd = false
    @State private var selectedChecklist: ChecklistNote?
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            List {
                ForEach(checklistStore.checklists.sorted { $0.isPinned && !$1.isPinned }) { checklist in
                    Button {
                        selectedChecklist = checklist
                        isEditing = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(checklist.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if checklist.isPinned {
                                    Image(systemName: "pin.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                                
                                Spacer()
                            }
                            
                            Text("\(checklist.items.filter { $0.isDone }.count)/\(checklist.items.count) complete")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(checklist.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            checklistStore.delete(note: checklist)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            checklistStore.togglePin(note: checklist)
                        } label: {
                            Label(checklist.isPinned ? "Unpin" : "Pin", systemImage: checklist.isPinned ? "pin.slash" : "pin")
                        }
                        .tint(.yellow)
                    }
                }
            }
            .navigationTitle("Checklists")
            .toolbar {
                Button(action: {
                    selectedChecklist = nil
                    showingAdd = true
                }) {
                    Label("Add Checklist", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAdd) {
                ChecklistEditorView(mode: .new, existingChecklist: nil)
            }
            .sheet(isPresented: $isEditing) {
                if let checklist = selectedChecklist {
                    ChecklistEditorView(mode: .edit, existingChecklist: checklist)
                }
            }
        }
    }
}
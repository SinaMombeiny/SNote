import SwiftUI
import CppHello
import AppKit

@main
struct HelloApp: App {
    @StateObject private var store = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var modifiedAt: Date

    init(id: UUID = UUID(), title: String = "", body: String = "", modifiedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.body = body
        self.modifiedAt = modifiedAt
    }
}

@MainActor
final class NoteStore: ObservableObject {
    @Published var notes: [Note] {
        didSet { save() }
    }

    private let storageKey = "SNote.notes"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Note].self, from: data) {
            notes = saved
        } else {
            let cppTitle = SNoteCpp.defaultTitle()
            let title = cppTitle.map { String(cString: $0) } ?? "Welcome"
            notes = [Note(title: title, body: "Start writing your note here.")]
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func addNote() {
        let note = Note(title: "New Note", modifiedAt: Date())
        notes.insert(note, at: 0)
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
    }
}

struct ContentView: View {
    @ObservedObject var store: NoteStore
    @State private var selection: Note.ID?
    @State private var searchText = ""

    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return store.notes
        }
        return store.notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(.yellow)
                    Text("Notes")
                        .font(.headline)
                    Spacer()
                    Button(action: store.addNote) {
                        Image(systemName: "square.and.pencil")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                List(selection: $selection) {
                    ForEach(filteredNotes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title.isEmpty ? "New Note" : note.title)
                                .font(.headline)
                                .lineLimit(1)
                            Text(note.body.isEmpty ? "No additional text" : note.body)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        .tag(note.id)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.delete(filteredNotes[index])
                        }
                    }
                }
                .listStyle(.sidebar)
                .searchable(text: $searchText, placement: .sidebar)
            }
            .frame(minWidth: 220)
        } detail: {
            if let selectedID = selection,
               let index = store.notes.firstIndex(where: { $0.id == selectedID }) {
                EditorView(note: Binding(
                    get: { store.notes[index] },
                    set: { updated in
                        store.notes[index] = updated
                        store.notes[index].modifiedAt = Date()
                    }
                ))
            } else if let first = store.notes.first {
                EditorView(note: Binding(
                    get: { first },
                    set: { updated in
                        if let index = store.notes.firstIndex(where: { $0.id == updated.id }) {
                            store.notes[index] = updated
                            store.notes[index].modifiedAt = Date()
                        }
                    }
                ))
            } else {
                VStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 52))
                        .foregroundStyle(.tertiary)
                    Text("No Note Selected")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 760, minHeight: 500)
        .task {
            if selection == nil {
                selection = store.notes.first?.id
            }
        }
        .background(WindowAccessor())
    }
}

struct EditorView: View {
    @Binding var note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $note.title)
                .font(.title)
                .bold()
                .textFieldStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 12)

            TextEditor(text: $note.body)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

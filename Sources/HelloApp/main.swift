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
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
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
            let title = cppTitle.map { String(cString: $0) } ?? "draft.txt"
            notes = [Note(title: title, body: "")]
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

    var body: some View {
        EditorView(note: Binding(
            get: { store.notes.first ?? Note(title: "draft.txt") },
            set: { updated in
                if store.notes.isEmpty {
                    store.notes = [updated]
                } else {
                    store.notes[0] = updated
                    store.notes[0].modifiedAt = Date()
                }
            }
        ))
        .frame(minWidth: 760, minHeight: 500)
        .preferredColorScheme(.dark)
        .background(WindowAccessor())
    }
}

struct EditorView: View {
    @Binding var note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextEditor(text: $note.body)
                .font(.custom("SFMono-Regular", size: 13))
                .foregroundStyle(Color(red: 0.80, green: 0.84, blue: 0.88))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 40)
                .padding(.vertical, 34)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
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
            window.backgroundColor = .black
            window.isOpaque = true
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

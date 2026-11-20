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
}

struct ContentView: View {
    @ObservedObject var store: NoteStore

    private var note: Binding<Note> {
        Binding(
            get: { store.notes.first ?? Note(title: "Untitled") },
            set: { updated in
                if store.notes.isEmpty {
                    store.notes = [updated]
                } else {
                    store.notes[0] = updated
                    store.notes[0].modifiedAt = Date()
                }
            }
        )
    }

    var body: some View {
        EditorView(note: note)
            .frame(minWidth: 700, minHeight: 480)
            .preferredColorScheme(.dark)
            .background(WindowAccessor())
    }
}

struct EditorView: View {
    @Binding var note: Note

    private let ink = Color(red: 0.86, green: 0.86, blue: 0.84)

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                TextField("Untitled", text: $note.title)
                    .font(.custom("Menlo-Bold", size: 16))
                    .foregroundStyle(ink)
                    .textFieldStyle(.plain)
                    .padding(.bottom, 2)

                TextEditor(text: $note.body)
                    .font(.custom("Menlo-Regular", size: 13))
                    .lineSpacing(4)
                    .foregroundStyle(ink)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, -5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Document text")
            }
            .frame(width: min(geometry.size.width - 100, 760), height: geometry.size.height - 100, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 52)
            .background(Color(red: 0.035, green: 0.04, blue: 0.055))
        }
        .background(Color(red: 0.035, green: 0.04, blue: 0.055))
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
            window.backgroundColor = NSColor(red: 0.035, green: 0.04, blue: 0.055, alpha: 1)
            window.isOpaque = true
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

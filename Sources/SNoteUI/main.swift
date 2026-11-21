import SwiftUI
import SNoteCore
import AppKit

@main
struct SNoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
    }
}

struct ContentView: View {
    @State private var title = ""
    @State private var documentText = ""
    @State private var pendingSave: Task<Void, Never>?

    var body: some View {
        EditorView(title: $title, documentText: $documentText)
            .frame(minWidth: 700, minHeight: 480)
            .preferredColorScheme(.dark)
            .background(WindowAccessor())
            .onAppear {
                SNoteCore.initialize()
                if let titlePointer = SNoteCore.title() {
                    title = String(cString: titlePointer)
                }
                if let bodyPointer = SNoteCore.body() {
                    documentText = String(cString: bodyPointer)
                }
            }
            .onChange(of: title) { newValue in
                SNoteCore.setTitle(newValue)
                scheduleSave()
            }
            .onChange(of: documentText) { newValue in
                SNoteCore.setBody(newValue)
                scheduleSave()
            }
            .onDisappear {
                pendingSave?.cancel()
                SNoteCore.save()
            }
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        pendingSave = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            SNoteCore.save()
        }
    }
}

struct EditorView: View {
    @Binding var title: String
    @Binding var documentText: String

    private let ink = Color(red: 0.86, green: 0.86, blue: 0.84)

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                TextField("Untitled", text: $title)
                    .font(.custom("Menlo-Bold", size: 18))
                    .foregroundStyle(ink)
                    .textFieldStyle(.plain)
                    .padding(.bottom, 2)

                TextEditor(text: $documentText)
                    .font(.custom("Menlo-Regular", size: 15))
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
            .background(Color.black)
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
            window.backgroundColor = NSColor.black
            window.isOpaque = true
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

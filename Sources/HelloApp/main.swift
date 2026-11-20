import SwiftUI
import SNoteCore
import AppKit

@main
struct HelloApp: App {
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

    var body: some View {
        EditorView(title: $title, body: $documentText)
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
            }
            .onChange(of: documentText) { newValue in
                SNoteCore.setBody(newValue)
            }
    }
}

struct EditorView: View {
    @Binding var title: String
    @Binding var body: String

    private let ink = Color(red: 0.86, green: 0.86, blue: 0.84)

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                TextField("Untitled", text: $title)
                    .font(.custom("Menlo-Bold", size: 16))
                    .foregroundStyle(ink)
                    .textFieldStyle(.plain)
                    .padding(.bottom, 2)

                TextEditor(text: $body)
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

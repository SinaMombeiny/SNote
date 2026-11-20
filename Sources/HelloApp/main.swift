import SwiftUI
import CppHello
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
    private var message: String {
        guard let cString = hello_cpp_message() else {
            return "Hello, world!"
        }
        return String(cString: cString)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Text(message)
                .foregroundStyle(.white)
                .font(.largeTitle)
        }
        .frame(minWidth: 360, minHeight: 180)
        .preferredColorScheme(.dark)
        .background(WindowAccessor())
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

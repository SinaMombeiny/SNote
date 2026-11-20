import SwiftUI
import CppHello

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
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
        Text(message)
            .font(.largeTitle)
            .padding(40)
            .frame(minWidth: 360, minHeight: 180)
    }
}

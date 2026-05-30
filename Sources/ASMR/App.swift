import SwiftUI

@main
struct ASMRApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownFile()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            // Remove commands that don't apply to a Markdown editor
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    // DocumentGroup handles this
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

import SwiftUI

@main
struct ASMRApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownFile()) { file in
            ContentView(document: file.$document)
        }
    }
}

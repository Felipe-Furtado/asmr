# Architecture — ASMR

Last updated: 2026-05-29
Status: v0.1 Draft

---

## 1. Overview

ASMR is a native macOS document app built with **SwiftUI** and the **DocumentGroup** scene architecture. It uses **WKWebView** for rendered Markdown display and a plain **TextEditor** for raw Markdown editing. The two views share a single in-memory document model and toggle on demand.

```
┌─────────────────────────────────────────────┐
│                   ASMRApp                   │
│              (DocumentGroup scene)          │
└────────────────────┬────────────────────────┘
                     │ owns
                     ▼
┌─────────────────────────────────────────────┐
│               MarkdownFile                  │
│         (SwiftUI FileDocument)              │
│  • text: String          (source of truth)  │
│  • isDirty tracked by DocumentGroup         │
└────────────────────┬────────────────────────┘
                     │ passed into
                     ▼
┌─────────────────────────────────────────────┐
│               ContentView                   │
│  • viewMode: .rendered | .raw               │
│  • ⌘U toggles between modes                 │
└──────────┬──────────────────────┬───────────┘
           │                      │
           ▼                      ▼
┌──────────────────┐   ┌──────────────────────┐
│  RenderedView    │   │    RawEditorView      │
│  (WKWebView      │   │  (TextEditor,         │
│   read-only)     │   │   monospace, editable)│
└────────┬─────────┘   └──────────────────────┘
         │
         ▼
┌──────────────────┐
│ MarkdownRenderer │
│ text → HTML      │
│ (cmark-gfm)      │
└──────────────────┘
```

---

## 2. Technology Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| UI framework | SwiftUI | Native, declarative, dark mode for free |
| Document model | `FileDocument` (SwiftUI) | Gives undo/redo, dirty state, open/save dialogs at zero cost |
| Rendered view | `WKWebView` wrapped in `NSViewRepresentable` | Fast, CSS-styleable, handles complex tables and code blocks well |
| Raw editor | SwiftUI `TextEditor` | Simple; monospace font; sufficient for v1 |
| Markdown parser | `cmark-gfm` (C library via SPM wrapper) | Full GFM support (tables, task lists, strikethrough) |
| Syntax highlighting | `highlight.js` (bundled, loaded locally) | Easy WKWebView integration; no network required |
| Minimum OS | macOS Sequoia 15.0 | Modern SwiftUI APIs; Apple Silicon + Intel |

---

## 3. Project Structure

```
asmr/
├── Package.swift
├── Sources/
│   └── ASMR/
│       ├── App.swift                  # @main, DocumentGroup scene
│       ├── Models/
│       │   └── MarkdownFile.swift     # FileDocument conformance
│       ├── Views/
│       │   ├── ContentView.swift      # Root view, toggle logic
│       │   ├── RenderedView.swift     # WKWebView NSViewRepresentable
│       │   └── RawEditorView.swift    # Plain text editor
│       ├── Services/
│       │   └── MarkdownRenderer.swift # text → HTML pipeline
│       └── Resources/
│           ├── template.html          # HTML shell injected per render
│           ├── styles-light.css       # Light mode styles
│           ├── styles-dark.css        # Dark mode styles
│           └── highlight.min.js       # Bundled syntax highlighter
├── docs/
│   ├── PRD.md
│   └── ARCHITECTURE.md
└── README.md
```

---

## 4. Document Model

ASMR uses SwiftUI's `FileDocument` protocol, which gives us the standard macOS document lifecycle (open, save, save-as, dirty tracking, undo) without subclassing `NSDocument`.

```swift
// MarkdownFile.swift
struct MarkdownFile: FileDocument {
    static var readableContentTypes: [UTType] { [.markdown] }
    var text: String

    init(text: String = "") { self.text = text }

    init(configuration: ReadConfiguration) throws {
        // Read raw bytes → UTF-8 string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // UTF-8 encode text → FileWrapper
    }
}
```

**Why `FileDocument` over `NSDocument`:**
- Native SwiftUI integration — no AppKit bridging needed
- `DocumentGroup` handles the open/save sheet, dirty dot, and undo stack automatically
- Simpler to reason about: the document is just a `String`

---

## 5. View Architecture

### 5.1 ContentView

The root view owns the `viewMode` state and renders either `RenderedView` or `RawEditorView`.

```
ContentView
├── toolbar: [Toggle Rendered/Raw button]
├── if .rendered → RenderedView(html: rendered(document.text))
└── if .raw      → RawEditorView(text: $document.text)
```

- Switching from raw → rendered re-renders the HTML from the current `document.text`
- Switching from rendered → raw shows the current `document.text` in the text editor
- All edits in `RawEditorView` mutate `document.text` directly via `Binding`, which triggers dirty-state tracking automatically

### 5.2 RenderedView (WKWebView)

`RenderedView` wraps a `WKWebView` using `NSViewRepresentable`. On each render:

1. `MarkdownRenderer` converts the Markdown string to an HTML fragment
2. The fragment is injected into `template.html`
3. The complete HTML is loaded into the WebView via `loadHTMLString(_:baseURL:)` with a local base URL so relative images resolve correctly

The WebView is **not** editable in v1 (`isEditable = false`). Clicking into the document in rendered mode has no effect; the user presses `⌘ U` to switch to raw mode for editing.

> **v2 consideration:** True inline editing in rendered view (like Notion) would require a content-editable WebView + a JS↔Swift bridge to sync HTML changes back to Markdown. This is a significant addition deferred to v2.

### 5.3 RawEditorView

A SwiftUI `TextEditor` bound directly to `document.text`, styled with SF Mono and a comfortable line height. This is the edit surface for v1.

---

## 6. Markdown Rendering Pipeline

```
document.text (String)
       │
       ▼
  cmark-gfm parser
  (CommonMark + GFM extensions: tables, task lists, strikethrough)
       │
       ▼
  HTML fragment (String)
       │
       ▼
  Injected into template.html
  (applies CSS, inlines highlight.js)
       │
       ▼
  WKWebView.loadHTMLString(_:baseURL:)
       │
       ▼
  Rendered document in window
```

**Template injection** replaces a single `{{CONTENT}}` placeholder in `template.html` with the HTML fragment. The CSS applies the typography defaults from the PRD (SF Pro or New York body, SF Mono code, ~680px line width, 1.6 line height).

**Dark mode:** The CSS uses `@media (prefers-color-scheme: dark)` so the WebView inherits the system appearance without any Swift-side logic.

---

## 7. File I/O & Save Flow

`DocumentGroup` handles all file I/O. The flow for saving:

1. User presses `⌘ S`
2. SwiftUI calls `fileWrapper(configuration:)` on `MarkdownFile`
3. `document.text` is UTF-8 encoded and returned as a `FileWrapper`
4. The framework writes the file and clears the dirty indicator

No custom save logic is needed. First-time saves ("Save As") use the standard NSSavePanel provided by `DocumentGroup`.

---

## 8. Keyboard Shortcuts

| Action | Shortcut | Where handled |
|--------|----------|---------------|
| Toggle rendered/raw | `⌘ U` | ContentView `.keyboardShortcut` |
| Save | `⌘ S` | DocumentGroup (automatic) |
| Save As | `⌘ ⇧ S` | DocumentGroup (automatic) |
| Find | `⌘ F` | v1: WKWebView built-in find; raw: TextEditor built-in |
| Undo / Redo | `⌘ Z` / `⌘ ⇧ Z` | DocumentGroup (automatic) |
| Zoom In/Out/Reset | `⌘ +` / `⌘ -` / `⌘ 0` | ContentView, adjusts WKWebView zoom |

---

## 9. Dependencies

| Dependency | Source | Purpose |
|------------|--------|---------|
| `cmark-gfm` | Swift package wrapper (e.g. `scinfu/cmark-gfm-swift`) | GFM Markdown → HTML |
| `highlight.js` | Bundled in Resources (no CDN) | Syntax highlighting in code blocks |

No other third-party dependencies. No network access at runtime.

---

## 10. What's Not in v1

| Feature | Reason deferred |
|---------|-----------------|
| Inline editing in rendered view | Requires JS↔Swift bridge + HTML-to-Markdown round-trip; significant complexity |
| Table of Contents sidebar | Needs heading extraction post-parse; straightforward but non-trivial layout |
| File watcher / auto-reload | Requires `DispatchSource` file watcher; conflicts with document dirty state |
| iOS / iPadOS | Different platform target; document-group approach ports cleanly later |

---

## 11. Revision History

| Date | Version | Notes |
|------|---------|-------|
| 2026-05-29 | 0.1 | Initial architecture draft |

# Architecture — ASMR

Last updated: 2026-06-03
Status: v0.1.0 (reflects shipped code)

---

## 1. Overview

ASMR is a native macOS document app built with **SwiftUI** and the **DocumentGroup**
scene architecture. It uses **WKWebView** for rendered Markdown display and a plain
**TextEditor** for raw Markdown editing. The two views share a single in-memory
document model (`MarkdownFile`) and toggle on demand with `⌘U`.

```
┌─────────────────────────────────────────────┐
│                   ASMRApp                   │
│     (DocumentGroup — open/save/dirty free)  │
└────────────────────┬────────────────────────┘
                     │ owns
                     ▼
┌─────────────────────────────────────────────┐
│               MarkdownFile                  │
│         (SwiftUI FileDocument)              │
│  • text: String          (source of truth)  │
│  • dirty / undo tracked by DocumentGroup    │
└────────────────────┬────────────────────────┘
                     │ passed as @Binding into
                     ▼
┌─────────────────────────────────────────────┐
│               ContentView                   │
│  • viewMode: .rendered | .raw               │
│  • ⌘U toggles; re-renders on text change    │
│  • reads @Environment(\.colorScheme)        │
└──────────┬──────────────────────┬───────────┘
           │                      │
           ▼                      ▼
┌──────────────────┐   ┌──────────────────────┐
│  RenderedView    │   │    RawEditorView      │
│  (WKWebView via  │   │  (TextEditor,         │
│  NSViewRepresen- │   │   SF Mono, 14pt,      │
│  table)          │   │   bound to text)      │
└────────┬─────────┘   └──────────────────────┘
         │ receives html: String
         ▼
┌──────────────────────────────────────────────┐
│           MarkdownRenderer (singleton)       │
│  1. normalizeCodeFences()                    │
│  2. Ink.MarkdownParser.parse()               │
│  3. template + CSS substitution              │
│  → self-contained HTML string                │
└──────────────────────────────────────────────┘
```

---

## 2. Technology Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| UI framework | SwiftUI | Native, declarative, dark mode and window management for free |
| Document model | `FileDocument` (SwiftUI) | Gives open/save/dirty/undo at zero cost via `DocumentGroup` |
| Rendered view | `WKWebView` via `NSViewRepresentable` | Fast, CSS-styleable; handles tables and code blocks well |
| Raw editor | SwiftUI `TextEditor` | Sufficient for v1; monospace font; zero boilerplate |
| Markdown parser | **Ink 0.5.1** (johnsundell/Ink) | Pure Swift, no C bridging, trivial SPM integration |
| Syntax highlighting | highlight.js | Bundled stubs present; **not yet wired up** (v0.2) |
| Minimum OS | macOS 14.0 Sonoma | Constrained by Xcode on macOS 26 Tahoe SDK default |

---

## 3. Project Structure

```
asmr/
├── Package.swift                  SPM manifest; macOS 14 target; Ink dep
├── Info.plist                     Bundle ID, file-type UTI, icon declaration
├── Makefile                       run / build / app / open / install / dmg / icon
├── CLAUDE.md                      Agent-facing project memory (decisions, bugs, setup)
├── BUILDING.md                    Human-readable build guide
├── scripts/
│   └── make_icon.swift            Generates AppIcon.icns via CoreGraphics
└── Sources/ASMR/
    ├── App.swift                  @main; DocumentGroup scene
    ├── Models/
    │   └── MarkdownFile.swift     FileDocument; UTType.markdown; UTF-8 I/O
    ├── Views/
    │   ├── ContentView.swift      Root view; toggle logic; re-render triggers
    │   ├── RenderedView.swift     WKWebView wrapper; WKUserScript injection
    │   └── RawEditorView.swift    TextEditor bound to $document.text
    ├── Services/
    │   └── MarkdownRenderer.swift Singleton; fence normalization; CSS inlining
    └── Resources/
        ├── template.html          HTML shell ({{THEME}}, {{STYLES}}, {{CONTENT}})
        ├── styles.css             Typography + dark mode + code block styles
        ├── AppIcon.icns           Generated from make icon
        ├── highlight.min.js       Stub placeholder (not functional in v0.1)
        └── highlight.min.css      Stub placeholder (not functional in v0.1)
```

---

## 4. Document Model

`MarkdownFile` conforms to `FileDocument`. The entire document is a single UTF-8
`String`. `DocumentGroup` wraps it in a full macOS document lifecycle.

```swift
struct MarkdownFile: FileDocument {
    static var readableContentTypes: [UTType] { [.markdown] }
    var text: String

    init(configuration: ReadConfiguration) throws { /* UTF-8 decode */ }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { /* UTF-8 encode */ }
}

extension UTType {
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }
}
```

**Why `FileDocument` over `NSDocument`:** `DocumentGroup` handles the Open panel,
Save As panel, dirty indicator, and undo stack automatically. The document is just a
`String` — no AppKit bridging, no `NSDocument` subclass.

---

## 5. View Architecture

### 5.1 ContentView

Owns `viewMode` and `renderedHTML`. Re-renders whenever `document.text` or
`colorScheme` changes. Switching raw→rendered re-renders before swapping the view.

```swift
.onAppear            { render() }
.onChange(of: document.text) { render() }
.onChange(of: colorScheme)   { render() }

private func render() {
    renderedHTML = MarkdownRenderer.shared.render(
        document.text,
        isDark: colorScheme == .dark
    )
}
```

### 5.2 RenderedView (WKWebView)

`NSViewRepresentable` wrapper. Key setup in `makeNSView`:

```swift
// Force white-space preservation on pre/code via JS — overrides any UA-stylesheet
// interference. Fires at document-end with inline-style specificity.
let wsScript = WKUserScript(
    source: """
    document.querySelectorAll('pre, pre code').forEach(function(el) {
        el.style.whiteSpace = 'pre-wrap';
        el.style.overflowWrap = 'anywhere';
        el.style.wordBreak = 'normal';
    });
    """,
    injectionTime: .atDocumentEnd,
    forMainFrameOnly: true
)
config.userContentController.addUserScript(wsScript)

webView.setValue(false, forKey: "drawsBackground")  // prevents white pre-load flash
webView.allowsMagnification = true
```

`updateNSView` calls `webView.loadHTMLString(html, baseURL: nil)`. The HTML string is
fully self-contained — CSS is inlined, no external resources needed.

The `WKNavigationDelegate` intercepts `.linkActivated` navigation and opens links in
the system browser.

### 5.3 RawEditorView

SwiftUI `TextEditor` bound to `$document.text`, styled SF Mono 14pt with 4pt extra
line spacing. Edits directly mutate `document.text`, which `DocumentGroup` tracks for
dirty state and undo.

---

## 6. Markdown Rendering Pipeline

```
document.text
    │
    ▼  normalizeCodeFences()
    │  strips leading whitespace from lines starting with ``` or ~~~
    │  (Ink requires fence markers at column 0; indented fences inside
    │   list items would cause runaway code blocks otherwise)
    │
    ▼  Ink.MarkdownParser().parse(markdown)
    │  → Markdown.html  (HTML fragment; literal \n preserved in <pre><code>)
    │
    ▼  template substitution
    │  {{THEME}}   → "dark" | "light"   (class on <html> element)
    │  {{STYLES}}  → full contents of styles.css  (inlined — no <link> tag)
    │  {{CONTENT}} → Ink HTML fragment
    │
    ▼  WKWebView.loadHTMLString(html, baseURL: nil)
       + WKUserScript at document-end pins white-space: pre-wrap
```

### Why CSS is inlined, not `<link href="styles.css">`

`loadHTMLString(_:baseURL:)` with `baseURL: nil` gives the page an `about:blank`
origin. WebKit's security model silently blocks loading relative `file://` resources
in this configuration — even when a bundle base URL is provided. There is no reliable
workaround. Instead, `MarkdownRenderer` reads `styles.css` from `Bundle.module` once
at init and substitutes its full text into the HTML string via `{{STYLES}}`.

### Why dark mode uses `html.dark {}`, not `@media (prefers-color-scheme: dark)`

`@media (prefers-color-scheme: dark)` is evaluated by WebKit against the view's
`NSAppearance`. Inside a `DocumentGroup` window's `NSViewRepresentable`, this
appearance is not reliably propagated before the first `loadHTMLString` call. Instead,
Swift reads `@Environment(\.colorScheme)` and stamps `class="dark"` or `class="light"`
onto `<html>` before loading. CSS rules like `html.dark { --bg-color: #1e1e1e; }` fire
on the very first paint with no timing dependency.

---

## 7. Ink Parser: Known Limitation and Workaround

Ink 0.5.1 requires fence markers to begin at column 0. CommonMark §4.5 allows fences
inside list items to be indented. When indented, Ink never matches the closing fence —
the block runs on until the next un-indented ` ``` ` in the document.

**Workaround:** `normalizeCodeFences()` strips leading whitespace from any line whose
non-whitespace content begins with ```` ``` ```` or `~~~`. Fence markers are normalised;
content inside blocks is untouched.

Full CommonMark compliance would require replacing Ink with `swift-markdown` (Apple) or
`cmark-gfm` — candidates for v0.2.

---

## 8. Styling

`styles.css` uses CSS custom properties on `:root` for light mode and `html.dark {}`
for dark mode. Key rules:

| Element | Value |
|---------|-------|
| Body font | `-apple-system, "New York", Georgia, serif` |
| Code font | `"SF Mono", "Menlo", "Courier New", monospace` |
| Line width | `680px` max-width on `.markdown-body` |
| Body size | `17px`, line-height `1.65` |
| Code blocks | `white-space: pre-wrap`, `overflow-wrap: anywhere` — soft-wrap, no horizontal scroll |

---

## 9. File Type Registration

`Info.plist` declares ASMR as `Editor` for `net.daringfireball.markdown` (`.md`,
`.markdown`). `UTImportedTypeDeclarations` ensures the UTI is available even on systems
where no other app has defined it.

---

## 10. Distribution

| Channel | Details |
|---------|---------|
| GitHub Releases | `make dmg` → `ASMR-x.y.z.dmg` → `gh release create` |
| Homebrew Cask | `brew tap Felipe-Furtado/asmr` → `brew install --cask asmr` |
| Build from source | `make install` (requires Xcode) |

No code signing / notarization in v0.1. Users must right-click → Open or run
`xattr -dr com.apple.quarantine /Applications/ASMR.app` the first time.

---

## 11. What's Not in v0.1

| Feature | Notes for v0.2 |
|---------|----------------|
| Syntax highlighting | highlight.js stubs in Resources; wire up `hljs.highlightAll()` in template |
| Find in document | Expose WKWebView built-in find bar (`⌘F`) |
| Font size control | `webView.magnification` via `⌘+` / `⌘-` / `⌘0` |
| Frontmatter | Render YAML/TOML header block as a collapsed table or strip it |
| CommonMark compliance | Replace Ink with `swift-markdown` or `cmark-gfm` |
| Notarization | Apple Developer Program ($99/yr); prerequisite for App Store |

---

## 12. Revision History

| Date | Version | Notes |
|------|---------|-------|
| 2026-05-29 | 0.1 | Initial draft |
| 2026-06-03 | 0.2 | Full rewrite to reflect shipped v0.1.0: Ink parser, CSS inlining, dark mode approach, fence-normalization bug/fix, WKUserScript, macOS 14 target, distribution |

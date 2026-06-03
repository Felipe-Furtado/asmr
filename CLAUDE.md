# CLAUDE.md — ASMR project memory

> This file is the primary orientation document for any agent (Claude or otherwise)
> resuming work on this project. Keep it current whenever significant decisions are made.
> Last updated: 2026-06-03

---

## What this is

ASMR (A Simple Markdown Reader) is a native macOS document app built with Swift 6.3.2 /
SwiftUI. It opens `.md` files, renders them with clean typography, and lets the user edit
and save them. No Electron, no runtime, no IDE features. Think "Preview for Markdown."

- **GitHub:** https://github.com/Felipe-Furtado/asmr
- **Owner:** Felipe Furtado (ffurtado@umich.edu)
- **Current release:** v0.1.0 (June 2026)
- **Homebrew tap:** `brew tap Felipe-Furtado/asmr && brew install --cask asmr`

---

## Current state (v0.1.0)

Everything below is **working and shipped**:

| Feature | Notes |
|---------|-------|
| Open `.md` / `.markdown` from Finder | Registered as Editor for `net.daringfireball.markdown` |
| Rendered Markdown view | Ink parser → HTML → WKWebView |
| Raw / source editor | SwiftUI TextEditor, SF Mono, `⌘U` to toggle |
| Save / dirty state | `FileDocument` + `DocumentGroup` — zero custom code |
| Light / dark mode | CSS `html.dark {}` class injected at render time |
| Code blocks | Soft-wrapped (`pre-wrap`), JS belt-and-suspenders |
| App icon | Bold white `#` on charcoal, geometric (CoreGraphics) |
| DMG distribution | `make dmg` → `ASMR-x.y.z.dmg` |
| Homebrew Cask | `Felipe-Furtado/homebrew-asmr` tap |

**Not yet implemented (v0.2 candidates):**
- Syntax highlighting in code blocks (highlight.js stubs exist but library not loaded)
- Find in document (`⌘F` — WKWebView built-in, not wired up)
- Font size adjustment (`⌘+` / `⌘-`)
- Frontmatter handling
- App Store submission / notarization

---

## Build & run

```bash
# Prerequisites: Xcode (not just CLT) + Apple Silicon Mac

cd ~/Documents/Claude\ Code/asmr

make open       # build release + assemble .app + launch
make install    # build + copy to /Applications
make dmg        # build + package ASMR-0.1.0.dmg (prints SHA-256)
make run        # swift run (dev mode, faster, no .app bundle)
```

**macOS 26 Tahoe quirk:** `swift build` succeeds but exits code 1 with a spurious
"disk I/O error" on `.build/build.db`. The Makefile uses `test -f <binary>` as the
success check — do not change this. See BUILDING.md for full explanation.

---

## Architecture at a glance

```
ASMRApp (DocumentGroup)
  └── ContentView
        ├── .rendered → RenderedView (WKWebView)
        │                   └── fed by MarkdownRenderer.render()
        └── .raw      → RawEditorView (TextEditor)

MarkdownRenderer (singleton, @MainActor)
  1. normalizeCodeFences(markdown)  ← pre-processes indented fences
  2. Ink.MarkdownParser.parse()     ← Markdown → HTML fragment
  3. template.html {{ substitution }}
     - {{THEME}}   → "dark" | "light"  (class on <html>)
     - {{STYLES}}  → full CSS content (inlined — see why below)
     - {{CONTENT}} → Ink HTML fragment
  4. returns self-contained HTML string → WKWebView.loadHTMLString(_:baseURL:nil)
```

---

## Key architectural decisions (with reasons)

### 1. Ink parser (not cmark-gfm, not swift-markdown)
Chosen for: pure Swift, zero C bridging, trivial SPM integration. Known limitation:
does not support CommonMark §4.5 (indented fenced code blocks inside list items).
Worked around by `normalizeCodeFences()` — see "Bugs fixed" below.

### 2. CSS inlined, `baseURL: nil`
`WKWebView.loadHTMLString(_:baseURL:)` silently refuses to load relative `file://`
resources (stylesheets, scripts) in many WebKit security configurations — even when
given a bundle base URL. Instead, `styles.css` is read from `Bundle.module` once at
init and its content is substituted into the HTML string via `{{STYLES}}`. The page
is fully self-contained; no external resources are ever needed.

### 3. Dark mode via `html.dark {}` class, NOT `@media (prefers-color-scheme: dark)`
`@media (prefers-color-scheme: dark)` requires WKWebView to receive the correct
`NSAppearance` at load time — this is not reliably propagated from SwiftUI's
`NSViewRepresentable` inside a `DocumentGroup` window. Swift reads `colorScheme`
from `@Environment` and stamps `class="dark"` or `class="light"` on the `<html>`
element before calling `loadHTMLString`. CSS uses `html.dark {}` selectors, so the
correct theme fires on the very first paint with no timing dependency.

### 4. `FileDocument` over `NSDocument`
`DocumentGroup` + `FileDocument` gives open/save/dirty-state/undo for free with
zero boilerplate. The entire document is just a `String`. Switching to `NSDocument`
would require AppKit bridging and gain nothing for v1.

### 5. `drawsBackground = false` on WKWebView
Without this, WKWebView shows a white flash before the HTML finishes loading. The
CSS background colour takes over immediately when `drawsBackground` is false.

### 6. WKUserScript for `white-space: pre-wrap`
Belt-and-suspenders: a `WKUserScript` injected `atDocumentEnd` forces
`white-space: pre-wrap` on all `pre` and `pre code` elements via inline style
(highest specificity). This is in addition to the CSS declaration, because WKWebView
on macOS 26 Tahoe exhibited UA-stylesheet interference with code block whitespace.

---

## Bugs found, root causes, and fixes

### Dark mode not applying (fixed)
**Symptom:** Rendered view always light regardless of OS setting.
**Root cause:** CSS loaded via `<link href="styles.css">` never loaded — `loadHTMLString`
with `baseURL: nil` silently blocks relative file:// resource loading. Page had zero
custom CSS; `@media (prefers-color-scheme: dark)` was never evaluated.
**Fix:** Inline CSS + html.dark class approach (see decisions above).

### Fenced code blocks inside list items parsed as paragraphs (fixed)
**Symptom:** README directory trees and code blocks inside ordered list installation
steps all collapsed into plain paragraphs; preceding content ran into adjacent
paragraphs.
**Root cause:** Ink requires fence markers (```` ``` ````) at column 0. When a fence is
indented (normal inside a list item), Ink never recognises the closing fence. The code
block runs on until it hits the next un-indented ```` ``` ```` — which happens to be the
OPENING fence of the directory tree block, consuming that as the closing fence of the
runaway block. The tree content then becomes a `<p>`.
**Root cause confirmed by:** writing the rendered HTML to `/tmp/asmr_render_debug.html`
and inspecting the actual `<pre><code>` content vs `<p>` content.
**Fix:** `normalizeCodeFences()` in `MarkdownRenderer` strips leading whitespace from
any line whose non-whitespace content begins with ```` ``` ```` or `~~~`, normalising
all fence markers to column 0 before Ink sees the input. Content inside blocks is
untouched.

### `white-space: pre` not preserving newlines in code blocks (fixed)
**Symptom:** After the fence-normalization fix, code blocks rendered but newlines were
still collapsed in some WKWebView configurations on macOS 26 Tahoe.
**Fix:** Changed CSS from `white-space: pre` to `white-space: pre-wrap` on both `pre`
and `pre code`, added `overflow-wrap: anywhere`, and added the WKUserScript injection
as a third layer (inline styles cannot be overridden by UA stylesheets).

---

## File map

```
asmr/
├── Package.swift               SPM manifest; macOS 14 target; Ink 0.5.1 dep
├── Info.plist                  Bundle ID, UTI declarations, file-type association
├── Makefile                    All build targets (run/build/app/open/install/dmg/icon)
├── CLAUDE.md                   ← this file
├── BUILDING.md                 Human-readable build guide
├── README.md                   User-facing README with install instructions
├── scripts/
│   └── make_icon.swift         CoreGraphics script → 1024×1024 PNG → AppIcon.icns
├── Sources/ASMR/
│   ├── App.swift               @main, DocumentGroup scene
│   ├── Models/
│   │   └── MarkdownFile.swift  FileDocument; UTType.markdown; read/write UTF-8
│   ├── Views/
│   │   ├── ContentView.swift   Owns viewMode state; ⌘U toggle; calls render()
│   │   ├── RenderedView.swift  NSViewRepresentable(WKWebView); WKUserScript injection
│   │   └── RawEditorView.swift TextEditor; SF Mono; bound to $document.text
│   ├── Services/
│   │   └── MarkdownRenderer.swift  @MainActor singleton; normalizeCodeFences; CSS inline
│   └── Resources/
│       ├── template.html       HTML shell with {{THEME}}, {{STYLES}}, {{CONTENT}}
│       ├── styles.css          Full typography + dark mode (html.dark {}); pre-wrap code
│       ├── AppIcon.icns        Generated by make icon
│       ├── highlight.min.js    STUB — placeholder, library not loaded
│       └── highlight.min.css   STUB — placeholder, library not loaded
└── docs/
    ├── PRD.md                  Product requirements (v0.2)
    └── ARCHITECTURE.md         Architecture reference (updated 2026-06-03)
```

---

## Distribution setup (v0.1.0)

| Asset | Location |
|-------|----------|
| Source | https://github.com/Felipe-Furtado/asmr |
| GitHub Release | https://github.com/Felipe-Furtado/asmr/releases/tag/v0.1.0 |
| DMG | `ASMR-0.1.0.dmg` attached to release |
| Homebrew tap repo | https://github.com/Felipe-Furtado/homebrew-asmr |
| Cask formula | `homebrew-asmr/Casks/asmr.rb` |

**To cut a new release:**
1. Bump `VERSION` in Makefile
2. `make dmg` — note the SHA-256 printed at the end
3. `gh release create vX.Y.Z ASMR-X.Y.Z.dmg`
4. Update `sha256` and `version` in `homebrew-asmr/Casks/asmr.rb` → push

**Gatekeeper:** App is unsigned / unnotarized. Users need to right-click → Open once,
or run `xattr -dr com.apple.quarantine /Applications/ASMR.app`. Notarization requires
Apple Developer Program ($99/yr) — deferred to v0.2 / App Store push.

---

## Environment

- **Machine:** Apple Silicon MacBook Air (arm64), macOS 26.5 Tahoe
- **Swift:** 6.3.2 (Xcode)
- **Deployment target:** macOS 14.0 (not 15 — CLI tools SDK on Tahoe only exposes 14.4)
- **SPM dependency:** `johnsundell/Ink` 0.5.1 (pinned)

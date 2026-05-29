# Product Requirements Document — ASMR

**A Simple Markdown Reader**
Last updated: 2026-05-28
Status: Draft v0.2

---

## 1. Overview

### 1.1 Problem Statement

Markdown has become the interoperability layer of the AI era. AI coding assistants (Claude, Cursor, Copilot) generate and consume Markdown natively — READMEs, specs, changelogs, and system prompts are all `.md` files. Claude "skills," MCP server configs, and agent context files are stored as Markdown. dbt v3+ uses Markdown extensively for data contracts, model descriptions, and documentation. The result: non-developers now encounter `.md` files daily as a routine artifact of AI-assisted workflows, not just as a developer convention.

macOS has no native, purpose-built app for Markdown files. Users who need to open or edit `.md` documents — technical writers, engineers, product managers, data practitioners, students — are forced to choose between raw-text editors (TextEdit), heavyweight IDEs (VS Code, Xcode), or off-platform workarounds (browsers, web converters). None of these are "just open and read" experiences, and none treat Markdown as a first-class document format the way Preview treats PDFs.

### 1.2 Goal

Build a lightweight, native macOS application that lets users read, edit, and save Markdown files as clean, readable documents — the same frictionless experience macOS Preview provides for PDFs, extended with editing capability like Word provides for `.docx` files. The app is document-centric, not project-centric: users open a document, read it, edit it, and save it. ASMR has no execution capability — no terminal, no debugger, no build system, no run button. Markdown files cannot be "run," and ASMR makes no attempt to do so.

### 1.3 Non-Goals

- Syncing or cloud storage
- Note-taking or organization features
- Support for non-macOS platforms (v1)
- Real-time collaboration

---

## 2. Target Users

| Persona | Description |
|---------|-------------|
| **The Engineer** | Opens READMEs, changelogs, and API docs from Finder without wanting to spin up an IDE |
| **The PM / Writer** | Receives spec docs, SOPs, or proposals in `.md` format and needs a clean reading and editing experience |
| **The Student** | Downloads course notes or textbooks in Markdown and wants to read them like a normal document |
| **The Power User** | Sets ASMR as the default `.md` app system-wide so files just open correctly |
| **The AI Workflow User** | Works with Claude, dbt, Cursor, or other AI tools that produce `.md` files — skills, MCP configs, data contracts, system prompts — and needs to open and edit them without spinning up an IDE |

---

## 3. Requirements

### 3.1 Functional Requirements

#### Must Have (v1 MVP)

- **F1** — Open any `.md` file via Finder double-click, drag-and-drop onto the app icon, or "Open With" from the context menu
- **F2** — Render standard CommonMark Markdown: headings (H1–H6), paragraphs, bold, italic, strikethrough, inline code, code blocks (with syntax highlighting), blockquotes, unordered lists, ordered lists, nested lists, horizontal rules, links, and images
- **F3** — Render GitHub Flavored Markdown (GFM) extensions: tables, task lists (checkboxes rendered, not interactive in v1)
- **F4** — Respect system appearance (light mode / dark mode), updating live if the user switches
- **F5** — Display filename as the window title
- **F6** — Support opening multiple files simultaneously in separate windows
- **F7** — Register as a handler for the `.md` file extension so macOS offers ASMR as an option in "Open With"
- **F8** — Toggle between rendered view and raw Markdown source (`⌘ U`) — this is a primary feature, not an afterthought
- **F9** — Inline editing in rendered view: user clicks into the document and edits text with standard formatting controls; typing `**` bolds text, etc.
- **F10** — Raw Markdown editing mode: plain-text editor with monospace font for users who prefer to work directly in Markdown syntax
- **F11** — Save file to disk (`⌘ S`); Save As (`⌘ Shift S`)
- **F12** — Dirty state indicator: window title shows the standard macOS edited indicator (dot) when there are unsaved changes
- **F13** — Standard macOS Edit menu: undo/redo, cut, copy, paste

#### Should Have (v1)

- **F14** — Find in document (`⌘ F`) with text search and highlight
- **F15** — Font size adjustment (`⌘ +` / `⌘ -` / `⌘ 0` to reset)
- **F16** — Clickable hyperlinks open in the default browser
- **F17** — Relative image paths resolve correctly relative to the source file's directory

#### Nice to Have (v2+)

- **F18** — Print / Export to PDF via macOS print dialog
- **F19** — Table of Contents sidebar generated from headings
- **F20** — Watch file for changes and auto-reload
- **F21** — Pinch-to-zoom support
- **F22** — Customizable fonts and line width
- **F23** — Support `.markdown` and `.mdown` extensions

### 3.2 Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| **NF1** | App launch to first rendered document in under 500ms on Apple Silicon |
| **NF2** | Renders a 10,000-line Markdown file without jank or dropped frames |
| **NF3** | Memory footprint under 100MB for a single open document |
| **NF4** | Sandbox-compatible; no network access required at runtime |
| **NF5** | Notarized and distributed via the Mac App Store or direct download (signed) |
| **NF6** | Minimum macOS version: Sequoia 15.0 (Apple Silicon + Intel) |

### 3.3 Out of Scope (Explicit Exclusions)

- Markdown-to-Word or Markdown-to-HTML export (beyond native print-to-PDF)
- Plugin or extension system
- iOS / iPadOS version (v1)
- Code execution, terminal, debugger, or build system of any kind

---

## 4. User Experience

### 4.1 Core Flow

**Read flow:**
1. User double-clicks a `.md` file in Finder
2. ASMR opens, renders the file, and displays it immediately
3. User reads the document
4. User closes the window — no prompts, no save dialogs (file was not modified)

**Edit flow:**
1. User double-clicks a `.md` file in Finder
2. ASMR opens and renders the file
3. User clicks into the rendered view (or toggles to raw mode with `⌘ U`) and makes changes
4. Window title shows the unsaved-changes indicator (dot)
5. User presses `⌘ S` to save; file is written back to disk
6. User closes the window — no prompt if already saved; standard "save before closing?" sheet if unsaved changes remain

### 4.2 Design Principles

- **Invisible chrome** — the UI should never compete with the document
- **System-native** — use macOS conventions for menus, fonts, scrollbars, and shortcuts
- **Zero configuration** — works correctly out of the box with no setup
- **Fast** — feels instantaneous; never shows a spinner for normal files

### 4.3 Typography Defaults

| Element | Default |
|---------|---------|
| Body font | System serif (New York) or system sans-serif (SF Pro) — TBD |
| Code font | SF Mono |
| Line width | ~680px (readable prose width) |
| Line height | 1.6 |

---

## 5. Technical Considerations

### 5.1 Platform

Native macOS app. Primary candidates:

| Option | Pros | Cons |
|--------|------|------|
| **SwiftUI + WKWebView** | Fast rendering via WebKit; CSS-based styling is easy to tune | Slight overhead from web layer |
| **SwiftUI + AttributedString** | Fully native rendering | Limited Markdown support natively; complex tables/code blocks need custom work |
| **SwiftUI + swift-markdown + custom renderer** | Full control; no web dependency | More implementation work |

Recommended starting point: **SwiftUI + WKWebView** with a local HTML/CSS template for rendering. Fast to build, easy to style, and trivially dark-mode compatible.

### 5.2 Markdown Parser

- [swift-markdown](https://github.com/apple/swift-markdown) — Apple's own CommonMark parser (preferred)
- [cmark-gfm](https://github.com/github/cmark-gfm) — GitHub's C library with GFM extensions (via Swift wrapper)

### 5.3 Syntax Highlighting

- [highlight.js](https://highlightjs.org/) (client-side JS, bundled) — easiest to integrate with WKWebView approach
- [Prism.js](https://prismjs.com/) — alternative

---

## 6. Success Metrics

| Metric | Target |
|--------|--------|
| Time-to-render (cold launch) | < 500ms |
| App Store rating | ≥ 4.5 stars |
| Crash-free sessions | ≥ 99.5% |
| Download-to-set-as-default rate | > 40% (proxy for "it just works") |

---

## 7. Open Questions

- [ ] Paid app vs. free? (free with optional tip jar / one-time purchase recommended)
- [ ] Mac App Store only, or also direct download?
- [ ] Which default font — serif (New York) feels more "document-like"; sans-serif is more GitHub-like
- [ ] Should v1 support frontmatter (YAML/TOML metadata blocks)? Render as a table or hide?
- [ ] Auto-reload on file change — in v1 or v2?

---

## 8. Revision History

| Date | Version | Notes |
|------|---------|-------|
| 2026-05-28 | 0.1 | Initial draft |
| 2026-05-28 | 0.2 | Editing in scope; AI-era framing; GUI clarification; new AI Workflow User persona |

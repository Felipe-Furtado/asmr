# Product Requirements Document — ASMR

**A Simple Markdown Reader**
Last updated: 2026-05-28
Status: Draft v0.1

---

## 1. Overview

### 1.1 Problem Statement

macOS has no native, purpose-built viewer for Markdown files. Users who work with `.md` documents — technical writers, engineers, product managers, students — are forced to choose between raw-text editors (TextEdit), heavyweight IDEs (VS Code, Xcode), or off-platform workarounds (browsers, web converters). None of these are "just open and read" experiences.

### 1.2 Goal

Build a lightweight, native macOS application that renders Markdown files as clean, readable documents — the same frictionless experience macOS Preview provides for PDFs.

### 1.3 Non-Goals

- Editing Markdown (write/save functionality is out of scope for v1)
- Syncing or cloud storage
- Note-taking or organization features
- Support for non-macOS platforms (v1)
- Real-time collaboration

---

## 2. Target Users

| Persona | Description |
|---------|-------------|
| **The Engineer** | Opens READMEs, changelogs, and API docs from Terminal or Finder without wanting to spin up an IDE |
| **The PM / Writer** | Receives spec docs, SOPs, or proposals in `.md` format and needs a clean reading experience |
| **The Student** | Downloads course notes or textbooks in Markdown and wants to read them like a normal document |
| **The Power User** | Sets ASMR as the default `.md` app system-wide so files just open correctly |

---

## 3. Requirements

### 3.1 Functional Requirements

#### Must Have (v1 MVP)

- **F1** — Open any `.md` file via Finder double-click, drag-and-drop onto the app icon, or `open -a ASMR file.md` in Terminal
- **F2** — Render standard CommonMark Markdown: headings (H1–H6), paragraphs, bold, italic, strikethrough, inline code, code blocks (with syntax highlighting), blockquotes, unordered lists, ordered lists, nested lists, horizontal rules, links, and images
- **F3** — Render GitHub Flavored Markdown (GFM) extensions: tables, task lists (checkboxes rendered, not interactive)
- **F4** — Respect system appearance (light mode / dark mode), updating live if the user switches
- **F5** — Display filename as the window title
- **F6** — Support opening multiple files simultaneously in separate windows
- **F7** — Register as a handler for the `.md` file extension so macOS offers ASMR as an option in "Open With"

#### Should Have (v1)

- **F8** — Keyboard shortcut to toggle between rendered view and raw Markdown source (`⌘ U` or similar)
- **F9** — Find in document (`⌘ F`) with text search and highlight
- **F10** — Font size adjustment (`⌘ +` / `⌘ -` / `⌘ 0` to reset)
- **F11** — Clickable hyperlinks open in the default browser
- **F12** — Relative image paths resolve correctly relative to the source file's directory

#### Nice to Have (v2+)

- **F13** — Print / Export to PDF via macOS print dialog
- **F14** — Table of Contents sidebar generated from headings
- **F15** — Watch file for changes and auto-reload
- **F16** — Pinch-to-zoom support
- **F17** — Customizable fonts and line width
- **F18** — Support `.markdown` and `.mdown` extensions

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

- Writing or editing Markdown
- WYSIWYG editing mode
- Markdown-to-Word or Markdown-to-HTML export (beyond native print-to-PDF)
- Plugin or extension system
- iOS / iPadOS version (v1)

---

## 4. User Experience

### 4.1 Core Flow

1. User double-clicks a `.md` file in Finder
2. ASMR opens, renders the file, and displays it immediately
3. User reads the document
4. User closes the window — no prompts, no save dialogs

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

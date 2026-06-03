# ASMR — A Simple Markdown Reader

A lightweight, native macOS app for reading and editing Markdown files the way they were meant to be used.

## The Problem

Markdown is everywhere — and it's accelerating. READMEs, specs, API docs, SOPs, personal notes — plain `.md` files have become a de facto standard for interoperable text documents. But a newer wave is pushing Markdown far beyond developer circles:

**AI tools have made Markdown the interoperability layer of the AI era.**

- AI assistants (Claude, Cursor, Copilot, ChatGPT) generate and consume Markdown natively — every spec, README, changelog, and system prompt they produce is a `.md` file
- Claude "skills," MCP server configs, agent context files, and system prompts are all stored as `.md` files
- dbt (data build tool), starting with v3, uses Markdown extensively for model documentation, descriptions, and data contracts
- AI coding assistants produce Markdown documentation as a first-class output

Non-developers are now routinely opening `.md` files and staring at raw syntax. macOS has no native solution:

- **TextEdit** renders raw syntax, not formatted output
- **Word** mangles the formatting
- **VS Code / Xcode** are full IDEs — overkill for reading or editing a document
- **Browser extensions** require extra steps and don't integrate with Finder

There's no "Preview for Markdown" on macOS. ASMR is that app.

## What It Is

ASMR is a native macOS document app — window-based, Finder-integrated — that opens `.md` files and renders them as clean, readable documents, while also letting you edit and save them. Think of it as Word for Markdown: open a document, read it, edit it, save it.

- **Opens from Finder** like any other macOS app — double-click a `.md` file or use Open With
- **Renders standard Markdown** — headings, bold, italics, lists, task lists, code blocks, tables, links
- **Toggle rendered / raw views** with `⌘ U` to work directly with Markdown source
- **Save back to disk** with `⌘ S`; dirty-state indicator in the title bar
- **Respects system light / dark mode** — switching appearance updates the rendered view instantly
- **Soft-wraps long lines** in code blocks so nothing overflows off-screen
- Optimised for Apple Silicon — faster than Word, zero bloat
- No subscription. No Electron. No cloud sync.

**Requires macOS 14 Sonoma or later.**

## What It Is Not

- Not an IDE — ASMR has no terminal, no debugger, no build system, no run button
- Not a note-taking or sync service
- Not a project manager

---

## Installation

### Option 1 — Homebrew (recommended)

```bash
brew tap Felipe-Furtado/asmr
brew install --cask asmr
```

### Option 2 — Direct download

1. Go to the [latest release](https://github.com/Felipe-Furtado/asmr/releases/latest)
2. Download `ASMR-x.y.z.dmg`
3. Open the DMG, drag **ASMR.app** to your **Applications** folder

> **Gatekeeper notice** — because ASMR is not yet notarised with Apple, macOS may show
> "App can't be opened because it is from an unidentified developer" the first time.
> Right-click the app and choose **Open** to bypass this once, or run:
>
> ```bash
> xattr -dr com.apple.quarantine /Applications/ASMR.app
> ```

### Option 3 — Build from source

Requires Xcode (not just Command Line Tools).

```bash
git clone https://github.com/Felipe-Furtado/asmr.git
cd asmr
make install     # builds release binary, assembles .app, copies to /Applications
```

---

## Project Status

| Milestone | Status |
|-----------|--------|
| Requirements (PRD v0.2) | ✅ Done |
| Architecture | ✅ Done |
| Markdown rendering (Ink parser + WKWebView) | ✅ Done |
| Dark / light mode | ✅ Done |
| Toggle rendered ↔ raw (`⌘ U`) | ✅ Done |
| Edit + save (`⌘ S`, dirty-state indicator) | ✅ Done |
| App icon | ✅ Done |
| v0.1.0 release | ✅ Done |
| Syntax highlighting in code blocks | ⏳ v0.2 |
| App Store submission | ⏳ Planned |

## Documents

- [Product Requirements Document](docs/PRD.md)
- [Architecture](docs/ARCHITECTURE.md)

## Contributing

Issues and pull requests welcome. See the PRD for the v0.2 roadmap.

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

ASMR is a native macOS document app — window-based, Finder-integrated — that opens `.md` files and renders them as clean, readable documents, while also letting you edit and save them. Think of it like Word for Markdown: open a document, read it, edit it, save it. Requires macOS Sequoia 15.0 or later.

- **Opens from Finder** like any other macOS app — double-click a `.md` file or use Open With
- **Renders standard Markdown**: headings, bold, italics, lists, task lists, code blocks, tables, links
- **Edit in rendered view**: click into the document and edit with standard formatting controls; typing `**` bolds text, etc.
- **Toggle rendered/raw views** (`⌘ U`) to work directly with Markdown source when needed
- **Save back to disk** with `⌘ S`
- Respects the system light/dark mode
- No subscription. No Electron. No bloat.

## What It Is Not

- Not an IDE — ASMR has no terminal, no debugger, no build system, no run button. Markdown files aren't programs; ASMR doesn't pretend they are. That's what separates it from VS Code or Xcode.
- Not a note-taking or sync service
- Not a project manager

## Project Status

| Milestone | Status |
|-----------|--------|
| Requirements (PRD) | 🔄 In progress |
| Architecture | ⏳ Planned |
| MVP | ⏳ Planned |
| App Store submission | ⏳ Planned |

## Documents

- [Product Requirements Document](docs/PRD.md)

## Contributing

This project is in early planning. Come back soon.

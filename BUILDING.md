# Building ASMR

## Requirements

- macOS 14.0 or later (Sonoma+)
- **Xcode** installed from the App Store (not just Command Line Tools)
- Apple Silicon Mac (arm64) — primary target

> **Note for macOS 26 (Tahoe):** The standalone Command Line Tools have a broken
> `libPackageDescription` stub on macOS 26 that prevents `swift build` from running.
> Full Xcode resolves this. This is a known CLT issue on the Tahoe beta cycle.

---

## First-time setup (do once after Xcode installs)

```bash
# 1. Accept the Xcode license
sudo xcodebuild -license accept

# 2. Fetch SPM dependencies (downloads Ink from GitHub)
cd path/to/asmr
swift package resolve
```

---

## Option A — Open in Xcode (recommended for development)

```bash
open /path/to/asmr
```

Xcode detects `Package.swift` automatically. Select:
- Scheme: **ASMR**
- Destination: **My Mac**

Hit **⌘R** to build and run.

---

## Option B — Command line (release build)

```bash
# Build optimised arm64 binary + assemble .app bundle
make app

# Build and immediately launch
make open

# Install to /Applications permanently
make install
```

The assembled `ASMR.app` can be double-clicked, dragged to `/Applications`,
or set as the default "Open With" app for `.md` files via Finder → Get Info.

---

## Testing editing

1. Launch the app (either method above)
2. macOS shows the standard **Open** dialog — pick any `.md` file
3. The document renders in the **preview** pane
4. Press **⌘U** to toggle to the **raw editor** — type freely
5. Press **⌘S** to save changes back to disk
6. Press **⌘U** again to see the updated rendered output

---

## Performance notes

The arm64 build runs **natively on Apple Silicon** — no Rosetta translation.
With the Ink parser and WKWebView renderer, a 10,000-line document renders
in well under 100ms. There is no JIT compiler, no bundled Node.js runtime,
no Electron overhead.

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [Ink](https://github.com/johnsundell/Ink) | ≥ 0.5.1 | Pure-Swift Markdown → HTML parser |

All other dependencies are system frameworks (SwiftUI, WebKit, Foundation).
No network access is required at runtime.

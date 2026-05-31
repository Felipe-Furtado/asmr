# ASMR — A Simple Markdown Reader
# Optimised for Apple Silicon (arm64).
# Requires: Xcode installed (not just Command Line Tools)

APP_NAME    := ASMR
ARCH        := arm64
CONFIG      := release
BUILD_DIR   := .build/$(ARCH)-apple-macosx/$(CONFIG)
APP_BUNDLE  := $(APP_NAME).app
RES_BUNDLE  := $(APP_NAME)_$(APP_NAME).bundle

# ──────────────────────────────────────────────
# First-time setup
# ──────────────────────────────────────────────

## Accept Xcode license (required once after Xcode install)
license:
	sudo xcodebuild -license accept

## Resolve / fetch SPM dependencies
resolve:
	swift package resolve

# ──────────────────────────────────────────────
# Development
# ──────────────────────────────────────────────

## Run in development mode — fast, no packaging needed
run:
	swift run

# ──────────────────────────────────────────────
# Release build — Apple Silicon, full optimisation
# ──────────────────────────────────────────────

## Compile optimised arm64 binary
## Note: on macOS 26 Tahoe, SPM emits a post-build disk I/O warning on its
## build.db file — the build still succeeds. We treat it as a success if
## the binary exists at the expected path.
build:
	swift build -c $(CONFIG) --arch $(ARCH); \
	test -f "$(BUILD_DIR)/$(APP_NAME)"

## Build + assemble a proper .app bundle (double-clickable, drag to /Applications)
app: build
	@echo "▶ Assembling $(APP_BUNDLE)..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(BUILD_DIR)/$(APP_NAME)          $(APP_BUNDLE)/Contents/MacOS/
	@cp Info.plist                         $(APP_BUNDLE)/Contents/
	@if [ -d "$(BUILD_DIR)/$(RES_BUNDLE)" ]; then \
		cp -r "$(BUILD_DIR)/$(RES_BUNDLE)" "$(APP_BUNDLE)/Contents/Resources/"; \
		echo "  ✓ Resource bundle copied"; \
	else \
		echo "  ⚠  Resource bundle not found (styles/template will use fallback)"; \
	fi
	@echo "✓ $(APP_BUNDLE) ready"
	@echo "  Run:     open $(APP_BUNDLE)"
	@echo "  Install: cp -r $(APP_BUNDLE) /Applications/"

## Build the app bundle and launch it
open: app
	open $(APP_BUNDLE)

## Install to /Applications
install: app
	@echo "Installing to /Applications/$(APP_BUNDLE)..."
	@cp -r $(APP_BUNDLE) /Applications/
	@echo "✓ Installed. Open it from Launchpad or Spotlight."

# ──────────────────────────────────────────────
# Housekeeping
# ──────────────────────────────────────────────

## Remove all build artefacts
clean:
	swift package clean
	rm -rf $(APP_BUNDLE)

.PHONY: license resolve run build app open install clean

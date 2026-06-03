# ASMR — A Simple Markdown Reader
# Optimised for Apple Silicon (arm64).
# Requires: Xcode installed (not just Command Line Tools)

APP_NAME    := ASMR
VERSION     := 0.1.0
ARCH        := arm64
CONFIG      := release
BUILD_DIR   := .build/$(ARCH)-apple-macosx/$(CONFIG)
APP_BUNDLE  := $(APP_NAME).app
RES_BUNDLE  := $(APP_NAME)_$(APP_NAME).bundle
DMG_NAME    := $(APP_NAME)-$(VERSION).dmg
DMG_STAGING := /tmp/asmr-dmg-staging

# ──────────────────────────────────────────────
# First-time setup
# ──────────────────────────────────────────────

## Regenerate AppIcon.icns from scripts/make_icon.swift
icon:
	@echo "▶ Generating icon..."
	@swift scripts/make_icon.swift
	@mkdir -p /tmp/AppIcon.iconset
	@for s in 16 32 64 128 256 512 1024; do \
		sips -z $$s $$s /tmp/asmr_icon_1024.png \
		     --out /tmp/AppIcon.iconset/icon_$${s}x$${s}.png > /dev/null; \
	done
	@cp /tmp/AppIcon.iconset/icon_32x32.png    /tmp/AppIcon.iconset/icon_16x16@2x.png
	@cp /tmp/AppIcon.iconset/icon_64x64.png    /tmp/AppIcon.iconset/icon_32x32@2x.png
	@cp /tmp/AppIcon.iconset/icon_256x256.png  /tmp/AppIcon.iconset/icon_128x128@2x.png
	@cp /tmp/AppIcon.iconset/icon_512x512.png  /tmp/AppIcon.iconset/icon_256x256@2x.png
	@cp /tmp/AppIcon.iconset/icon_1024x1024.png /tmp/AppIcon.iconset/icon_512x512@2x.png
	@iconutil -c icns /tmp/AppIcon.iconset -o Sources/ASMR/Resources/AppIcon.icns
	@echo "✓ AppIcon.icns updated"

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
	@cp $(BUILD_DIR)/$(APP_NAME)                    $(APP_BUNDLE)/Contents/MacOS/
	@cp Info.plist                                  $(APP_BUNDLE)/Contents/
	@if [ -d "$(BUILD_DIR)/$(RES_BUNDLE)" ]; then \
		cp -r "$(BUILD_DIR)/$(RES_BUNDLE)" "$(APP_BUNDLE)/Contents/Resources/"; \
		echo "  ✓ Resource bundle copied"; \
	else \
		echo "  ⚠  Resource bundle not found (styles/template will use fallback)"; \
	fi
	@cp Sources/ASMR/Resources/AppIcon.icns         $(APP_BUNDLE)/Contents/Resources/
	@echo "  ✓ App icon copied"
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

## Create a distributable disk image (ASMR-x.y.z.dmg)
## Produces a compressed DMG with a drag-to-Applications layout.
## The SHA-256 printed at the end goes into the Homebrew Cask formula.
dmg: app
	@echo "▶ Creating $(DMG_NAME)..."
	@rm -rf "$(DMG_STAGING)" "$(DMG_NAME)"
	@mkdir -p "$(DMG_STAGING)"
	@cp -r "$(APP_BUNDLE)" "$(DMG_STAGING)/"
	@ln -s /Applications "$(DMG_STAGING)/Applications"
	@hdiutil create \
	    -volname "ASMR" \
	    -srcfolder "$(DMG_STAGING)" \
	    -ov -format UDZO \
	    -o "$(DMG_NAME)" > /dev/null
	@rm -rf "$(DMG_STAGING)"
	@echo "✓ $(DMG_NAME) ready"
	@printf "  SHA-256: "; shasum -a 256 "$(DMG_NAME)" | awk '{print $$1}'

# ──────────────────────────────────────────────
# Housekeeping
# ──────────────────────────────────────────────

## Remove all build artefacts
clean:
	swift package clean
	rm -rf $(APP_BUNDLE)

.PHONY: icon license resolve run build app open install dmg clean

# AirText - macOS Menu Bar Voice Input App
# Makefile for building, running, and installing the application

APP_NAME = AirText
BUNDLE_ID = com.airtext.app
BUILD_DIR = .build
APP_BUNDLE = $(APP_NAME).app
INSTALL_DIR = /Applications

# Swift build configuration (native architecture for compatibility)
SWIFT_BUILD_FLAGS = -c release

.PHONY: all build run install clean help

all: build

# Build the application
build:
	@echo "🔨 Building $(APP_NAME)..."
	swift build $(SWIFT_BUILD_FLAGS)
	@echo "📦 Creating app bundle..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$$(swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"
	@cp "Resources/Info.plist" "$(APP_BUNDLE)/Contents/"
	@if [ -d "Sources/AirText/Resources/Assets.xcassets" ]; then \
		xcrun actool "Sources/AirText/Resources/Assets.xcassets" \
			--compile "$(APP_BUNDLE)/Contents/Resources" \
			--platform macosx \
			--minimum-deployment-target 14.0 \
			--app-icon AppIcon \
			--output-partial-info-plist /dev/null 2>/dev/null || true; \
	fi
	@echo "🔏 Signing app bundle..."
	@codesign --force --deep --sign - "$(APP_BUNDLE)"
	@echo "✅ Build complete: $(APP_BUNDLE)"

# Build for debugging (faster)
debug:
	@echo "🔨 Building $(APP_NAME) (debug)..."
	swift build
	@echo "📦 Creating debug app bundle..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$$(swift build --show-bin-path)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"
	@cp "Resources/Info.plist" "$(APP_BUNDLE)/Contents/"
	@codesign --force --deep --sign - "$(APP_BUNDLE)"
	@echo "✅ Debug build complete: $(APP_BUNDLE)"

# Run the application (builds first if needed)
run: build
	@echo "🚀 Running $(APP_NAME)..."
	@open "$(APP_BUNDLE)"

# Run in debug mode
run-debug: debug
	@echo "🚀 Running $(APP_NAME) (debug)..."
	@"$$(swift build --show-bin-path)/$(APP_NAME)"

# Install to /Applications
install: build
	@echo "📲 Installing $(APP_NAME) to $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_BUNDLE)"
	@cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/"
	@echo "✅ Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"

# Uninstall from /Applications
uninstall:
	@echo "🗑️  Uninstalling $(APP_NAME)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_BUNDLE)"
	@echo "✅ Uninstalled"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	@swift package clean
	@rm -rf "$(BUILD_DIR)"
	@rm -rf "$(APP_BUNDLE)"
	@rm -rf .swiftpm
	@echo "✅ Clean complete"

# Show help
help:
	@echo "AirText - macOS Menu Bar Voice Input App"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build      Build release app bundle (universal binary)"
	@echo "  debug      Build debug version (faster, single arch)"
	@echo "  run        Build and run the app"
	@echo "  run-debug  Build debug and run in terminal"
	@echo "  install    Install to /Applications"
	@echo "  uninstall  Remove from /Applications"
	@echo "  clean      Remove all build artifacts"
	@echo "  help       Show this help message"

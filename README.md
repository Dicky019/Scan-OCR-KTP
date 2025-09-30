# Scan OCR KTP

iOS SwiftUI application for OCR scanning of Indonesian ID cards (KTP - Kartu Tanda Penduduk) with dual OCR engines (Apple Vision + Google MLKit).

## Features

- 📷 Camera capture for KTP scanning
- 🖼️ Gallery photo selection
- 🔍 Dual OCR engines (Apple Vision + Google MLKit)
- 📊 Performance comparison between OCR engines
- 🎯 Advanced KTP field extraction with regex
- 🧭 Coordinator pattern navigation
- 📝 Comprehensive logging system
- ✅ 67 unit and UI tests

## Requirements

- iOS 18.5+
- Xcode 16.4+
- Swift 5.0
- CocoaPods
- XcodeGen (for project generation)

## Setup

### 1. Install Dependencies

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Install CocoaPods dependencies
pod install
```

### 2. Generate Xcode Project

This project uses **XcodeGen** to generate the `.xcodeproj` from `project.yml`:

```bash
# Generate Xcode project
xcodegen generate

# Or use the shortcut
xcodegen
```

### 3. Open Workspace

```bash
# Always use the workspace (required for CocoaPods)
open "Scan OCR KTP.xcworkspace"
```

## Development Workflow

### Daily Development

1. **Make changes** to `project.yml` if you need to:
   - Add new source files
   - Modify build settings
   - Add dependencies
   - Change targets

2. **Regenerate project**:
   ```bash
   xcodegen
   ```

3. **Commit changes**:
   - Commit `project.yml` (source of truth)
   - `.xcodeproj` is gitignored (will be regenerated)
   - Commit `Scan OCR KTP.xcworkspace` (CocoaPods workspace)

### Adding New Files

XcodeGen automatically detects files in the configured directories:
- `App/` - Main application code
- `Tests/` - Unit tests
- `UITests/` - UI tests

Just create your file in the appropriate directory and run `xcodegen` to regenerate.

## Building

### Build for iOS Device (Required for MLKit)

```bash
xcodebuild -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS,name=YOUR_DEVICE_NAME' \
  build
```

### Build for iOS Simulator (Vision only)

```bash
xcodebuild -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

**Note**: MLKit frameworks don't support iOS Simulator linking. The app automatically falls back to Vision-only mode in simulator.

## Testing

### Run All Tests

```bash
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Run Unit Tests Only

```bash
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Scan_OCR_KTPTests
```

### Run UI Tests Only

```bash
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Scan_OCR_KTPUITests
```

## Project Structure

```
.
├── project.yml                 # XcodeGen configuration (source of truth)
├── Podfile                     # CocoaPods dependencies
├── Podfile.lock               # CocoaPods lock file
├── CLAUDE.md                   # Claude Code documentation
├── PLAN.md                     # Development plan and progress
├── App/                        # Main application
│   ├── App.swift              # App entry point
│   ├── ContentView.swift      # Root view
│   ├── Models/                # Data models
│   ├── Navigation/            # Coordinator pattern
│   ├── Services/              # OCR services and parsers
│   ├── Utils/                 # Utilities (Logger)
│   └── Views/                 # SwiftUI views
├── Tests/                      # Unit tests (43 tests)
│   └── Tests.swift
└── UITests/                    # UI tests (24 tests)
    ├── UITests.swift
    └── UITestsLaunchTests.swift
```

## Architecture

### Coordinator Pattern Navigation

- **NavigationCoordinator**: Manages navigation stack and image storage
- **AppRoute**: Defines all app routes
- **NavigationFactory**: Creates views for routes

### Dual OCR Engine

- **VisionOCRService**: Apple's Vision framework
- **MLKitOCRService**: Google MLKit
- **OCRManager**: Orchestrates both engines and compares results
- **KTPParser**: Extracts 14 KTP fields using advanced regex

### Logging System

- **OCRLogger**: Thread-safe logging with session tracking
- Performance metrics for both OCR engines
- Detailed field extraction logging

## XcodeGen Benefits

✅ **No Merge Conflicts**: No more `.xcodeproj` conflicts in git
✅ **Declarative**: Project structure defined in YAML
✅ **Consistency**: Same project structure across team members
✅ **Simple**: Easy to add files, targets, and settings
✅ **Version Control**: `project.yml` is human-readable and diffable

## CocoaPods Dependencies

- **GoogleMLKit/TextRecognition**: Google's ML Kit for text recognition

## Known Issues

- MLKit frameworks don't support iOS Simulator linking (build for physical device)
- visionOS support removed due to MLKit incompatibility

## Documentation

- See [CLAUDE.md](CLAUDE.md) for detailed architecture and development guidelines
- See [PLAN.md](PLAN.md) for feature checklist and progress

## License

Private project

## Team

Development Team ID: `6LKBYRNM9Y`
# Scan OCR KTP

iOS SwiftUI application for OCR scanning of Indonesian ID cards (KTP - Kartu Tanda Penduduk) with dual OCR engines (Apple Vision + Google MLKit) and Clean Architecture.

## Features

- 📷 Camera capture for KTP scanning
- 🖼️ Gallery photo selection
- 🔍 Dual OCR engines (Apple Vision + Google MLKit)
- 📊 Performance comparison between OCR engines
- 🎯 Advanced KTP field extraction with regex
- 🏗️ Clean Architecture with Domain, Data, and Presentation layers
- 💉 Dependency Injection with Swinject
- 🧭 Coordinator pattern navigation
- 📝 Comprehensive logging system
- ✅ Comprehensive unit and UI tests with Swift Testing

## Requirements

- iOS 18.5+
- Xcode 16.4+
- Swift 5.0
- CocoaPods

## Setup

### 1. Install Dependencies

```bash
# Install CocoaPods dependencies
pod install
```

### 2. Open Workspace

```bash
# Always use the workspace (required for CocoaPods)
open "Scan OCR KTP.xcworkspace"
```

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

### Test Organization

**Unit Tests** (Tests/):
- Organized by feature using Swift Testing framework
- Tagged for selective test execution
- Categories: Parser, OCR (Vision/MLKit/Dual), Models, Navigation

**UI Tests** (UITests/):
- Page Object Pattern for maintainability
- Optimized for faster execution (70% fewer tests)
- Categories: Home, Camera Flow, Gallery Flow, Navigation, Launch

## Project Structure

```
.
├── Podfile                           # CocoaPods dependencies
├── Podfile.lock                     # CocoaPods lock file
├── CLAUDE.md                         # Claude Code documentation
├── PLAN.md                           # Development plan and progress
├── App/                              # Main application
│   ├── App.swift                    # App entry point with DI setup
│   ├── Presentation/                # Views and ViewModels
│   │   ├── MainView.swift          # Root view with navigation
│   │   ├── HomeView.swift          # Home screen
│   │   ├── CameraView.swift        # Camera capture
│   │   ├── PhotoPickerView.swift  # Photo picker
│   │   ├── ImagePreviewView.swift # Image preview
│   │   └── OCRResultView.swift    # OCR results
│   ├── Domain/                      # Business logic layer
│   │   ├── Entities/               # Domain models (KTPData)
│   │   ├── UseCases/               # Business logic
│   │   └── Repositories/           # Repository protocols
│   ├── Data/                        # Data layer
│   │   ├── Repositories/           # Repository implementations
│   │   └── Services/               # External services
│   ├── Core/                        # Shared utilities
│   │   ├── DI/                     # Dependency Injection
│   │   ├── Logger/                 # Logging system
│   │   └── Navigation/             # Navigation coordinator
│   └── Resources/                   # Assets and resources
├── Tests/                            # Unit tests
│   ├── Helpers/                     # Test utilities
│   │   └── TestTags.swift          # Test tags
│   ├── Parser/                      # KTP parser tests
│   ├── OCR/                         # OCR engine tests
│   ├── Models/                      # Model tests
│   └── Navigation/                  # Navigation tests
└── UITests/                          # UI tests
    ├── Utils/                       # Test base classes
    ├── Helpers/                     # Test extensions
    ├── PageObjects/                 # Page object models
    └── Tests/                       # Test suites
```

## Architecture

### Clean Architecture Layers

**Presentation Layer** (App/Presentation/):
- SwiftUI views and view logic
- Coordinator pattern for navigation
- No direct dependency on data sources

**Domain Layer** (App/Domain/):
- Business logic and use cases
- Domain entities (KTPData, OCRResult)
- Repository protocols (interfaces)
- Independent of frameworks

**Data Layer** (App/Data/):
- Repository implementations
- OCR services (Vision, MLKit)
- External service integrations

**Core Layer** (App/Core/):
- Dependency Injection container (Swinject)
- Navigation coordinator
- Logging utilities

### Key Components

**Dependency Injection**:
- Container setup in App.swift
- Protocol-based dependencies
- Easy testing with mock implementations

**OCR Engine**:
- **VisionOCRService**: Apple's Vision framework
- **MLKitOCRService**: Google MLKit
- **ProcessKTPUseCase**: Orchestrates both engines and compares results
- **KTPParser**: Extracts 14 KTP fields using advanced regex

**Navigation**:
- **NavigationCoordinator**: Manages navigation stack and image storage
- Automatic cleanup of stored images (max 5)
- Timestamp-based management

**Logging System**:
- **OCRLogger**: Thread-safe logging with session tracking
- Performance metrics for both OCR engines
- Detailed field extraction logging

## Dependencies

### CocoaPods
- **GoogleMLKit/TextRecognition**: Google's ML Kit for text recognition
- **Swinject**: Dependency Injection container

### System Frameworks
- Vision: Apple's text recognition
- AVFoundation: Camera capture
- PhotosUI: Modern photo picker
- UIKit: Camera and picker wrappers

## Known Issues

- MLKit frameworks don't support iOS Simulator linking (build for physical device)
- Vision framework requires minimum 3x3 pixel images
- visionOS support removed due to MLKit incompatibility

## Documentation

- See [CLAUDE.md](CLAUDE.md) for detailed architecture and development guidelines
- See [PLAN.md](PLAN.md) for feature checklist and progress
- See [UITests/README.md](UITests/README.md) for UI testing guidelines

## License

Private project

## Team

Development Team ID: `6LKBYRNM9Y`

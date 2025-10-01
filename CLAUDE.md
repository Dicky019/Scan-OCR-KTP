# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS SwiftUI application for OCR scanning of Indonesian ID cards (KTP - Kartu Tanda Penduduk). Built with Xcode 16.4, targeting iOS 18.5+. The app features dual OCR engines (Apple Vision + Google MLKit) with performance comparison, coordinator-based navigation, and comprehensive logging.

**Bundle ID:** `com.diki.scan.ocr.ktp`
**Swift Version:** 5.0
**Minimum Deployment:** iOS 18.5

## Architecture

### Coordinator Pattern Navigation
The app uses a **Coordinator pattern** for navigation to maintain separation of concerns and testability:

- **NavigationCoordinator** (`App/Navigation/NavigationCoordinator.swift`): Main coordinator class marked with `@MainActor`. Manages navigation stack, image storage with timestamp-based cleanup (max 5 images), and provides navigation helpers.
- **AppRoute** (`App/Navigation/AppRoute.swift`): Enum defining all possible routes (home, camera, photoPicker, imagePreview, ocrResults) with associated values for parameters.
- **NavigationFactory** (`App/Navigation/NavigationFactory.swift`): Factory that creates views for routes and injects the coordinator as an environment object.

**Key Pattern:**
```swift
// In views: Navigate using coordinator
coordinator.push(to: .camera)
coordinator.navigateToImagePreview(with: image)
coordinator.pop()
coordinator.popToRoot()

// Images are stored in coordinator with automatic cleanup
let imageId = coordinator.storeImage(image)
let image = coordinator.getImage(by: imageId)
```

### Dual OCR Engine Architecture

The app processes images with **both** Apple Vision and Google MLKit simultaneously for comparison:

1. **OCRManager** (`App/Services/OCRManager.swift`): Marked with `@MainActor`. Orchestrates both OCR services, creates performance comparisons, and manages session logging.
2. **VisionOCRService** (`App/Services/VisionOCRService.swift`): Uses Apple's Vision framework with `VNRecognizeTextRequest`, configured for accurate recognition with English + Indonesian language support.
3. **MLKitOCRService** (`App/Services/MLKitOCRService.swift`): Uses Google MLKit Text Recognition. Uses `[weak self]` in nested callbacks to prevent retain cycles.
4. **KTPParser** (`App/Services/KTPParser.swift`): Parses raw OCR text into structured KTP fields using regex patterns for Indonesian ID card format.

**Important:** MLKit frameworks do NOT support iOS Simulator on Apple Silicon. The app automatically falls back to Vision-only mode in simulator via `#if targetEnvironment(simulator)`.

### View Architecture

All views follow the **Navigation View** pattern, integrating with the coordinator:

- **HomeView**: Entry point with Camera and Gallery buttons
- **CameraView**: `UIViewControllerRepresentable` wrapping `UIImagePickerController` for camera
- **PhotoPickerView**: `UIViewControllerRepresentable` wrapping `PHPickerViewController` for photo library
- **ImagePreviewView**: Shows captured image with "Process OCR" button
- **OCRResultView**: Displays dual OCR results with performance metrics and engine comparison

**Pattern:** Views inject coordinator via `@EnvironmentObject`, use state for local UI, and cancel tasks in `.onDisappear` for proper cleanup.

### Comprehensive Logging System

**OCRLogger** (`App/Utils/OCRLogger.swift`) provides structured logging with session tracking:

- Singleton with thread-safe access via `DispatchQueue` with barrier flags
- Session management: tracks multiple concurrent OCR operations
- Performance logging: start/end operations with timing
- Process logging: detailed step-by-step OCR pipeline
- Image capture logging: source, dimensions, timestamps
- Uses OSLog with categories: default, performance, process, ui, error

**All async closures use `[weak self]` to prevent retain cycles** even though it's a singleton.

## Development Commands

### CocoaPods Management
```bash
# Install/Update dependencies
pod install

# Deintegrate and reinstall (if issues occur)
pod deintegrate && pod install

# Update pods
pod update
```

**Always use `.xcworkspace` after pod install, NOT `.xcodeproj`**

### Building

```bash
# Build for iOS Device (REQUIRED for MLKit)
xcodebuild -workspace "Scan OCR KTP.xcworkspace" -scheme "Scan OCR KTP" \
  -destination 'platform=iOS,name=YOUR_DEVICE_NAME' build

# Build for iOS Simulator (Vision only - MLKit linking will fail)
xcodebuild -workspace "Scan OCR KTP.xcworkspace" -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Known Issue:** MLKit pre-compiled frameworks don't support iOS Simulator linking. Code compiles but linking fails. Build for physical devices to test MLKit.

### Testing

```bash
# Run all tests
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test target
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Scan_OCR_KTPTests

# Run UI tests
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Scan_OCR_KTPUITests
```

**Testing Framework:** Unit tests use Swift Testing (`import Testing`). UI tests use XCTest with `XCUIApplication`.

## Key Implementation Details

### Memory Management

**Critical patterns to maintain:**

1. **Image Storage Cleanup:** NavigationCoordinator stores images with timestamps and automatically removes oldest when exceeding `maxStoredImages` (5). Never sort by UUID strings - always sort by timestamp.

2. **Weak Self in Closures:** All async closures in OCRLogger and MLKitOCRService must use `[weak self]` capture lists with `guard let self = self else { return }` checks.

3. **Task Cancellation:** OCR processing views store tasks and cancel them in `.onDisappear` to prevent memory leaks and wasted processing.

4. **MainActor Annotation:** OCRManager and NavigationCoordinator are marked `@MainActor` to ensure thread-safe access.

### Error Handling Pattern

OCR processing uses this pattern:
```swift
processingTask = Task {
    do {
        let results = await ocrManager.processImage(image)
        guard !Task.isCancelled else { return }
        await MainActor.run {
            // Update UI
        }
    } catch {
        guard !Task.isCancelled else { return }
        await MainActor.run {
            // Handle error
        }
    }
}
```

### Camera and Photo Permissions

Permissions are configured in project build settings via `INFOPLIST_KEY_*`:
- `INFOPLIST_KEY_NSCameraUsageDescription`: "This app needs camera access to scan KTP documents"
- `INFOPLIST_KEY_NSPhotoLibraryUsageDescription`: "This app needs photo library access to select KTP images for scanning"

No separate Info.plist file - permissions are in project.pbxproj.

## Project Structure

```
App/
├── App.swift                           # Entry point with @main
├── ContentView.swift                   # Root view with NavigationStack
├── Models/
│   ├── ImageData.swift                 # CapturedImage model
│   └── KTPData.swift                   # KTP fields + OCRComparisonResult
├── Navigation/
│   ├── AppRoute.swift                  # Route enum with Hashable
│   ├── NavigationCoordinator.swift     # @MainActor coordinator with image storage
│   └── NavigationFactory.swift         # View factory for routes
├── Services/
│   ├── OCRManager.swift                # @MainActor orchestrator for dual OCR
│   ├── VisionOCRService.swift          # Apple Vision framework integration
│   ├── MLKitOCRService.swift           # Google MLKit integration
│   └── KTPParser.swift                 # Regex-based KTP field extraction
├── Utils/
│   └── OCRLogger.swift                 # Thread-safe logging with sessions
└── Views/
    ├── HomeView.swift                  # Main menu
    ├── CameraView.swift      # Camera capture wrapper
    ├── PhotoPickerView.swift # Photo picker wrapper
    ├── ImagePreviewView.swift # Image preview before OCR
    └── OCRResultView.swift   # Dual OCR results display

Tests/
└── Tests.swift                         # Swift Testing framework tests

UITests/
├── UITests.swift                       # XCTest UI tests
└── UITestsLaunchTests.swift           # Launch tests
```

## Dependencies

**CocoaPods** (`Podfile`):
- `GoogleMLKit/TextRecognition`: Google's ML Kit for text recognition

**System Frameworks:**
- Vision: Apple's text recognition
- AVFoundation: Camera capture
- PhotosUI: Modern photo picker (`PHPickerViewController`)
- UIKit: Camera and picker wrappers via `UIViewControllerRepresentable`

## Code Quality Standards

1. **Async/Await:** Use modern Swift concurrency throughout. Mark UI-updating code with `@MainActor` or wrap in `MainActor.run`.

2. **Weak Self:** Always use `[weak self]` in callbacks and async closures to prevent retain cycles, even in singletons.

3. **Task Cancellation:** Store long-running tasks and cancel in `.onDisappear` to prevent wasted resources.

4. **Image Memory:** Always consider memory impact when storing UIImages. Use coordinator's cleanup mechanism.

5. **Error Recovery:** OCR failures should be caught and logged. UI should show error states, not crash.

6. **Simulator Limitations:** Always check for simulator environment when using MLKit. Provide Vision fallback.

## Common Issues and Solutions

**Problem:** MLKit linking fails in simulator
**Solution:** This is expected. Test dual OCR on physical devices. Simulator automatically uses Vision-only mode.

**Problem:** "visionOS not supported" build error
**Solution:** Project is configured for iOS only now. visionOS support was removed due to MLKit incompatibility.

**Problem:** Large images causing memory pressure
**Solution:** NavigationCoordinator automatically cleans up old images (keeps last 5). Consider adding image downsampling before storage if needed.

**Problem:** OCR processing continues after view dismissed
**Solution:** Ensure views store `processingTask` and cancel it in `.onDisappear`.
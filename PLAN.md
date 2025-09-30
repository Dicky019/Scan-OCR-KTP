# Scan OCR KTP - Simple Sample App Plan

## Project Overview
Simple iOS sample app for capturing photos using camera or selecting from gallery. Basic demo untuk menunjukkan camera integration dan photo picker.

## Core Features

### 1. Camera Capture ✅
- [x] Camera permission handling
- [x] Basic camera preview dengan SwiftUI
- [x] Capture button untuk ambil foto
- [x] Simpan foto ke temporary storage (via NavigationCoordinator)

### 2. Gallery Selection ✅
- [x] Photo picker integration
- [x] Select image dari gallery
- [x] Display selected image

### 3. OCR Processing (2 Options) ✅
- [x] **Option A: Vision Framework** (Apple's built-in)
  - [x] Integrate Vision framework
  - [x] VNRecognizeTextRequest untuk text recognition
  - [x] Extract text dari captured/selected image
- [x] **Option B: MLKit** (Google's ML Kit)
  - [x] Add MLKit Text Recognition dependency
  - [x] Integrate MLKit TextRecognition
  - [x] Compare accuracy dengan Vision
- [x] Create OCR comparison interface
- [x] Allow user to choose OCR engine

### 4. Data Parsing ✅
- [x] Parse extracted text untuk KTP fields
- [x] Basic field detection (NIK, Nama, etc.)
- [x] Advance field detection using regex (NIK, Nama, etc.)
- [x] Simple validation

### 5. Simple UI ✅
- [x] Main screen dengan 2 buttons: "Camera" & "Gallery"
- [x] Image preview screen
- [x] OCR results screen
- [x] Basic navigation (Coordinator pattern)

## Technical Stack
- **SwiftUI** - UI framework
- **AVFoundation** - Camera functionality
- **PhotosUI** - Photo picker
- **Vision** - Apple's OCR text recognition
- **MLKit** - Google's ML Kit Text Recognition
- **UIKit** (wrapped) - Camera interface

## Simple Architecture
```
App/
├── Views/
│   ├── ContentView.swift      # Main screen
│   ├── CameraView.swift       # Camera capture
│   ├── ImagePreviewView.swift # Show captured/selected image
│   └── OCRResultView.swift    # Show extracted data
├── Services/
│   ├── VisionOCRService.swift # Apple Vision OCR processing
│   ├── MLKitOCRService.swift  # Google MLKit OCR processing
│   ├── OCRManager.swift       # Manage both OCR services
│   └── KTPParser.swift        # Parse text to KTP fields
└── Models/
    ├── ImageData.swift        # Simple image model
    └── KTPData.swift          # KTP fields model
```

## Development Timeline (2-3 Days) ✅ COMPLETED

### Day 1: Camera & Gallery ✅
- [x] Setup camera permissions di Info.plist
- [x] Create main UI dengan 2 buttons
- [x] Implement camera capture view
- [x] Add photo picker functionality
- [x] Basic image capture & selection

### Day 2: OCR Integration ✅
- [x] Integrate Vision framework
- [x] Create VisionOCRService untuk Apple's text recognition
- [x] Add MLKit dependency via SPM/CocoaPods
- [x] Create MLKitOCRService untuk Google's text recognition
- [x] Create OCRManager untuk manage both services
- [x] Basic text extraction dari image dengan both methods

### Day 3: KTP Parsing & UI ✅
- [x] Create KTPParser untuk parse text dari both OCR engines
- [x] Extract KTP fields (NIK, Nama, etc.)
- [x] Create OCRResultView dengan comparison results
- [x] Show results dari Vision vs MLKit side by side
- [x] Add OCR engine selector
- [x] Basic validation & error handling

### Bonus: Production-Ready Enhancements ✅
- [x] Implement Coordinator pattern navigation
- [x] Add comprehensive OCRLogger with session tracking
- [x] Memory management with timestamp-based image cleanup
- [x] Task cancellation support for OCR processing
- [x] Error handling with proper try-catch blocks
- [x] Thread safety with @MainActor annotations
- [x] Weak self capture in all closures to prevent memory leaks
- [x] Performance comparison UI with metrics visualization

### Testing Suite ✅
- [x] Unit tests for KTPParser (18 tests covering all field extractions)
- [x] Unit tests for OCRManager and comparison logic
- [x] Unit tests for data models (KTPData, ImageData, OCREngine)
- [x] Unit tests for NavigationCoordinator
- [x] UI tests for app launch and home screen
- [x] UI tests for camera flow navigation
- [x] UI tests for gallery flow navigation
- [x] UI tests for complete navigation flows
- [x] UI tests for accessibility
- [x] UI tests for memory management
- [x] Performance tests for app launch and navigation

### Project Management ✅
- [x] XcodeGen integration for project generation
- [x] project.yml as source of truth for project structure
- [x] fixme.sh script for automated environment setup
- [x] README.md with comprehensive documentation
- [x] .gitignore configured for XcodeGen workflow
- [x] Automated dependency installation (Homebrew, XcodeGen, CocoaPods)

## Data Models
```swift
struct CapturedImage {
    let image: UIImage
    let source: ImageSource
    let timestamp: Date
}

enum ImageSource {
    case camera
    case gallery
}

struct KTPData {
    let nik: String?
    let nama: String?
    let tempatLahir: String?
    let tanggalLahir: String?
    let jenisKelamin: String?
    let alamat: String?
    let rtRw: String?
    let kelurahan: String?
    let kecamatan: String?
    let agama: String?
    let statusPerkawinan: String?
    let pekerjaan: String?
    let kewarganegaraan: String?
    let berlakuHingga: String?
    let rawText: String // Original OCR text
    let confidence: Double
    let ocrEngine: OCREngine // Which engine was used
}

enum OCREngine {
    case vision
    case mlkit
}

struct OCRResult {
    let visionResult: KTPData?
    let mlkitResult: KTPData?
    let processingTime: (vision: Double, mlkit: Double)
}
```

## Key Features
- Camera capture ✅
- Gallery selection ✅
- Image preview ✅
- **Dual OCR engines** (Vision + MLKit) ✅
- **OCR comparison** & accuracy testing ✅
- KTP data parsing ✅
- **Side-by-side results** display ✅
- OCR engine selector ✅
- Processing time comparison ✅
- Basic navigation ✅

## Dependencies to Add
```swift
// Package.swift or CocoaPods
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
// Add: GoogleMLKit/TextRecognition
```

**Enhanced sample app untuk compare Vision vs MLKit OCR accuracy untuk Indonesian KTP text recognition.**
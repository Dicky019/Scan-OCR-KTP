# Clean Architecture Documentation

## Overview

This project follows **Clean Architecture** and **SOLID principles** for maintainability, testability, and scalability.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  ┌─────────────┐     ┌──────────────┐  │
│  │  ViewModels │     │    Views     │  │
│  └─────────────┘     └──────────────┘  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│          Domain Layer                   │
│  ┌─────────────┐     ┌──────────────┐  │
│  │  Use Cases  │     │   Entities   │  │
│  └─────────────┘     └──────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │    Repository Protocols          │  │
│  └──────────────────────────────────┘  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│           Data Layer                    │
│  ┌──────────────────────────────────┐  │
│  │  Repository Implementations      │  │
│  └──────────────────────────────────┘  │
│  ┌─────────────┐     ┌──────────────┐  │
│  │  Services   │     │   Adapters   │  │
│  └─────────────┘     └──────────────┘  │
└─────────────────────────────────────────┘
```

## Directory Structure

```
App/
├── Domain/                      # Business Logic (Pure Swift)
│   ├── Entities/               # Data models
│   │   └── OCRResult.swift
│   ├── UseCases/               # Business rules
│   │   └── ProcessKTPImageUseCase.swift
│   └── Repositories/           # Protocols (abstractions)
│       └── OCRRepositoryProtocol.swift
│
├── Data/                        # Data Sources
│   ├── Repositories/           # Repository implementations
│   │   └── OCRRepository.swift
│   ├── Services/               # OCR engines
│   │   ├── VisionOCRServiceAdapter.swift
│   │   ├── VisionOCRService.swift (legacy)
│   │   └── MLKitOCRService.swift (legacy)
│   └── Parsers/                # Data parsers
│       └── KTPParserAdapter.swift
│
├── Presentation/                # UI Layer
│   ├── ViewModels/             # MVVM ViewModels
│   │   └── OCRProcessingViewModel.swift
│   └── Views/                  # SwiftUI Views
│       ├── HomeView.swift
│       ├── CameraNavigationView.swift
│       ├── PhotoPickerNavigationView.swift
│       └── OCRResultNavigationView.swift
│
├── Core/                        # Shared components
│   ├── DI/                     # Dependency Injection
│   │   └── DIContainer.swift
│   └── Utils/                  # Utilities
│       ├── OCRLogger.swift (legacy)
│       └── OCRLoggerAdapter.swift
│
├── Navigation/                  # App navigation
│   ├── NavigationCoordinator.swift
│   └── AppRoute.swift
│
└── Models/                      # Legacy models (to be migrated)
    ├── KTPData.swift
    └── ImageData.swift
```

## SOLID Principles Implementation

### 1. **Single Responsibility Principle (SRP)**

Each class has one reason to change:

- `ProcessKTPImageUseCase` - handles KTP processing business logic
- `OCRRepository` - coordinates OCR services
- `OCRProcessingViewModel` - manages presentation state
- `VisionOCRService` - performs Vision OCR only
- `MLKitOCRService` - performs MLKit OCR only

### 2. **Open/Closed Principle (OCP)**

Open for extension, closed for modification:

```swift
// Add new OCR engine without modifying existing code
class CustomOCRServiceAdapter: OCRServiceProtocol {
    // New implementation
}

// Register in DIContainer
let customService = CustomOCRServiceAdapter()
```

### 3. **Liskov Substitution Principle (LSP)**

Subtypes are substitutable:

```swift
// Any OCRServiceProtocol can replace another
let service: OCRServiceProtocol = VisionOCRServiceAdapter()
let service2: OCRServiceProtocol = MLKitOCRServiceAdapter()
```

### 4. **Interface Segregation Principle (ISP)**

Specific interfaces for specific needs:

- `OCRServiceProtocol` - OCR operations only
- `KTPParserProtocol` - parsing only
- `LoggerProtocol` - logging only

### 5. **Dependency Inversion Principle (DIP)**

Depend on abstractions, not concretions:

```swift
// ViewModel depends on protocol, not concrete implementation
init(processKTPUseCase: ProcessKTPImageUseCase, logger: LoggerProtocol)

// Not: init(logger: OCRLogger)
```

## Design Patterns Used

### 1. **Repository Pattern**

Abstracts data sources:

```swift
protocol OCRRepositoryProtocol {
    func recognizeText(...) async -> Result<OCRResult, OCRError>
}
```

### 2. **Use Case Pattern**

Encapsulates business logic:

```swift
class ProcessKTPImageUseCase {
    func execute(image: UIImage) async -> Result<KTPData, OCRError>
}
```

### 3. **Adapter Pattern**

Makes legacy code conform to protocols:

```swift
class VisionOCRServiceAdapter: OCRServiceProtocol {
    private let visionService: VisionOCRService
}
```

### 4. **Dependency Injection**

Centralized dependency management:

```swift
class DIContainer {
    func makeOCRRepository() -> OCRRepositoryProtocol
    func makeProcessKTPImageUseCase() -> ProcessKTPImageUseCase
}
```

### 5. **MVVM Pattern**

Separates presentation from view:

```swift
@MainActor
class OCRProcessingViewModel: ObservableObject {
    @Published var state: ViewState
    func processImage(_ image: UIImage) async
}
```

## Benefits

### Testability

```swift
// Easy to mock dependencies for testing
class MockOCRRepository: OCRRepositoryProtocol {
    func recognizeText(...) async -> Result<OCRResult, OCRError> {
        return .success(mockResult)
    }
}

let useCase = ProcessKTPImageUseCase(
    ocrRepository: MockOCRRepository(),
    ktpParser: MockParser(),
    logger: MockLogger()
)
```

### Maintainability

- **Clear separation of concerns** - each layer has specific responsibility
- **Independent layers** - changes in UI don't affect business logic
- **Protocol-based** - easy to swap implementations

### Scalability

- **Add new features** - create new use cases
- **Add new OCR engines** - implement `OCRServiceProtocol`
- **Add new views** - reuse existing ViewModels

## Migration Strategy

### Current (Legacy)

```swift
// Tightly coupled
class OCRResultView {
    let ocrManager = OCRManager()
    ocrManager.processImage(image)
}
```

### New (Clean Architecture)

```swift
// Loosely coupled, testable
class OCRResultView {
    @StateObject var viewModel = OCRProcessingViewModel()
    viewModel.processImage(image, engine: .vision)
}
```

### Backward Compatibility

Legacy code continues to work:
- `OCRManager` - still functional
- `VisionOCRService` - wrapped by adapter
- `MLKitOCRService` - wrapped by adapter
- Existing views - can be migrated incrementally

## Usage Examples

### Create ViewModel with DI

```swift
let viewModel = OCRProcessingViewModel(container: .shared)
```

### Process Image

```swift
await viewModel.processImage(image, engine: .vision)

if viewModel.hasResult {
    print(viewModel.ktpData)
}
```

### Custom Dependencies (Testing)

```swift
let mockRepository = MockOCRRepository()
let mockParser = MockKTPParser()
let mockLogger = MockLogger()

let useCase = ProcessKTPImageUseCase(
    ocrRepository: mockRepository,
    ktpParser: mockParser,
    logger: mockLogger
)

let viewModel = OCRProcessingViewModel(
    processKTPUseCase: useCase,
    logger: mockLogger
)
```

## Testing Strategy

### Unit Tests

```swift
// Test use cases in isolation
func testProcessKTPImageSuccess() async {
    let useCase = ProcessKTPImageUseCase(
        ocrRepository: MockOCRRepository(),
        ktpParser: MockParser(),
        logger: MockLogger()
    )

    let result = await useCase.execute(image: testImage, engine: .vision)

    XCTAssertTrue(result.isSuccess)
}
```

### Integration Tests

```swift
// Test repository with real services
func testOCRRepositoryIntegration() async {
    let repository = DIContainer.shared.makeOCRRepository()
    let result = await repository.recognizeText(
        from: testImage,
        using: .vision,
        sessionId: nil
    )

    XCTAssertTrue(result.isSuccess)
}
```

## Next Steps

1. ✅ Migrate `OCRResultNavigationView` to use `OCRProcessingViewModel`
2. ✅ Create `HomeViewModel` for home screen logic
3. ✅ Add unit tests for new architecture
4. ✅ Update documentation
5. ✅ Gradual migration of remaining views

## References

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
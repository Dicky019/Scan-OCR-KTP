# Test Suite Organization

Test suite untuk aplikasi Scan OCR KTP, diorganisir berdasarkan best practices Swift Testing.

## 📁 Struktur Direktori

```
Tests/
├── Helpers/
│   └── TestTags.swift              # Shared test tags untuk filtering
├── Parser/
│   └── KTPParserTests.swift        # Tests untuk KTP field parsing
├── OCR/
│   ├── VisionOCRTests.swift        # Tests untuk Apple Vision OCR
│   ├── MLKitOCRTests.swift         # Tests untuk Google MLKit OCR
│   └── DualEngineTests.swift       # Tests untuk dual engine comparison
├── Models/
│   └── ModelTests.swift            # Tests untuk data models
└── Navigation/
    └── NavigationTests.swift       # Tests untuk navigation coordinator
```

## 🏷️ Test Tags

Tests diorganisir menggunakan tags untuk filtering yang mudah:

- **`parser`** - Parser dan regex extraction tests
- **`ocr`** - OCR processing tests (Vision, MLKit)
- **`vision`** - Spesifik Apple Vision framework
- **`mlkit`** - Spesifik Google MLKit framework
- **`performance`** - Performance dan timing tests
- **`integration`** - Multi-component integration tests
- **`models`** - Data structure dan model tests
- **`navigation`** - Navigation dan coordinator tests

## 🚀 Menjalankan Tests

### Run Semua Tests
```bash
swift test
```

### Run Tests Berdasarkan Tag
```bash
# Hanya parser tests
swift test --filter tag:parser

# Hanya Vision OCR tests
swift test --filter tag:vision

# Hanya MLKit OCR tests (requires device)
swift test --filter tag:mlkit

# Hanya performance tests
swift test --filter tag:performance

# Kombinasi tags
swift test --filter "tag:ocr AND tag:vision"
swift test --filter "tag:performance OR tag:integration"
```

### Run Tests Berdasarkan Suite
```bash
# Run specific suite
swift test --filter "KTP Parser"
swift test --filter "Vision OCR"
swift test --filter "Navigation"
```

### Run Tests di Xcode
```bash
# Run all tests
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific tag
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Scan_OCR_KTPTests/KTPParserTests
```

## 📝 Best Practices

### 1. Suite Organization
- ✅ Gunakan `@Suite` dengan descriptive names
- ✅ Tambahkan tags yang relevan
- ✅ Gunakan nested suites untuk sub-kategorisasi
- ✅ Gunakan `.serialized` hanya jika diperlukan

```swift
@Suite("Vision OCR", .tags(.vision, .ocr), .serialized)
@MainActor
struct VisionOCRTests {
  // tests...
}
```

### 2. Test Naming
- ✅ Gunakan descriptive test names tanpa prefix "test"
- ✅ Function names harus jelas dan concise
- ✅ Gunakan `@Test` attribute dengan description

```swift
@Test("Extracts NIK from valid text")
func extractNIK() async throws {
  // test implementation
}
```

### 3. Assertions
- ✅ Gunakan `#expect()` untuk assertions
- ✅ Gunakan `#require()` untuk unwrapping
- ✅ Gunakan `Issue.record()` untuk custom failures

```swift
#expect(result.nik == "3174051234567890")
let unwrapped = try #require(optionalValue)
Issue.record("Custom error message")
```

### 4. Async Testing
- ✅ Gunakan `async throws` untuk async tests
- ✅ Gunakan `await` untuk async operations
- ✅ Mark suite dengan `@MainActor` jika diperlukan

```swift
@Test("Processes image successfully")
func processesImage() async throws {
  let result = await manager.processImage(image)
  #expect(result != nil)
}
```

## ⚠️ Catatan Penting

### MLKit Tests
MLKit framework **tidak support iOS Simulator** di Apple Silicon. Tests dengan tag `.mlkit` hanya akan berjalan di physical device:

```swift
#if !targetEnvironment(simulator)
@Suite("MLKit OCR", .tags(.mlkit))
struct MLKitOCRTests {
  // MLKit tests
}
#endif
```

### Performance Tests
Performance tests diberi tag `.performance` untuk filtering:

```swift
@Test("Completes within acceptable time", .tags(.performance))
func performance() async throws {
  // timing tests
}
```

## 📊 Coverage

Untuk melihat test coverage:

```bash
# Generate coverage report
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES
```

## 🔧 Troubleshooting

### Tests tidak ditemukan
Pastikan semua test files sudah ditambahkan ke test target di Xcode.

### MLKit tests failed di simulator
Ini expected behavior. Jalankan di physical device atau filter out dengan:
```bash
swift test --filter "NOT tag:mlkit"
```

### Serial execution
Jika tests memiliki shared state, gunakan `.serialized`:
```swift
@Suite("My Suite", .serialized)
struct MyTests { }
```

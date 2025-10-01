# UI Tests

UI test suite untuk Scan OCR KTP menggunakan XCTest dengan **Page Object Pattern** untuk maintainability yang lebih baik.

## 📁 Struktur Direktori

```
UITests/
├── Helpers/
│   ├── UITestBase.swift               # Base class untuk semua UI tests
│   └── XCTestCase+Extensions.swift    # Helper extensions
├── PageObjects/
│   ├── HomeScreen.swift               # Page Object untuk Home screen
│   ├── CameraScreen.swift             # Page Object untuk Camera screen
│   └── GalleryScreen.swift            # Page Object untuk Gallery screen
└── Tests/
    ├── HomeScreenTests.swift          # Tests untuk Home screen
    ├── CameraFlowTests.swift          # Tests untuk Camera flow
    ├── GalleryFlowTests.swift         # Tests untuk Gallery flow
    ├── NavigationTests.swift          # Tests untuk navigation
    └── LaunchTests.swift              # Tests untuk app launch
```

## 🎯 Page Object Pattern

### Apa itu Page Object Pattern?

Page Object Pattern adalah design pattern untuk UI testing yang memisahkan:
- **Test logic** (apa yang di-test)
- **UI structure** (bagaimana mengakses UI elements)

### Keuntungan

✅ **Maintainable** - Jika UI berubah, hanya update page object
✅ **Reusable** - Page objects bisa dipakai di banyak tests
✅ **Readable** - Test code lebih mudah dibaca
✅ **DRY** - Tidak ada duplikasi kode UI access

### Contoh Penggunaan

```swift
// ❌ Tanpa Page Object (Bad)
func testCameraNavigation() {
  app.buttons["Camera"].tap()
  XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).exists)
  app.navigationBars.buttons.element(boundBy: 0).tap()
}

// ✅ Dengan Page Object (Good)
func testCameraNavigation() {
  homeScreen.tapCameraButton()
  cameraScreen.assertBackButtonExists()
  cameraScreen.tapBackButton()
}
```

## 🚀 Menjalankan UI Tests

### Dari Command Line

```bash
# Run semua UI tests
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Scan_OCR_KTPUITests

# Run specific test class
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Scan_OCR_KTPUITests/HomeScreenTests

# Run specific test method
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:Scan_OCR_KTPUITests/HomeScreenTests/testHomeScreenDisplays
```

### Dari Xcode

1. Open **Test Navigator** (⌘6)
2. Klik **Run** pada test yang diinginkan
3. Atau use keyboard shortcut **⌘U** untuk run semua tests

## 📝 Best Practices

### 1. Inherit dari UITestBase

Semua test classes harus inherit dari `UITestBase`:

```swift
final class MyTests: UITestBase {
  // app property sudah tersedia
  // setUp dan tearDown sudah handled
}
```

### 2. Gunakan Page Objects

Buat page object di `setUpWithError()`:

```swift
var homeScreen: HomeScreen!

override func setUpWithError() throws {
  try super.setUpWithError()
  homeScreen = HomeScreen(app: app)
}
```

### 3. Gunakan Helper Extensions

```swift
// Wait dengan verification
waitForElement(element, timeout: 5)

// Safe tap dengan wait
safeTap(element)

// Wait for navigation
waitForNavigation()

// Take screenshot
takeScreenshot(named: "Home Screen")
```

### 4. Test Naming Convention

- ✅ `testHomeScreenDisplays` - Descriptive, starts with "test"
- ✅ `testCameraNavigationPerformance` - Clear intent
- ❌ `test1` - Not descriptive
- ❌ `checkCamera` - Doesn't start with "test"

### 5. Organize Tests by Category

```swift
// MARK: - Display Tests
func testHomeScreenDisplays() { }

// MARK: - Navigation Tests
func testNavigateToCameraScreen() { }

// MARK: - Performance Tests
func testCameraNavigationPerformance() { }
```

### 6. Use Assertions dari Page Objects

```swift
// ✅ Good - assertions in page object
homeScreen.assertIsDisplayed()
homeScreen.assertButtonsAreEnabled()

// ❌ Avoid - direct assertions in tests
XCTAssertTrue(app.buttons["Camera"].exists)
XCTAssertTrue(app.buttons["Gallery"].exists)
```

## 🎨 Membuat Page Object Baru

### Template

```swift
//
//  MyScreen.swift
//  Scan OCR KTP UITests
//

import XCTest

struct MyScreen {

  let app: XCUIApplication

  // MARK: - Elements

  var myButton: XCUIElement {
    app.buttons["My Button"]
  }

  var myLabel: XCUIElement {
    app.staticTexts["My Label"]
  }

  // MARK: - Actions

  @discardableResult
  func tapMyButton() -> Bool {
    guard myButton.waitForExistence(timeout: 3) else {
      return false
    }
    myButton.tap()
    return true
  }

  // MARK: - Assertions

  func assertIsDisplayed() {
    XCTAssertTrue(myLabel.exists, "My screen should be displayed")
  }
}
```

## 🔧 Helper Methods

### UITestBase

- `returnToHome()` - Navigate back to home screen
- `handlePermissionAlert(allow:)` - Handle system permission alerts
- `assertAppIsRunning()` - Verify app is running

### XCTestCase Extensions

- `waitForElement(_:timeout:)` - Wait for element dengan verification
- `waitForElementToDisappear(_:timeout:)` - Wait for element to disappear
- `safeTap(_:timeout:)` - Tap dengan wait dan verification
- `waitForNavigation(timeout:)` - Wait for navigation animation
- `takeScreenshot(named:lifetime:)` - Capture screenshot

### XCUIElement Extensions

- `isVisibleAndHittable` - Check if element is visible AND hittable
- `forceTap()` - Force tap even if not hittable
- `waitAndTap(timeout:)` - Wait dan tap dalam satu call

## 📊 Performance Testing

UI tests include performance metrics:

```swift
func testAppLaunchPerformance() throws {
  measure(metrics: [XCTApplicationLaunchMetric()]) {
    XCUIApplication().launch()
  }
}

func testCameraNavigationPerformance() throws {
  measure(metrics: [XCTClockMetric()]) {
    homeScreen.tapCameraButton()
    cameraScreen.tapBackButton()
  }
}
```

## 🐛 Troubleshooting

### Tests gagal di CI/CD

Pastikan:
- Simulator sudah di-boot
- Keyboard shortcuts disabled: `defaults write com.apple.iphonesimulator ConnectHardwareKeyboard 0`
- Accessibility permissions granted

### Element tidak ditemukan

1. Check accessibility identifier di app code
2. Gunakan Xcode's Accessibility Inspector
3. Add delay: `waitForNavigation()` atau `usleep()`
4. Check device orientation

### Flaky tests

1. Add proper waits: `waitForElement()` instead of `sleep()`
2. Use `waitForExistence(timeout:)` instead of checking `exists` directly
3. Handle system alerts dengan `handlePermissionAlert()`
4. Reset app state di `setUpWithError()`

## 📱 Testing di Physical Device

Untuk test camera dan gallery dengan real hardware:

```bash
# List devices
xcrun xctrace list devices

# Run on device
xcodebuild test -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS,name=YOUR_DEVICE_NAME' \
  -only-testing:Scan_OCR_KTPUITests
```

## 🎯 Coverage

UI tests focus on:
- ✅ User flows (navigation, interaction)
- ✅ UI element visibility
- ✅ Accessibility
- ✅ Performance metrics
- ✅ Error handling

UI tests do NOT cover:
- ❌ Business logic (use unit tests)
- ❌ OCR processing (use unit/integration tests)
- ❌ Data validation (use unit tests)

## 📚 Referensi

- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [UI Testing in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)
- [Page Object Pattern](https://martinfowler.com/bliki/PageObject.html)

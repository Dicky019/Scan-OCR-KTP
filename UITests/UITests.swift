//
//  UITests.swift
//  Scan OCR KTP UITests
//
//  Created by Dicky Darmawan on 29/09/25.
//

import XCTest

final class Scan_OCR_KTPUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()

    // Suppress verbose system logging
    app.launchEnvironment = [
      "OS_ACTIVITY_MODE": "disable",
      "IDEPreferLogStreaming": "NO"
    ]

    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - App Launch Tests

  @MainActor
  func testAppLaunches() throws {
    // Verify app launches successfully
    XCTAssertTrue(app.state == .runningForeground)
  }

  @MainActor
  func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }

  // MARK: - Home Screen Tests

  @MainActor
  func testHomeScreenElements() throws {
    // Verify home screen has required elements
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists, "App title should exist")
    XCTAssertTrue(app.buttons["Camera"].exists, "Camera button should exist")
    XCTAssertTrue(app.buttons["Gallery"].exists, "Gallery button should exist")
  }

  @MainActor
  func testHomeScreenDescription() throws {
    // Check if description text exists
    let descriptionText = app.staticTexts["Capture or select a KTP image to extract information"]
    XCTAssertTrue(descriptionText.waitForExistence(timeout: 2), "Description text should exist")
  }

  @MainActor
  func testButtonsAreInteractive() throws {
    let cameraButton = app.buttons["Camera"]
    let galleryButton = app.buttons["Gallery"]

    // Verify buttons exist and are enabled
    XCTAssertTrue(cameraButton.exists)
    XCTAssertTrue(cameraButton.isEnabled)
    XCTAssertTrue(galleryButton.exists)
    XCTAssertTrue(galleryButton.isEnabled)
  }

  @MainActor
  func testNavigationBarExists() throws {
    // Check navigation bar on home screen
    let navigationBar = app.navigationBars.firstMatch
    XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")
  }

  // MARK: - Accessibility Tests

  @MainActor
  func testAccessibilityLabels() throws {
    // Verify important elements have accessibility
    let cameraButton = app.buttons["Camera"]
    XCTAssertTrue(cameraButton.exists)
    XCTAssertNotEqual(cameraButton.label, "", "Camera button should have accessibility label")

    let galleryButton = app.buttons["Gallery"]
    XCTAssertTrue(galleryButton.exists)
    XCTAssertNotEqual(galleryButton.label, "", "Gallery button should have accessibility label")
  }

  // MARK: - State Persistence Tests

  @MainActor
  func testAppStateAfterBackground() throws {
    // Launch app
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)

    // Send app to background
    XCUIDevice.shared.press(.home)
    sleep(1)

    // Bring back to foreground
    app.activate()
    sleep(1)

    // Verify home screen still visible
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists, "Home screen should persist after backgrounding")
  }

  // MARK: - Icon and Image Tests

  @MainActor
  func testAppIconsDisplay() throws {
    // Check if camera icon exists
    let cameraIcon = app.images.matching(identifier: "camera.fill").firstMatch
    let photoIcon = app.images.matching(identifier: "photo.fill").firstMatch

    // At least one should exist (icons in buttons)
    XCTAssertTrue(cameraIcon.exists || photoIcon.exists, "Icons should be displayed")
  }

  // MARK: - Layout Tests

  @MainActor
  func testPortraitLayout() throws {
    // Ensure device is in portrait
    XCUIDevice.shared.orientation = .portrait
    sleep(1)

    // Verify elements are visible
    XCTAssertTrue(app.buttons["Camera"].exists)
    XCTAssertTrue(app.buttons["Gallery"].exists)
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)
  }

  @MainActor
  func testLandscapeLayout() throws {
    // Test landscape orientation
    XCUIDevice.shared.orientation = .landscapeLeft
    sleep(1)

    // Verify elements are still accessible
    XCTAssertTrue(app.buttons["Camera"].exists || app.buttons["Camera"].isHittable)
    XCTAssertTrue(app.buttons["Gallery"].exists || app.buttons["Gallery"].isHittable)

    // Return to portrait
    XCUIDevice.shared.orientation = .portrait
  }

  // MARK: - Complete Flow Tests

  @MainActor
  func testHomeToBackNavigationFlow() throws {
    // Start at home
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)

    // Go to Camera
    app.buttons["Camera"].tap()
    sleep(1)

    // Go back
    if app.navigationBars.buttons.element(boundBy: 0).exists {
      app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    sleep(1)

    // Verify back at home
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)

    // Go to Gallery
    app.buttons["Gallery"].tap()
    sleep(1)

    // Go back
    if app.navigationBars.buttons.element(boundBy: 0).exists {
      app.navigationBars.buttons.element(boundBy: 0).tap()
    } else if app.buttons["Cancel"].exists {
      app.buttons["Cancel"].tap()
    }
    sleep(1)

    // Verify back at home
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)
  }

  @MainActor
  func testNavigationStackDepth() throws {
    // Start at home (depth 0)
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)

    // Navigate to camera (depth 1)
    app.buttons["Camera"].tap()
    XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 2))

    // Verify we can go back (only 1 level deep)
    app.navigationBars.buttons.element(boundBy: 0).tap()
    XCTAssertTrue(app.staticTexts["KTP Scanner"].waitForExistence(timeout: 2))
  }
}

// MARK: - Performance Tests

final class Scan_OCR_KTPPerformanceTests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
  }

  @MainActor
  func testAppLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      app.launch()
    }
  }
}
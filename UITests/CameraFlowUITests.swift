//
//  CameraFlowUITests.swift
//  Scan OCR KTP UITests
//
//  Created by Dicky Darmawan on 30/09/25.
//

import XCTest

final class CameraFlowUITests: XCTestCase {

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

  // MARK: - Camera Navigation Tests

  @MainActor
  func testNavigationToCameraView() throws {
    // Tap camera button
    let cameraButton = app.buttons["Camera"]
    XCTAssertTrue(cameraButton.exists, "Camera button should exist")
    cameraButton.tap()

    // Verify navigation happened (check for back button or camera UI)
    let backButton = app.navigationBars.buttons.element(boundBy: 0)
    XCTAssertTrue(backButton.waitForExistence(timeout: 3), "Navigation should show back button")
  }

  @MainActor
  func testCameraFlowNavigation() throws {
    // Tap Camera button
    let cameraButton = app.buttons["Camera"]
    cameraButton.tap()

    // Check if camera permission alert appears or camera view loads
    // Note: Actual camera testing requires physical device
    let navigationBar = app.navigationBars.firstMatch
    XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Camera view should load")
  }

  @MainActor
  func testCameraViewHasTitle() throws {
    app.buttons["Camera"].tap()

    // Wait for navigation
    let captureTitle = app.staticTexts["Capture Image"]
    XCTAssertTrue(captureTitle.waitForExistence(timeout: 3), "Camera view should have title")
  }

  @MainActor
  func testCameraBackNavigation() throws {
    // Navigate to camera
    app.buttons["Camera"].tap()

    // Wait for navigation
    let backButton = app.navigationBars.buttons.element(boundBy: 0)
    XCTAssertTrue(backButton.waitForExistence(timeout: 3))

    // Tap back button
    backButton.tap()

    // Verify we're back at home
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists, "Should return to home screen")
  }

  @MainActor
  func testMultipleCameraNavigations() throws {
    // Test multiple back and forth navigations to camera
    for _ in 1...3 {
      // Navigate to camera
      app.buttons["Camera"].tap()
      XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))

      // Go back
      app.navigationBars.buttons.element(boundBy: 0).tap()
      XCTAssertTrue(app.staticTexts["KTP Scanner"].waitForExistence(timeout: 2))
    }
  }

  @MainActor
  func testCameraPermissionHandling() throws {
    // Tap camera button
    app.buttons["Camera"].tap()

    // Check if permission alert appears
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alertAllowButton = springboard.buttons["Allow"]

    if alertAllowButton.waitForExistence(timeout: 2) {
      alertAllowButton.tap()
    }

    // After permission (or if already granted), camera or alert should be visible
    let cameraExists = app.otherElements["AVCaptureView"].waitForExistence(timeout: 3)
    let alertExists = app.alerts.firstMatch.exists

    XCTAssertTrue(cameraExists || alertExists, "Camera UI or alert should be visible")
  }

  // MARK: - Camera Error Handling Tests

  @MainActor
  func testCameraNavigationDoesNotCrash() throws {
    // Rapid tap testing to ensure no crashes
    let cameraButton = app.buttons["Camera"]

    for _ in 1...5 {
      if cameraButton.exists {
        cameraButton.tap()
        sleep(UInt32(0.5))

        if app.navigationBars.buttons.element(boundBy: 0).exists {
          app.navigationBars.buttons.element(boundBy: 0).tap()
          sleep(UInt32(0.5))
        }
      }
    }

    // Verify app is still running
    XCTAssertEqual(app.state, .runningForeground, "App should still be running")
  }

  // MARK: - Camera Memory Tests

  @MainActor
  func testCameraMemoryDoesNotLeak() throws {
    // Perform multiple camera navigations to test memory management
    for _ in 1...10 {
      app.buttons["Camera"].tap()
      if app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 1) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
      }
    }

    // Verify app is still responsive
    XCTAssertTrue(app.buttons["Camera"].isHittable, "App should remain responsive")
    XCTAssertTrue(app.buttons["Gallery"].isHittable, "Gallery button should remain responsive")
  }

  // MARK: - Camera Performance Tests

  @MainActor
  func testCameraNavigationPerformance() throws {
    measure(metrics: [XCTClockMetric()]) {
      app.buttons["Camera"].tap()
      if app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 2) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
      }
    }
  }

  @MainActor
  func testCameraButtonTapResponseTime() throws {
    let cameraButton = app.buttons["Camera"]

    measure(metrics: [XCTClockMetric()]) {
      cameraButton.tap()
      _ = app.navigationBars.firstMatch.waitForExistence(timeout: 2)

      // Navigate back for next iteration
      if app.navigationBars.buttons.element(boundBy: 0).exists {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        _ = cameraButton.waitForExistence(timeout: 1)
      }
    }
  }
}
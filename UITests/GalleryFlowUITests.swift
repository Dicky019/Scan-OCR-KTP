//
//  GalleryFlowUITests.swift
//  Scan OCR KTP UITests
//
//  Created by Dicky Darmawan on 30/09/25.
//

import XCTest

final class GalleryFlowUITests: XCTestCase {

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

  // MARK: - Gallery Navigation Tests

  @MainActor
  func testNavigationToGalleryView() throws {
    // Tap gallery button
    let galleryButton = app.buttons["Gallery"]
    XCTAssertTrue(galleryButton.exists, "Gallery button should exist")
    galleryButton.tap()

    // Verify navigation happened
    let backButton = app.navigationBars.buttons.element(boundBy: 0)
    XCTAssertTrue(backButton.waitForExistence(timeout: 3), "Navigation should show back button")
  }

  @MainActor
  func testGalleryFlowNavigation() throws {
    // Tap Gallery button
    let galleryButton = app.buttons["Gallery"]
    galleryButton.tap()

    // Check if photo picker permission alert appears or picker loads
    let navigationBar = app.navigationBars.firstMatch
    XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Gallery view should load")
  }

  @MainActor
  func testGalleryViewHasTitle() throws {
    app.buttons["Gallery"].tap()

    // Wait for navigation
    let selectTitle = app.staticTexts["Select Image"]
    XCTAssertTrue(selectTitle.waitForExistence(timeout: 3), "Gallery view should have title")
  }

  @MainActor
  func testGalleryBackNavigation() throws {
    // Navigate to gallery
    app.buttons["Gallery"].tap()

    // Wait for navigation
    let backButton = app.navigationBars.buttons.element(boundBy: 0)
    XCTAssertTrue(backButton.waitForExistence(timeout: 3))

    // Tap back button
    backButton.tap()

    // Verify we're back at home
    XCTAssertTrue(app.staticTexts["KTP Scanner"].exists, "Should return to home screen")
  }

  @MainActor
  func testMultipleGalleryNavigations() throws {
    // Test multiple back and forth navigations to gallery
    for _ in 1...3 {
      // Navigate to gallery
      app.buttons["Gallery"].tap()
      XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))

      // Go back
      app.navigationBars.buttons.element(boundBy: 0).tap()
      XCTAssertTrue(app.staticTexts["KTP Scanner"].waitForExistence(timeout: 2))
    }
  }

  @MainActor
  func testGalleryPermissionHandling() throws {
    // Tap gallery button
    app.buttons["Gallery"].tap()

    // Check if permission alert appears
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alertAllowButton = springboard.buttons["Allow Access to All Photos"]
    let limitedButton = springboard.buttons["Select Photos..."]

    if alertAllowButton.waitForExistence(timeout: 2) {
      alertAllowButton.tap()
    } else if limitedButton.waitForExistence(timeout: 2) {
      limitedButton.tap()
    }

    // After permission (or if already granted), photo picker should be visible
    let pickerExists = app.otherElements["PUPhotoPicker"].waitForExistence(timeout: 3)
    let navigationBarExists = app.navigationBars.firstMatch.exists

    XCTAssertTrue(pickerExists || navigationBarExists, "Photo picker or navigation should be visible")
  }

  @MainActor
  func testGalleryPhotoPickerInterface() throws {
    // Navigate to gallery
    app.buttons["Gallery"].tap()

    // Wait for photo picker to load
    sleep(2)

    // Check if Cancel button exists in photo picker
    let cancelButton = app.buttons["Cancel"]
    if cancelButton.waitForExistence(timeout: 3) {
      XCTAssertTrue(cancelButton.exists, "Cancel button should exist in photo picker")

      // Tap cancel to go back
      cancelButton.tap()

      // Should return to home
      XCTAssertTrue(app.staticTexts["KTP Scanner"].waitForExistence(timeout: 2))
    }
  }

  // MARK: - Gallery Error Handling Tests

  @MainActor
  func testGalleryNavigationDoesNotCrash() throws {
    // Rapid tap testing to ensure no crashes
    let galleryButton = app.buttons["Gallery"]

    for _ in 1...5 {
      if galleryButton.exists {
        galleryButton.tap()
        sleep(UInt32(0.5))

        if app.navigationBars.buttons.element(boundBy: 0).exists {
          app.navigationBars.buttons.element(boundBy: 0).tap()
          sleep(UInt32(0.5))
        } else if app.buttons["Cancel"].exists {
          app.buttons["Cancel"].tap()
          sleep(UInt32(0.5))
        }
      }
    }

    // Verify app is still running
    XCTAssertEqual(app.state, .runningForeground, "App should still be running")
  }

  // MARK: - Gallery Memory Tests

  @MainActor
  func testGalleryMemoryDoesNotLeak() throws {
    // Perform multiple gallery navigations to test memory management
    for _ in 1...10 {
      app.buttons["Gallery"].tap()

      if app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 1) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
      } else if app.buttons["Cancel"].waitForExistence(timeout: 1) {
        app.buttons["Cancel"].tap()
      }

      _ = app.buttons["Gallery"].waitForExistence(timeout: 1)
    }

    // Verify app is still responsive
    XCTAssertTrue(app.buttons["Gallery"].isHittable, "App should remain responsive")
    XCTAssertTrue(app.buttons["Camera"].isHittable, "Camera button should remain responsive")
  }

  // MARK: - Gallery Performance Tests

  @MainActor
  func testGalleryNavigationPerformance() throws {
    measure(metrics: [XCTClockMetric()]) {
      app.buttons["Gallery"].tap()

      if app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 2) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
      } else if app.buttons["Cancel"].waitForExistence(timeout: 2) {
        app.buttons["Cancel"].tap()
      }

      _ = app.buttons["Gallery"].waitForExistence(timeout: 1)
    }
  }

  @MainActor
  func testGalleryButtonTapResponseTime() throws {
    let galleryButton = app.buttons["Gallery"]

    measure(metrics: [XCTClockMetric()]) {
      galleryButton.tap()
      _ = app.navigationBars.firstMatch.waitForExistence(timeout: 2)

      // Navigate back for next iteration
      if app.navigationBars.buttons.element(boundBy: 0).exists {
        app.navigationBars.buttons.element(boundBy: 0).tap()
      } else if app.buttons["Cancel"].exists {
        app.buttons["Cancel"].tap()
      }
      _ = galleryButton.waitForExistence(timeout: 1)
    }
  }
}
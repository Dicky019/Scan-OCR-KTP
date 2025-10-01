//
//  CameraScreen.swift
//  Scan OCR KTP UITests
//
//  Page Object for Camera Screen
//

import XCTest

struct CameraScreen {

  let app: XCUIApplication

  // MARK: - Elements

  var title: XCUIElement {
    app.staticTexts["Capture Image"]
  }

  var backButton: XCUIElement {
    app.navigationBars.buttons.element(boundBy: 0)
  }

  var navigationBar: XCUIElement {
    app.navigationBars.firstMatch
  }

  var cameraView: XCUIElement {
    app.otherElements["AVCaptureView"]
  }

  // MARK: - Actions

  @discardableResult
  func tapBackButton() -> Bool {
    guard backButton.waitForExistence(timeout: 3) else {
      return false
    }
    backButton.tap()
    return true
  }

  // MARK: - Assertions

  func assertIsDisplayed() {
    XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Camera navigation bar should exist")
  }

  func assertTitleIsVisible() {
    XCTAssertTrue(title.waitForExistence(timeout: 3), "Camera title should be visible")
  }

  func assertBackButtonExists() {
    XCTAssertTrue(backButton.waitForExistence(timeout: 3), "Back button should exist")
  }
}

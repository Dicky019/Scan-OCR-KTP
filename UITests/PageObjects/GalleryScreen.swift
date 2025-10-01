//
//  GalleryScreen.swift
//  Scan OCR KTP UITests
//
//  Page Object for Gallery/Photo Picker Screen
//

import XCTest

struct GalleryScreen {

  let app: XCUIApplication

  // MARK: - Elements

  var title: XCUIElement {
    app.staticTexts["Select Image"]
  }

  var backButton: XCUIElement {
    app.navigationBars.buttons.element(boundBy: 0)
  }

  var cancelButton: XCUIElement {
    app.buttons["Cancel"]
  }

  var navigationBar: XCUIElement {
    app.navigationBars.firstMatch
  }

  var photoPicker: XCUIElement {
    app.otherElements["PUPhotoPicker"]
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

  @discardableResult
  func tapCancelButton() -> Bool {
    guard cancelButton.waitForExistence(timeout: 3) else {
      return false
    }
    cancelButton.tap()
    return true
  }

  /// Dismiss gallery (try back button first, then cancel)
  func dismiss() {
    if backButton.exists {
      tapBackButton()
    } else if cancelButton.exists {
      tapCancelButton()
    }
  }

  // MARK: - Assertions

  func assertIsDisplayed() {
    XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Gallery navigation bar should exist")
  }

  func assertTitleIsVisible() {
    XCTAssertTrue(title.waitForExistence(timeout: 3), "Gallery title should be visible")
  }

  func assertBackOrCancelExists() {
    let exists = backButton.waitForExistence(timeout: 3) || cancelButton.waitForExistence(timeout: 3)
    XCTAssertTrue(exists, "Back button or Cancel button should exist")
  }
}

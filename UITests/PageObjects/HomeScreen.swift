//
//  HomeScreen.swift
//  Scan OCR KTP UITests
//
//  Page Object for Home Screen
//

import XCTest

struct HomeScreen {

  let app: XCUIApplication

  // MARK: - Elements

  var title: XCUIElement {
    app.staticTexts["KTP Scanner"]
  }

  var descriptionText: XCUIElement {
    app.staticTexts["Capture or select a KTP image to extract information"]
  }

  var cameraButton: XCUIElement {
    app.buttons["Camera"]
  }

  var galleryButton: XCUIElement {
    app.buttons["Gallery"]
  }

  var cameraIcon: XCUIElement {
    app.images.matching(identifier: "camera.fill").firstMatch
  }

  var galleryIcon: XCUIElement {
    app.images.matching(identifier: "photo.fill").firstMatch
  }

  // MARK: - Actions

  @discardableResult
  func tapCameraButton() -> Bool {
    guard cameraButton.waitForExistence(timeout: 3) else {
      return false
    }
    cameraButton.tap()
    return true
  }

  @discardableResult
  func tapGalleryButton() -> Bool {
    guard galleryButton.waitForExistence(timeout: 3) else {
      return false
    }
    galleryButton.tap()
    return true
  }

  // MARK: - Assertions

  func assertIsDisplayed() {
    XCTAssertTrue(title.exists, "Home screen title should exist")
    XCTAssertTrue(cameraButton.exists, "Camera button should exist")
    XCTAssertTrue(galleryButton.exists, "Gallery button should exist")
  }

  func assertButtonsAreEnabled() {
    XCTAssertTrue(cameraButton.isEnabled, "Camera button should be enabled")
    XCTAssertTrue(galleryButton.isEnabled, "Gallery button should be enabled")
  }

  func assertButtonsAreInteractive() {
    XCTAssertTrue(cameraButton.isHittable, "Camera button should be hittable")
    XCTAssertTrue(galleryButton.isHittable, "Gallery button should be hittable")
  }

  func assertAccessibility() {
    XCTAssertNotEqual(cameraButton.label, "", "Camera button should have accessibility label")
    XCTAssertNotEqual(galleryButton.label, "", "Gallery button should have accessibility label")
  }
}

//
//  HomeScreenTests.swift
//  Scan OCR KTP UITests
//
//  Essential tests for Home Screen functionality
//

import XCTest

final class HomeScreenTests: UITestBase {
  
  var homeScreen: HomeScreen!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    homeScreen = HomeScreen(app: app)
  }
  
  // MARK: - Essential Tests
  
  func testHomeScreenDisplaysWithAllElements() throws {
    // Combined: display + description + app icon
    homeScreen.assertIsDisplayed()

    XCTAssertTrue(homeScreen.descriptionText.waitForExistence(timeout: 2),
                  "Description text should be visible")

    // Check for app icon (doc.text.viewfinder)
    let appIcon = app.images["doc.text.viewfinder"]
    XCTAssertTrue(appIcon.exists, "App icon should be visible")
  }
  
  func testButtonsAreEnabledAndAccessible() throws {
    // Combined: enabled + interactive + accessibility
    homeScreen.assertButtonsAreEnabled()
    homeScreen.assertButtonsAreInteractive()
    homeScreen.assertAccessibility()
  }
}

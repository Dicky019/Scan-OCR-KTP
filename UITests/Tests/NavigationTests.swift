//
//  NavigationTests.swift
//  Scan OCR KTP UITests
//
//  Essential navigation behavior tests
//

import XCTest

final class NavigationTests: UITestBase {
  
  var homeScreen: HomeScreen!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    homeScreen = HomeScreen(app: app)
  }
  
  // MARK: - Essential Test
  
  func testNavigationStackAndStatePersistence() throws {
    // Combined: navigation depth + state persistence
    homeScreen.assertIsDisplayed()
    
    // Navigate to camera and back
    homeScreen.tapCameraButton()
    XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 2))
    
    app.navigationBars.buttons.element(boundBy: 0).tap()
    XCTAssertTrue(homeScreen.title.waitForExistence(timeout: 2))
    
    // Test state persistence after backgrounding
    XCUIDevice.shared.press(.home)
    usleep(500_000)
    
    app.activate()
    usleep(500_000)
    
    XCTAssertTrue(homeScreen.title.exists)
  }
}

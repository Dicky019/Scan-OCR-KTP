//
//  UITestBase.swift
//  Scan OCR KTP UITests
//
//  Base class for all UI tests with common setup
//

import XCTest

class UITestBase: XCTestCase {
  
  var app: XCUIApplication!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    
    continueAfterFailure = false
    
    app = XCUIApplication()
    
    // Suppress verbose system logging
    app.launchEnvironment = [
      "OS_ACTIVITY_MODE": "disable",
      "IDEPreferLogStreaming": "NO",
      "UI_TESTING": "1" // Flag to indicate running in UI test mode
    ]
    
    // Add launch arguments for faster testing
    app.launchArguments = [
      "-AppleLanguages", "(en)",
      "-AppleLocale", "en_US"
    ]
    
    app.launch()
  }
  
  override func tearDownWithError() throws {
    app?.terminate()
    app = nil
    try super.tearDownWithError()
  }
  
  // MARK: - Common Actions
  
  /// Reset app to home screen
  func returnToHome() {
    while app.navigationBars.buttons.element(boundBy: 0).exists {
      app.navigationBars.buttons.element(boundBy: 0).tap()
      waitForNavigation()
    }
  }
  
  /// Handle system permission alert
  func handlePermissionAlert(allow: Bool = true) {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    if allow {
      // Camera permission
      if springboard.buttons["Allow"].waitForExistence(timeout: 2) {
        springboard.buttons["Allow"].tap()
        return
      }
      
      // Photos permission
      if springboard.buttons["Allow Access to All Photos"].waitForExistence(timeout: 2) {
        springboard.buttons["Allow Access to All Photos"].tap()
        return
      }
      
      if springboard.buttons["Select Photos..."].waitForExistence(timeout: 2) {
        springboard.buttons["Select Photos..."].tap()
        return
      }
    } else {
      if springboard.buttons["Don't Allow"].waitForExistence(timeout: 2) {
        springboard.buttons["Don't Allow"].tap()
      }
    }
  }
  
  /// Verify app is running
  func assertAppIsRunning() {
    XCTAssertEqual(app.state, .runningForeground, "App should be running in foreground")
  }
}

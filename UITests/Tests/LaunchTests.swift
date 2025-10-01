//
//  LaunchTests.swift
//  Scan OCR KTP UITests
//
//  Tests for app launch and performance
//

import XCTest

final class LaunchTests: XCTestCase {
  
  override class var runsForEachTargetApplicationUIConfiguration: Bool {
    true
  }
  
  override func setUpWithError() throws {
    continueAfterFailure = false
  }
  
  // MARK: - Essential Tests
  
  func testLaunchAndVerifyUI() throws {
    // Combined: launch + screenshot + UI verification + configurations
    let app = XCUIApplication()
    app.launchEnvironment = ["UI_TESTING": "1"]
    app.launch()
    
    // Verify app launches successfully
    XCTAssertEqual(app.state, .runningForeground,
                   "App should be running in foreground")
    
    // Verify critical elements appear quickly
    let homeTitle = app.staticTexts["KTP Scanner"]
    XCTAssertTrue(homeTitle.waitForExistence(timeout: 3),
                  "Home screen should appear within 3 seconds")
    
    // Capture screenshot
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Launch Screen"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
  
  func testLaunchPerformance() throws {
    // Combined: performance metrics with reduced iterations
    let options = XCTMeasureOptions()
    options.iterationCount = 3
    
    measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
      let app = XCUIApplication()
      app.launch()
      app.terminate()
    }
  }
}

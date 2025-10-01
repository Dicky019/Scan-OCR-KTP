//
//  CameraFlowTests.swift
//  Scan OCR KTP UITests
//
//  Essential tests for Camera flow
//

import XCTest

final class CameraFlowTests: UITestBase {
  
  var homeScreen: HomeScreen!
  var cameraScreen: CameraScreen!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    homeScreen = HomeScreen(app: app)
    cameraScreen = CameraScreen(app: app)
  }
  
  // MARK: - Essential Tests
  
  func testCameraNavigationFlow() throws {
    // Combined: navigation + title + back navigation
    XCTAssertTrue(homeScreen.tapCameraButton())
    
    cameraScreen.assertIsDisplayed()
    cameraScreen.assertTitleIsVisible()
    cameraScreen.assertBackButtonExists()
    
    XCTAssertTrue(cameraScreen.tapBackButton())
    XCTAssertTrue(homeScreen.title.waitForExistence(timeout: 2))
  }
  
  func testCameraStabilityAndMemory() throws {
    // Combined: rapid navigation + memory test
    for _ in 1...5 {
      if homeScreen.cameraButton.exists {
        homeScreen.tapCameraButton()
        usleep(300_000) // 0.3 seconds
        
        if cameraScreen.backButton.exists {
          cameraScreen.tapBackButton()
          usleep(300_000)
        }
      }
    }
    
    assertAppIsRunning()
    XCTAssertTrue(homeScreen.cameraButton.isHittable)
  }
}

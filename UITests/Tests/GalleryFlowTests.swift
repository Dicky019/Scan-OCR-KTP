//
//  GalleryFlowTests.swift
//  Scan OCR KTP UITests
//
//  Essential tests for Gallery flow
//

import XCTest

final class GalleryFlowTests: UITestBase {
  
  var homeScreen: HomeScreen!
  var galleryScreen: GalleryScreen!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    homeScreen = HomeScreen(app: app)
    galleryScreen = GalleryScreen(app: app)
  }
  
  // MARK: - Essential Tests
  
  func testGalleryNavigationFlow() throws {
    // Combined: navigation + title + back navigation
    XCTAssertTrue(homeScreen.tapGalleryButton())
    
    galleryScreen.assertIsDisplayed()
    galleryScreen.assertTitleIsVisible()
    galleryScreen.assertBackOrCancelExists()
    
    galleryScreen.dismiss()
    XCTAssertTrue(homeScreen.title.waitForExistence(timeout: 2))
  }
  
  func testGalleryStabilityAndMemory() throws {
    // Combined: rapid navigation + memory test
    for _ in 1...5 {
      if homeScreen.galleryButton.exists {
        homeScreen.tapGalleryButton()
        usleep(300_000) // 0.3 seconds
        
        galleryScreen.dismiss()
        usleep(300_000)
      }
    }
    
    assertAppIsRunning()
    XCTAssertTrue(homeScreen.galleryButton.isHittable)
  }
}

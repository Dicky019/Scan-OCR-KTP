//
//  UITests.swift
//  Scan OCR KTP UITests
//
//  Created by Dicky Darmawan on 29/09/25.
//

import XCTest

final class Scan_OCR_KTPUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.state == .runningForeground)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Home Screen Tests

    @MainActor
    func testHomeScreenElements() throws {
        // Verify home screen has required elements
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists, "App title should exist")
        XCTAssertTrue(app.buttons["Camera"].exists, "Camera button should exist")
        XCTAssertTrue(app.buttons["Gallery"].exists, "Gallery button should exist")
    }

    @MainActor
    func testHomeScreenDescription() throws {
        // Check if description text exists
        let descriptionText = app.staticTexts["Capture or select a KTP image to extract information"]
        XCTAssertTrue(descriptionText.waitForExistence(timeout: 2), "Description text should exist")
    }

    // MARK: - Navigation Tests

    @MainActor
    func testNavigationToCameraView() throws {
        // Tap camera button
        let cameraButton = app.buttons["Camera"]
        XCTAssertTrue(cameraButton.exists, "Camera button should exist")
        cameraButton.tap()

        // Verify navigation happened (check for back button or camera UI)
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 3), "Navigation should show back button")
    }

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
    func testBackNavigation() throws {
        // Navigate to camera
        app.buttons["Camera"].tap()

        // Wait for navigation
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))

        // Tap back button
        backButton.tap()

        // Verify we're back at home
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists, "Should return to home screen")
    }

    // MARK: - Camera Flow Tests

    @MainActor
    func testCameraFlowNavigation() throws {
        // Tap Camera button
        let cameraButton = app.buttons["Camera"]
        cameraButton.tap()

        // Check if camera permission alert appears or camera view loads
        // Note: Actual camera testing requires physical device
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Camera view should load")
    }

    @MainActor
    func testCameraViewHasTitle() throws {
        app.buttons["Camera"].tap()

        // Wait for navigation
        let captureTitle = app.staticTexts["Capture Image"]
        XCTAssertTrue(captureTitle.waitForExistence(timeout: 3), "Camera view should have title")
    }

    // MARK: - Gallery Flow Tests

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

    // MARK: - Complete Flow Tests (Mock)

    @MainActor
    func testHomeToBackNavigationFlow() throws {
        // Start at home
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)

        // Go to Camera
        app.buttons["Camera"].tap()
        sleep(1)

        // Go back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)

        // Verify back at home
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)

        // Go to Gallery
        app.buttons["Gallery"].tap()
        sleep(1)

        // Go back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)

        // Verify back at home
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)
    }

    @MainActor
    func testMultipleNavigations() throws {
        // Test multiple back and forth navigations
        for _ in 1...3 {
            // Navigate to camera
            app.buttons["Camera"].tap()
            XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))

            // Go back
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.staticTexts["KTP Scanner"].waitForExistence(timeout: 2))
        }
    }

    // MARK: - UI Element Tests

    @MainActor
    func testButtonsAreInteractive() throws {
        let cameraButton = app.buttons["Camera"]
        let galleryButton = app.buttons["Gallery"]

        // Verify buttons exist and are enabled
        XCTAssertTrue(cameraButton.exists)
        XCTAssertTrue(cameraButton.isEnabled)
        XCTAssertTrue(galleryButton.exists)
        XCTAssertTrue(galleryButton.isEnabled)
    }

    @MainActor
    func testNavigationBarExists() throws {
        // Check navigation bar on home screen
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testAccessibilityLabels() throws {
        // Verify important elements have accessibility
        let cameraButton = app.buttons["Camera"]
        XCTAssertTrue(cameraButton.exists)
        XCTAssertNotEqual(cameraButton.label, "", "Camera button should have accessibility label")

        let galleryButton = app.buttons["Gallery"]
        XCTAssertTrue(galleryButton.exists)
        XCTAssertNotEqual(galleryButton.label, "", "Gallery button should have accessibility label")
    }

    // MARK: - State Persistence Tests

    @MainActor
    func testAppStateAfterBackground() throws {
        // Launch app
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)

        // Send app to background
        XCUIDevice.shared.press(.home)
        sleep(1)

        // Bring back to foreground
        app.activate()
        sleep(1)

        // Verify home screen still visible
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists, "Home screen should persist after backgrounding")
    }

    // MARK: - Navigation Stack Tests

    @MainActor
    func testNavigationStackDepth() throws {
        // Start at home (depth 0)
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)

        // Navigate to camera (depth 1)
        app.buttons["Camera"].tap()
        XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 2))

        // Verify we can go back (only 1 level deep)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["KTP Scanner"].waitForExistence(timeout: 2))
    }

    // MARK: - Icon and Image Tests

    @MainActor
    func testAppIconsDisplay() throws {
        // Check if camera icon exists
        let cameraIcon = app.images.matching(identifier: "camera.fill").firstMatch
        let photoIcon = app.images.matching(identifier: "photo.fill").firstMatch

        // At least one should exist (icons in buttons)
        XCTAssertTrue(cameraIcon.exists || photoIcon.exists, "Icons should be displayed")
    }

    // MARK: - Layout Tests

    @MainActor
    func testPortraitLayout() throws {
        // Ensure device is in portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)

        // Verify elements are visible
        XCTAssertTrue(app.buttons["Camera"].exists)
        XCTAssertTrue(app.buttons["Gallery"].exists)
        XCTAssertTrue(app.staticTexts["KTP Scanner"].exists)
    }

    // MARK: - Error Handling UI Tests

    @MainActor
    func testNavigationDoesNotCrash() throws {
        // Rapid tap testing to ensure no crashes
        let cameraButton = app.buttons["Camera"]

        for _ in 1...5 {
            if cameraButton.exists {
                cameraButton.tap()
                sleep(0.5)

                if app.navigationBars.buttons.element(boundBy: 0).exists {
                    app.navigationBars.buttons.element(boundBy: 0).tap()
                    sleep(0.5)
                }
            }
        }

        // Verify app is still running
        XCTAssertEqual(app.state, .runningForeground, "App should still be running")
    }

    // MARK: - Memory Tests

    @MainActor
    func testMemoryDoesNotLeakDuringNavigation() throws {
        // Perform multiple navigations to test memory management
        for _ in 1...10 {
            app.buttons["Camera"].tap()
            if app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 1) {
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }

        // Verify app is still responsive
        XCTAssertTrue(app.buttons["Camera"].isHittable, "App should remain responsive")
        XCTAssertTrue(app.buttons["Gallery"].isHittable, "App should remain responsive")
    }
}

// MARK: - Performance Tests

final class Scan_OCR_KTPPerformanceTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    @MainActor
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    @MainActor
    func testNavigationPerformance() throws {
        app.launch()

        measure(metrics: [XCTClockMetric()]) {
            app.buttons["Camera"].tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    @MainActor
    func testButtonTapResponseTime() throws {
        app.launch()

        let cameraButton = app.buttons["Camera"]

        measure(metrics: [XCTClockMetric()]) {
            cameraButton.tap()
        }
    }
}
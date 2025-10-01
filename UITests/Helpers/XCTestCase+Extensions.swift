//
//  XCTestCase+Extensions.swift
//  Scan OCR KTP UITests
//
//  Helper extensions for UI testing
//

import XCTest

extension XCTestCase {

  /// Wait for element to exist with custom timeout
  func waitForElement(
    _ element: XCUIElement,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    line: UInt = #line
  ) -> Bool {
    let exists = element.waitForExistence(timeout: timeout)
    if !exists {
      XCTFail("Element did not exist after \(timeout) seconds", file: file, line: line)
    }
    return exists
  }

  /// Wait for element to disappear
  func waitForElementToDisappear(
    _ element: XCUIElement,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

    if result != .completed {
      XCTFail("Element did not disappear after \(timeout) seconds", file: file, line: line)
    }
  }

  /// Tap element with verification
  func safeTap(
    _ element: XCUIElement,
    timeout: TimeInterval = 3,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    guard waitForElement(element, timeout: timeout, file: file, line: line) else {
      return
    }

    XCTAssertTrue(element.isHittable, "Element is not hittable", file: file, line: line)
    element.tap()
  }

  /// Wait for navigation to complete
  func waitForNavigation(timeout: TimeInterval = 3) {
    // Small delay to allow navigation animation to complete
    usleep(UInt32(timeout * 100_000)) // Convert to microseconds
  }

  /// Take screenshot with name
  func takeScreenshot(named name: String, lifetime: XCTAttachment.Lifetime = .keepAlways) {
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = lifetime
    add(attachment)
  }
}

extension XCUIElement {

  /// Check if element is visible and hittable
  var isVisibleAndHittable: Bool {
    return exists && isHittable
  }

  /// Force tap even if not hittable (useful for edge cases)
  func forceTap() {
    if exists {
      coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
  }

  /// Wait and tap
  @discardableResult
  func waitAndTap(timeout: TimeInterval = 5) -> Bool {
    guard waitForExistence(timeout: timeout) else {
      return false
    }
    tap()
    return true
  }
}

//
//  TestTags.swift
//  Scan OCR KTP Tests
//
//  Shared test tags for organizing and filtering tests
//

import Testing

// MARK: - Test Tags

extension Tag {
  /// Parser-related tests (KTP field extraction, regex parsing)
  @Tag static var parser: Self

  /// OCR processing tests (Vision, MLKit, comparison)
  @Tag static var ocr: Self

  /// Apple Vision framework tests
  @Tag static var vision: Self

  /// Google MLKit framework tests
  @Tag static var mlkit: Self

  /// Performance and timing tests
  @Tag static var performance: Self

  /// Integration tests (multi-component, end-to-end)
  @Tag static var integration: Self

  /// Model structure and data tests
  @Tag static var models: Self

  /// Navigation and coordinator tests
  @Tag static var navigation: Self
}

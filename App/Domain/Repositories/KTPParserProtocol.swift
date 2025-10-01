//
//  KTPParserProtocol.swift
//  Scan OCR KTP - Domain Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import Foundation

// MARK: - KTP Parser Protocol (Dependency Inversion Principle)

/// Protocol for parsing KTP data from OCR text
/// Allows different parsing implementations without changing business logic
protocol KTPParserProtocol {
  /// Parse raw OCR text into structured KTP data
  func parse(
    text: String,
    confidence: Double,
    engine: OCREngine,
    processingTime: TimeInterval
  ) -> KTPData
}

// MARK: - Field Extraction Strategy Protocol

/// Strategy pattern for extracting specific KTP fields
protocol KTPFieldExtractionStrategy {
  var fieldName: String { get }
  func extract(from lines: [String]) -> String?
}
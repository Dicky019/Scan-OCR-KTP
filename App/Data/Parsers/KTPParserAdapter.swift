//
//  KTPParserAdapter.swift
//  Scan OCR KTP - Data Layer
//
//  Adapter for KTPParser
//  Provides easy dependency injection and testability
//
//  Created by Dicky Darmawan on 30/09/25.
//

import Foundation

// MARK: - KTP Parser Adapter

/// Adapter for KTPParser - uses SOLID principles and Strategy Pattern
final class KTPParserAdapter: KTPParserProtocol {

  private let parser: KTPParserProtocol

  /// Initialize with KTP parser (default uses KTPParser)
  init(parser: KTPParserProtocol = KTPParser()) {
    self.parser = parser
  }

  func parse(
    text: String,
    confidence: Double,
    engine: OCREngine,
    processingTime: TimeInterval
  ) -> KTPData {
    return parser.parse(
      text: text,
      confidence: confidence,
      engine: engine,
      processingTime: processingTime
    )
  }
}
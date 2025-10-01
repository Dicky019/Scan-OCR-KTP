//
//  OCRResult.swift
//  Scan OCR KTP - Domain Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import Foundation

// MARK: - Domain Entities (Clean Architecture)

/// Represents the result of OCR text recognition
struct OCRResult: Equatable {
  let text: String
  let confidence: Double
  let processingTime: TimeInterval
  let engine: OCREngine

  init(text: String, confidence: Double, processingTime: TimeInterval, engine: OCREngine) {
    self.text = text
    self.confidence = confidence
    self.processingTime = processingTime
    self.engine = engine
  }
}

/// OCR Engine type
enum OCREngine: String, Codable, Equatable {
  case vision = "Apple Vision"
  case mlkit = "Google MLKit"
}

/// Comparison result from multiple OCR engines
struct OCRComparisonResult: Equatable {
  let visionResult: KTPData?
  let mlkitResult: KTPData?
  let processingTime: (vision: TimeInterval, mlkit: TimeInterval)

  var hasBothResults: Bool {
    visionResult != nil && mlkitResult != nil
  }

  var bestResult: KTPData? {
    guard let vision = visionResult, let mlkit = mlkitResult else {
      return visionResult ?? mlkitResult
    }
    return vision.confidence >= mlkit.confidence ? vision : mlkit
  }

  static func == (lhs: OCRComparisonResult, rhs: OCRComparisonResult) -> Bool {
    lhs.visionResult == rhs.visionResult &&
    lhs.mlkitResult == rhs.mlkitResult &&
    lhs.processingTime.vision == rhs.processingTime.vision &&
    lhs.processingTime.mlkit == rhs.processingTime.mlkit
  }
}
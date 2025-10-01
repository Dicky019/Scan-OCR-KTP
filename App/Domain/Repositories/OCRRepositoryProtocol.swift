//
//  OCRRepositoryProtocol.swift
//  Scan OCR KTP - Domain Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import UIKit

// MARK: - Repository Protocol (Dependency Inversion Principle)

/// Protocol defining OCR operations (abstraction)
/// This allows different implementations without changing business logic
protocol OCRRepositoryProtocol {
  /// Process image with specified OCR engine
  func recognizeText(from image: UIImage, using engine: OCREngine, sessionId: String?) async -> Result<OCRResult, OCRError>

  /// Process image with all available engines and compare results
  func processWithComparison(image: UIImage) async -> Result<OCRComparisonResult, OCRError>
}

// MARK: - OCR Error Types

enum OCRError: Error, Equatable {
  case engineUnavailable(OCREngine)
  case processingFailed(String)
  case noTextDetected
  case invalidImage
  case timeout

  var localizedDescription: String {
    switch self {
    case .engineUnavailable(let engine):
      return "\(engine.rawValue) is not available"
    case .processingFailed(let message):
      return "OCR processing failed: \(message)"
    case .noTextDetected:
      return "No text detected in image"
    case .invalidImage:
      return "Invalid or corrupted image"
    case .timeout:
      return "OCR processing timeout"
    }
  }
}
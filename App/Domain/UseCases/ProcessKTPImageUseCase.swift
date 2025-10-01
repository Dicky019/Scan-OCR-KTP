//
//  ProcessKTPImageUseCase.swift
//  Scan OCR KTP - Domain Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import UIKit

// MARK: - Use Case (Single Responsibility Principle)

/// Use case for processing KTP images with OCR
/// Encapsulates business logic for KTP text extraction and parsing
final class ProcessKTPImageUseCase {

  // MARK: - Dependencies (Dependency Injection)

  private let ocrRepository: OCRRepositoryProtocol
  private let ktpParser: KTPParserProtocol
  private let logger: LoggerProtocol

  // MARK: - Initialization

  init(
    ocrRepository: OCRRepositoryProtocol,
    ktpParser: KTPParserProtocol,
    logger: LoggerProtocol
  ) {
    self.ocrRepository = ocrRepository
    self.ktpParser = ktpParser
    self.logger = logger
  }

  // MARK: - Execute Use Case

  /// Process KTP image with single OCR engine
  func execute(image: UIImage, engine: OCREngine) async -> Result<KTPData, OCRError> {
    logger.logProcess("Starting KTP processing with \(engine.rawValue)")

    // Step 1: OCR text recognition
    let ocrResult = await ocrRepository.recognizeText(
      from: image,
      using: engine,
      sessionId: nil
    )

    switch ocrResult {
    case .success(let result):
      // Step 2: Parse KTP data
      let ktpData = ktpParser.parse(
        text: result.text,
        confidence: result.confidence,
        engine: result.engine,
        processingTime: result.processingTime
      )

      logger.logSuccess("KTP processing complete")
      return .success(ktpData)

    case .failure(let error):
      logger.logError("KTP processing failed: \(error.localizedDescription)")
      return .failure(error)
    }
  }

  /// Process KTP image with multiple engines and return best result
  func executeWithComparison(image: UIImage) async -> Result<OCRComparisonResult, OCRError> {
    logger.logProcess("Starting dual-engine KTP processing")

    let comparisonResult = await ocrRepository.processWithComparison(image: image)

    switch comparisonResult {
    case .success(let result):
      logger.logSuccess("Dual-engine processing complete")
      return .success(result)

    case .failure(let error):
      logger.logError("Dual-engine processing failed: \(error.localizedDescription)")
      return .failure(error)
    }
  }
}

// MARK: - Logger Protocol

protocol LoggerProtocol {
  func logProcess(_ message: String, details: String?, sessionId: String?)
  func logSuccess(_ message: String, details: String?, sessionId: String?)
  func logError(_ message: String, error: Error?, sessionId: String?)
}

extension LoggerProtocol {
  func logProcess(_ message: String) {
    logProcess(message, details: nil, sessionId: nil)
  }

  func logSuccess(_ message: String) {
    logSuccess(message, details: nil, sessionId: nil)
  }

  func logError(_ message: String) {
    logError(message, error: nil, sessionId: nil)
  }
}
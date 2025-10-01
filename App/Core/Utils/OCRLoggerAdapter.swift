//
//  OCRLoggerAdapter.swift
//  Scan OCR KTP - Core Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import Foundation

// MARK: - Adapter for OCRLogger

/// Adapter to make OCRLogger conform to LoggerProtocol
final class OCRLoggerAdapter: LoggerProtocol {

  private let logger: OCRLogger

  init(logger: OCRLogger = .shared) {
    self.logger = logger
  }

  func logProcess(_ message: String, details: String?, sessionId: String?) {
    logger.logProcess(message, details: details, sessionId: sessionId)
  }

  func logSuccess(_ message: String, details: String?, sessionId: String?) {
    logger.logSuccess(message, details: details, sessionId: sessionId)
  }

  func logError(_ message: String, error: Error?, sessionId: String?) {
    if let error = error {
      logger.logError(message, error: error, sessionId: sessionId)
    } else {
      logger.logWarning(message, message: "", sessionId: sessionId)
    }
  }
}
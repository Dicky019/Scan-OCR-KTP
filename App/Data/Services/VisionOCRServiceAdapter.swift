//
//  VisionOCRServiceAdapter.swift
//  Scan OCR KTP - Data Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import UIKit

// MARK: - Adapter Pattern (Make existing service conform to protocol)

/// Adapter to make VisionOCRService conform to OCRServiceProtocol
final class VisionOCRServiceAdapter: OCRServiceProtocol {

  private let visionService: VisionOCRService

  init(visionService: VisionOCRService = VisionOCRService()) {
    self.visionService = visionService
  }

  func recognizeText(
    from image: UIImage,
    sessionId: String?
  ) async throws -> (text: String, confidence: Double, processingTime: TimeInterval) {
    return try await visionService.recognizeText(from: image, sessionId: sessionId)
  }
}

// MARK: - MLKit Adapter

#if !targetEnvironment(simulator)
final class MLKitOCRServiceAdapter: OCRServiceProtocol {

  private let mlkitService: MLKitOCRService

  init(mlkitService: MLKitOCRService = MLKitOCRService()) {
    self.mlkitService = mlkitService
  }

  func recognizeText(
    from image: UIImage,
    sessionId: String?
  ) async throws -> (text: String, confidence: Double, processingTime: TimeInterval) {
    return try await mlkitService.recognizeText(from: image, sessionId: sessionId)
  }
}
#endif
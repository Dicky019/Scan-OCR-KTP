//
//  OCRRepository.swift
//  Scan OCR KTP - Data Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import UIKit

// MARK: - Repository Implementation (Dependency Inversion Principle)

/// Concrete implementation of OCR repository
/// Coordinates between different OCR service providers
final class OCRRepository: OCRRepositoryProtocol {
  
  // MARK: - Dependencies
  
  private let visionService: OCRServiceProtocol
  private let mlkitService: OCRServiceProtocol?
  private let ktpParser: KTPParserProtocol
  private let logger: LoggerProtocol
  
  // MARK: - Initialization
  
  init(visionService: OCRServiceProtocol, mlkitService: OCRServiceProtocol?, ktpParser: KTPParserProtocol, logger: LoggerProtocol) {
    self.visionService = visionService
    self.mlkitService = mlkitService
    self.ktpParser = ktpParser
    self.logger = logger
  }
  
  // MARK: - OCRRepositoryProtocol
  
  func recognizeText(from image: UIImage, using engine: OCREngine, sessionId: String?) async -> Result<OCRResult, OCRError> {
    
    let service: OCRServiceProtocol
    
    switch engine {
    case .vision:
      service = visionService
      
    case .mlkit:
      guard let mlkit = mlkitService else {
        return .failure(.engineUnavailable(.mlkit))
      }
      service = mlkit
    }
    
    do {
      let result = try await service.recognizeText(from: image, sessionId: sessionId)
      return .success(OCRResult(
        text: result.text,
        confidence: result.confidence,
        processingTime: result.processingTime,
        engine: engine
      ))
    } catch {
      return .failure(.processingFailed(error.localizedDescription))
    }
  }
  
  func processWithComparison(image: UIImage) async -> Result<OCRComparisonResult, OCRError> {
    
#if targetEnvironment(simulator)
    // Simulator: Vision only
    let visionResult = await recognizeText(from: image, using: .vision, sessionId: nil)
    
    switch visionResult {
    case .success(let result):
      let ktpData = ktpParser.parse(
        text: result.text,
        confidence: result.confidence,
        engine: result.engine,
        processingTime: result.processingTime
      )
      
      let comparison = OCRComparisonResult(
        visionResult: ktpData,
        mlkitResult: nil,
        processingTime: (vision: result.processingTime, mlkit: 0)
      )
      return .success(comparison)
      
    case .failure(let error):
      return .failure(error)
    }
#else
    // Device: Both engines
    async let visionTask = recognizeText(from: image, using: .vision, sessionId: nil)
    async let mlkitTask = recognizeText(from: image, using: .mlkit, sessionId: nil)
    
    let (visionResult, mlkitResult) = await (visionTask, mlkitTask)
    
    // Parse results
    var visionKTP: KTPData?
    var mlkitKTP: KTPData?
    var visionTime: TimeInterval = 0
    var mlkitTime: TimeInterval = 0
    
    if case .success(let result) = visionResult {
      visionKTP = ktpParser.parse(
        text: result.text,
        confidence: result.confidence,
        engine: result.engine,
        processingTime: result.processingTime
      )
      visionTime = result.processingTime
    }
    
    if case .success(let result) = mlkitResult {
      mlkitKTP = ktpParser.parse(
        text: result.text,
        confidence: result.confidence,
        engine: result.engine,
        processingTime: result.processingTime
      )
      mlkitTime = result.processingTime
    }
    
    // Return comparison even if one engine failed
    let comparison = OCRComparisonResult(
      visionResult: visionKTP,
      mlkitResult: mlkitKTP,
      processingTime: (vision: visionTime, mlkit: mlkitTime)
    )
    
    return .success(comparison)
#endif
  }
}

// MARK: - OCR Service Protocol

/// Protocol for OCR service providers (Vision, MLKit, etc.)
protocol OCRServiceProtocol {
  func recognizeText(
    from image: UIImage,
    sessionId: String?
  ) async throws -> (text: String, confidence: Double, processingTime: TimeInterval)
}

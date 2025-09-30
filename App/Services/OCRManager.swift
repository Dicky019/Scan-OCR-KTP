//
//  OCRManager.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation
import UIKit

@MainActor
class OCRManager: ObservableObject {
  private let visionService = VisionOCRService()
#if !targetEnvironment(simulator)
  private let mlkitService = MLKitOCRService()
#endif
  private let ktpParser = KTPParser()
  private let logger = OCRLogger.shared
  
  func processImage(_ image: UIImage) async -> OCRComparisonResult {
    let sessionId = logger.startSession()
    
#if targetEnvironment(simulator)
    // In simulator, use Vision only due to GoogleMLKit compatibility issues
    logger.logProcess("Starting Vision-only OCR (simulator mode)", details: "Image size: \(Int(image.size.width))x\(Int(image.size.height))", sessionId: sessionId)
    
    let imageSize = image.size
    logger.logPerformanceMetric("comparison_image_width", value: Double(imageSize.width), engine: .vision, sessionId: sessionId)
    logger.logPerformanceMetric("comparison_image_height", value: Double(imageSize.height), engine: .vision, sessionId: sessionId)
    
    let comparisonOperationId = logger.logPerformanceStart("Vision_Only_OCR", engine: .vision, sessionId: sessionId)
    
    let vision = await processWithVision(image, sessionId: sessionId)
    let mlkit: KTPData? = nil
    
    logger.logProcess("Simulator mode: MLKit skipped", details: "Vision-only processing", sessionId: sessionId)
#else
    // On device, use both engines for comparison
    logger.logProcess("Starting dual OCR engine comparison", details: "Image size: \(Int(image.size.width))x\(Int(image.size.height))", sessionId: sessionId)
    
    let imageSize = image.size
    logger.logPerformanceMetric("comparison_image_width", value: Double(imageSize.width), engine: .vision, sessionId: sessionId)
    logger.logPerformanceMetric("comparison_image_height", value: Double(imageSize.height), engine: .vision, sessionId: sessionId)
    
    let comparisonOperationId = logger.logPerformanceStart("OCR_Engine_Comparison", engine: .vision, sessionId: sessionId)
    
    logger.logProcess("Launching parallel OCR processing", details: "Vision + MLKit engines", sessionId: sessionId)
    
    async let visionResult = processWithVision(image, sessionId: sessionId)
    async let mlkitResult = processWithMLKit(image, sessionId: sessionId)
    
    let vision = await visionResult
    let mlkit = await mlkitResult
#endif
    
    let visionTime = vision?.processingTime ?? 0.0
    let mlkitTime = mlkit?.processingTime ?? 0.0
    
    logger.logPerformanceMetric("vision_processing_time", value: visionTime, engine: .vision, sessionId: sessionId)
    logger.logPerformanceMetric("mlkit_processing_time", value: mlkitTime, engine: .mlkit, sessionId: sessionId)
    
    // Compare results
    logger.logProcess("Comparing OCR results", sessionId: sessionId)
    
#if targetEnvironment(simulator)
    // Simulator mode - only Vision results
    if let visionData = vision {
      logger.logProcess("Vision OCR successful (simulator)", details: "Confidence: \(String(format: "%.1f", visionData.confidence * 100))%", sessionId: sessionId)
      logger.logPerformanceMetric("vision_confidence", value: visionData.confidence, engine: .vision, sessionId: sessionId)
      logger.logPerformanceMetric("vision_text_length", value: Double(visionData.rawText.count), engine: .vision, sessionId: sessionId)
    } else {
      logger.logWarning("Vision OCR failed", message: "Failed to process image", sessionId: sessionId)
    }
#else
    // Device mode - compare both engines
    if let visionData = vision, let mlkitData = mlkit {
      logger.logProcess("Both engines successful", details: "Vision: \(String(format: "%.1f", visionData.confidence * 100))%, MLKit: \(String(format: "%.1f", mlkitData.confidence * 100))%", sessionId: sessionId)
      
      // Compare confidence scores
      let confidenceDiff = abs(visionData.confidence - mlkitData.confidence)
      logger.logPerformanceMetric("confidence_difference", value: confidenceDiff, engine: .vision, sessionId: sessionId)
      
      // Compare text lengths
      let textLengthDiff = abs(visionData.rawText.count - mlkitData.rawText.count)
      logger.logPerformanceMetric("text_length_difference", value: Double(textLengthDiff), engine: .vision, sessionId: sessionId)
      
      // Compare processing times
      let timeDiff = abs(visionTime - mlkitTime)
      logger.logPerformanceMetric("processing_time_difference", value: timeDiff, engine: .vision, sessionId: sessionId)
      
      let fasterEngine = visionTime <= mlkitTime ? "Vision" : "MLKit"
      let higherConfidenceEngine = visionData.confidence >= mlkitData.confidence ? "Vision" : "MLKit"
      
      logger.logProcess("Performance comparison", details: "Faster: \(fasterEngine), Higher confidence: \(higherConfidenceEngine)", sessionId: sessionId)
      
    } else if let visionData = vision {
      logger.logProcess("Only Vision successful", details: "Confidence: \(String(format: "%.1f", visionData.confidence * 100))%", sessionId: sessionId)
    } else if let mlkitData = mlkit {
      logger.logProcess("Only MLKit successful", details: "Confidence: \(String(format: "%.1f", mlkitData.confidence * 100))%", sessionId: sessionId)
    } else {
      logger.logWarning("OCR comparison failed", message: "Both engines failed to process image", sessionId: sessionId)
    }
#endif
    
    let result = OCRComparisonResult(
      visionResult: vision,
      mlkitResult: mlkit,
      processingTime: (vision: visionTime, mlkit: mlkitTime)
    )
    
    logger.logPerformanceEnd(comparisonOperationId, sessionId: sessionId, result: "Comparison complete")
    logger.logSessionSummary(sessionId)
    logger.endSession(sessionId)
    
    return result
  }
  
  func processWithVision(_ image: UIImage, sessionId: String? = nil) async -> KTPData? {
    logger.logProcess("Starting Vision OCR processing", sessionId: sessionId)
    
    do {
      let result = try await visionService.recognizeText(from: image, sessionId: sessionId)
      logger.logProcess("Vision OCR text recognition completed", details: "Text length: \(result.text.count)", sessionId: sessionId)
      
      let parsingOperationId = logger.logPerformanceStart("Vision_KTP_Parsing", engine: .vision, sessionId: sessionId)
      let ktpData = ktpParser.parseKTPData(
        from: result.text,
        confidence: result.confidence,
        engine: .vision,
        processingTime: result.processingTime,
        sessionId: sessionId
      )
      logger.logPerformanceEnd(parsingOperationId, sessionId: sessionId, result: "Parsing complete")
      
      logger.logSuccess("Vision processing complete", details: "Fields extracted, confidence: \(String(format: "%.1f", ktpData.confidence * 100))%", sessionId: sessionId)
      return ktpData
      
    } catch {
      logger.logError("Vision OCR processing failed", error: error, sessionId: sessionId)
      return nil
    }
  }
  
  func processWithMLKit(_ image: UIImage, sessionId: String? = nil) async -> KTPData? {
#if targetEnvironment(simulator)
    logger.logWarning("MLKit OCR called in simulator", message: "This should not happen - use Vision OCR instead", sessionId: sessionId)
    return nil
#else
    logger.logProcess("Starting MLKit OCR processing", sessionId: sessionId)
    
    do {
      let result = try await mlkitService.recognizeText(from: image, sessionId: sessionId)
      logger.logProcess("MLKit OCR text recognition completed", details: "Text length: \(result.text.count)", sessionId: sessionId)
      
      let parsingOperationId = logger.logPerformanceStart("MLKit_KTP_Parsing", engine: .mlkit, sessionId: sessionId)
      let ktpData = ktpParser.parseKTPData(
        from: result.text,
        confidence: result.confidence,
        engine: .mlkit,
        processingTime: result.processingTime,
        sessionId: sessionId
      )
      logger.logPerformanceEnd(parsingOperationId, sessionId: sessionId, result: "Parsing complete")
      
      logger.logSuccess("MLKit processing complete", details: "Fields extracted, confidence: \(String(format: "%.1f", ktpData.confidence * 100))%", sessionId: sessionId)
      return ktpData
      
    } catch {
      logger.logError("MLKit OCR processing failed", error: error, sessionId: sessionId)
      return nil
    }
#endif
  }
  
  func processWithSingleEngine(_ image: UIImage, engine: OCREngine) async -> KTPData? {
    let sessionId = logger.startSession()
    logger.logProcess("Starting single engine OCR", details: "Engine: \(engine.rawValue)", sessionId: sessionId)
    
    let singleEngineOperationId = logger.logPerformanceStart("Single_Engine_OCR", engine: engine, sessionId: sessionId)
    
    let result: KTPData?
    switch engine {
    case .vision:
      result = await processWithVision(image, sessionId: sessionId)
    case .mlkit:
#if targetEnvironment(simulator)
      logger.logWarning("MLKit OCR requested in simulator", message: "Falling back to Vision OCR", sessionId: sessionId)
      result = await processWithVision(image, sessionId: sessionId)
#else
      result = await processWithMLKit(image, sessionId: sessionId)
#endif
    }
    
    logger.logPerformanceEnd(singleEngineOperationId, sessionId: sessionId, result: result != nil ? "Success" : "Failed")
    logger.logSessionSummary(sessionId)
    logger.endSession(sessionId)
    
    return result
  }
}

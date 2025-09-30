//
//  MLKitOCRService.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation
import UIKit

#if !targetEnvironment(simulator)
import MLKitTextRecognition
import MLKitVision
#endif

#if !targetEnvironment(simulator)
class MLKitOCRService {
  private let logger = OCRLogger.shared
  private let textRecognizer = TextRecognizer.textRecognizer(options: TextRecognizerOptions())
  
  func recognizeText(from image: UIImage, sessionId: String? = nil) async throws -> (text: String, confidence: Double, processingTime: Double) {
    logger.logProcess("Starting MLKit OCR text recognition", details: "Image size: \(image.size)", sessionId: sessionId)
    
    let imageSize = image.size
    logger.logPerformanceMetric("image_width", value: Double(imageSize.width), engine: .mlkit, sessionId: sessionId)
    logger.logPerformanceMetric("image_height", value: Double(imageSize.height), engine: .mlkit, sessionId: sessionId)
    logger.logPerformanceMetric("image_scale", value: Double(image.scale), engine: .mlkit, sessionId: sessionId)
    
    let overallOperationId = logger.logPerformanceStart("MLKit_OCR_Complete", engine: .mlkit, sessionId: sessionId)
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Image preprocessing
    let preprocessingId = logger.logPerformanceStart("MLKit_Image_Preprocessing", engine: .mlkit, sessionId: sessionId)
    
    // Convert UIImage to VisionImage
    let visionImage = VisionImage(image: image)
    visionImage.orientation = image.imageOrientation
    
    logger.logProcess("Converting image to MLKit VisionImage format", sessionId: sessionId)
    
    // Log image metrics
    if let cgImage = image.cgImage {
      let pixelCount = Double(cgImage.width * cgImage.height)
      logger.logPerformanceMetric("image_pixels", value: pixelCount, engine: .mlkit, sessionId: sessionId)
      logger.logProcess("MLKit image preprocessing", details: "Size: \(cgImage.width)x\(cgImage.height), Format: \(cgImage.bitsPerComponent)bpc", sessionId: sessionId)
    }
    
    logger.logPerformanceEnd(preprocessingId, sessionId: sessionId, result: "VisionImage ready")
    
    // MLKit text recognition
    let processingId = logger.logPerformanceStart("MLKit_Text_Recognition", engine: .mlkit, sessionId: sessionId)
    
    return try await withCheckedThrowingContinuation { [weak self] continuation in
      guard let self = self else {
        continuation.resume(throwing: NSError(domain: "MLKitOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"]))
        return
      }
      
      self.textRecognizer.process(visionImage) { [weak self] result, error in
        guard let self = self else { return }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let processingTime = endTime - startTime
        
        self.logger.logPerformanceEnd(processingId, sessionId: sessionId)
        
        if let error = error {
          self.logger.logError("MLKit OCR text recognition", error: error, sessionId: sessionId)
          self.logger.logPerformanceEnd(overallOperationId, sessionId: sessionId, result: "Failed: \(error.localizedDescription)")
          continuation.resume(throwing: error)
          return
        }
        
        guard let result = result else {
          let error = NSError(domain: "MLKitOCR", code: -2, userInfo: [NSLocalizedDescriptionKey: "No text recognition result"])
          self.logger.logError("MLKit OCR text recognition", error: error, sessionId: sessionId)
          self.logger.logPerformanceEnd(overallOperationId, sessionId: sessionId, result: "Failed: No result")
          continuation.resume(throwing: error)
          return
        }
        
        let recognizedText = result.text
        
        // Calculate confidence from text blocks
        let textExtractionId = self.logger.logPerformanceStart("MLKit_Text_Extraction", engine: .mlkit, sessionId: sessionId)
        
        // MLKit doesn't provide confidence scores at element level, so we'll estimate based on text quality
        var totalElements = 0
        var totalCharacters = 0
        
        for block in result.blocks {
          for line in block.lines {
            totalElements += line.elements.count
            for element in line.elements {
              totalCharacters += element.text.count
            }
          }
        }
        
        // Estimate confidence based on text characteristics
        let averageElementLength = totalElements > 0 ? Double(totalCharacters) / Double(totalElements) : 0.0
        let estimatedConfidence = min(0.95, max(0.6, 0.7 + (averageElementLength / 20.0))) // 0.6 to 0.95 range
        
        // Log detailed metrics
        self.logger.logPerformanceMetric("blocks_count", value: Double(result.blocks.count), engine: .mlkit, sessionId: sessionId)
        self.logger.logPerformanceMetric("elements_count", value: Double(totalElements), engine: .mlkit, sessionId: sessionId)
        self.logger.logPerformanceMetric("total_characters", value: Double(recognizedText.count), engine: .mlkit, sessionId: sessionId)
        self.logger.logPerformanceMetric("average_element_length", value: averageElementLength, engine: .mlkit, sessionId: sessionId)
        self.logger.logPerformanceMetric("estimated_confidence", value: estimatedConfidence, engine: .mlkit, sessionId: sessionId)
        self.logger.logPerformanceMetric("processing_time", value: processingTime, engine: .mlkit, sessionId: sessionId)
        
        // Log block details
        for (index, block) in result.blocks.enumerated() {
          let blockText = block.text.replacingOccurrences(of: "\n", with: " ")
          let preview = String(blockText.prefix(30))
          self.logger.logProcess("MLKit text block \(index)", details: "'\(preview)...' (\(block.lines.count) lines)", sessionId: sessionId)
        }
        
        self.logger.logPerformanceEnd(textExtractionId, sessionId: sessionId, result: "\(recognizedText.count) characters")
        
        self.logger.logTextExtraction(engine: .mlkit, textLength: recognizedText.count, confidence: estimatedConfidence, sessionId: sessionId)
        self.logger.logPerformanceEnd(overallOperationId, sessionId: sessionId, result: "Success")
        
        self.logger.logSuccess("MLKit OCR text recognition complete",
                               details: "Confidence: \(String(format: "%.1f", estimatedConfidence * 100))%, Characters: \(recognizedText.count), Blocks: \(result.blocks.count)",
                               sessionId: sessionId)
        
        continuation.resume(returning: (recognizedText, estimatedConfidence, processingTime))
      }
    }
  }
}
#else
// Simulator fallback - MLKitOCRService stub
class MLKitOCRService {
  private let logger = OCRLogger.shared
  
  func recognizeText(from image: UIImage, sessionId: String? = nil) async throws -> (text: String, confidence: Double, processingTime: Double) {
    logger.logWarning("MLKit OCR called in simulator", message: "This should not happen - use Vision OCR instead", sessionId: sessionId)
    throw NSError(domain: "MLKitOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "MLKit OCR not available in simulator"])
  }
}
#endif

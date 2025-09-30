//
//  VisionOCRService.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation
import Vision
import UIKit

class VisionOCRService {
    private let logger = OCRLogger.shared

    func recognizeText(from image: UIImage, sessionId: String? = nil) async throws -> (text: String, confidence: Double, processingTime: Double) {
        logger.logProcess("Starting Vision OCR text recognition", sessionId: sessionId)

        let imageSize = image.size
        logger.logPerformanceMetric("image_width", value: Double(imageSize.width), engine: .vision, sessionId: sessionId)
        logger.logPerformanceMetric("image_height", value: Double(imageSize.height), engine: .vision, sessionId: sessionId)
        logger.logPerformanceMetric("image_scale", value: Double(image.scale), engine: .vision, sessionId: sessionId)

        let overallOperationId = logger.logPerformanceStart("Vision_OCR_Complete", engine: .vision, sessionId: sessionId)
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let cgImage = image.cgImage else {
            logger.logError("Vision OCR failed", error: OCRError.invalidImage, sessionId: sessionId)
            throw OCRError.invalidImage
        }

        logger.logProcess("CGImage conversion successful", details: "Size: \(cgImage.width)x\(cgImage.height)", sessionId: sessionId)

        return try await withCheckedThrowingContinuation { continuation in
            let requestSetupId = logger.logPerformanceStart("Vision_Request_Setup", engine: .vision, sessionId: sessionId)

            let request = VNRecognizeTextRequest { request, error in
                let requestProcessingId = self.logger.logPerformanceStart("Vision_Request_Processing", engine: .vision, sessionId: sessionId)

                if let error = error {
                    self.logger.logError("Vision request failed", error: error, sessionId: sessionId)
                    self.logger.logPerformanceEnd(requestProcessingId, sessionId: sessionId, result: "Error")
                    self.logger.logPerformanceEnd(overallOperationId, sessionId: sessionId, result: "Error")
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.logger.logError("Vision OCR failed", error: OCRError.noTextFound, sessionId: sessionId)
                    self.logger.logPerformanceEnd(requestProcessingId, sessionId: sessionId, result: "No observations")
                    self.logger.logPerformanceEnd(overallOperationId, sessionId: sessionId, result: "No observations")
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                self.logger.logProcess("Vision observations received", details: "\(observations.count) text blocks found", sessionId: sessionId)
                self.logger.logPerformanceMetric("observations_count", value: Double(observations.count), engine: .vision, sessionId: sessionId)

                let textExtractionId = self.logger.logPerformanceStart("Vision_Text_Extraction", engine: .vision, sessionId: sessionId)

                var recognizedText = ""
                var totalConfidence = 0.0
                var observationCount = 0
                var totalCharacters = 0

                for (index, observation) in observations.enumerated() {
                    guard let topCandidate = observation.topCandidates(1).first else {
                        self.logger.logWarning("Vision OCR", message: "No candidates for observation \(index)", sessionId: sessionId)
                        continue
                    }

                    recognizedText += topCandidate.string + "\n"
                    totalConfidence += Double(topCandidate.confidence)
                    totalCharacters += topCandidate.string.count
                    observationCount += 1

                    // Log individual text block performance
                    self.logger.logProcess("Text block \(index)", details: "'\(String(topCandidate.string.prefix(30)))...' (confidence: \(String(format: "%.2f", topCandidate.confidence)))", sessionId: sessionId)
                }

                self.logger.logPerformanceEnd(textExtractionId, sessionId: sessionId, result: "\(totalCharacters) characters")
                self.logger.logPerformanceMetric("total_characters", value: Double(totalCharacters), engine: .vision, sessionId: sessionId)
                self.logger.logPerformanceMetric("characters_per_observation", value: observationCount > 0 ? Double(totalCharacters) / Double(observationCount) : 0, engine: .vision, sessionId: sessionId)

                let averageConfidence = observationCount > 0 ? totalConfidence / Double(observationCount) : 0.0
                let processingTime = CFAbsoluteTimeGetCurrent() - startTime

                self.logger.logPerformanceMetric("average_confidence", value: averageConfidence, engine: .vision, sessionId: sessionId)
                self.logger.logPerformanceMetric("processing_time", value: processingTime, engine: .vision, sessionId: sessionId)

                let finalText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.logger.logTextExtraction(engine: .vision, textLength: finalText.count, confidence: averageConfidence, sessionId: sessionId)

                self.logger.logPerformanceEnd(requestProcessingId, sessionId: sessionId, result: "\(finalText.count) chars")
                self.logger.logPerformanceEnd(overallOperationId, sessionId: sessionId, result: "Success")

                self.logger.logSuccess("Vision OCR completed", details: "Text: \(finalText.count) chars, Confidence: \(String(format: "%.1f", averageConfidence * 100))%", sessionId: sessionId)

                continuation.resume(returning: (
                    text: finalText,
                    confidence: averageConfidence,
                    processingTime: processingTime
                ))
            }

            // Configure for better text recognition
            logger.logProcess("Configuring Vision request", details: "Recognition level: accurate, Languages: en,id", sessionId: sessionId)
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en", "id"] // English and Indonesian
            request.usesLanguageCorrection = true

            logger.logPerformanceEnd(requestSetupId, sessionId: sessionId, result: "Request configured")

            let handlerExecutionId = logger.logPerformanceStart("Vision_Handler_Execution", engine: .vision, sessionId: sessionId)
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                logger.logProcess("Executing Vision request", sessionId: sessionId)
                try handler.perform([request])
                logger.logPerformanceEnd(handlerExecutionId, sessionId: sessionId, result: "Request executed")
            } catch {
                logger.logError("Vision handler execution failed", error: error, sessionId: sessionId)
                logger.logPerformanceEnd(handlerExecutionId, sessionId: sessionId, result: "Error")
                logger.logPerformanceEnd(overallOperationId, sessionId: sessionId, result: "Error")
                continuation.resume(throwing: error)
            }
        }
    }
}

enum OCRError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .noTextFound:
            return "No text found in image"
        case .processingFailed:
            return "OCR processing failed"
        }
    }
}
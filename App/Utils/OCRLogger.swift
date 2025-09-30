//
//  OCRLogger.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation
import os.log

class OCRLogger {
  static let shared = OCRLogger()
  
  private let logger = Logger(subsystem: "com.diki.scan.ocr.ktp", category: "OCR")
  private let performanceLogger = Logger(subsystem: "com.diki.scan.ocr.ktp", category: "Performance")
  private let uiLogger = Logger(subsystem: "com.diki.scan.ocr.ktp", category: "UI")
  
  private var sessions: [String: OCRSession] = [:]
  private let sessionQueue = DispatchQueue(label: "ocr.logger.session", attributes: .concurrent)
  
  private init() {}
  
  // MARK: - Session Management
  
  func startSession() -> String {
    let sessionId = UUID().uuidString
    let session = OCRSession(id: sessionId, startTime: Date())
    
    sessionQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      self.sessions[sessionId] = session
    }
    
    logger.info("📱 Started OCR session: \(sessionId)")
    return sessionId
  }
  
  func endSession(_ sessionId: String) {
    sessionQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      if let session = self.sessions[sessionId] {
        let totalTime = Date().timeIntervalSince(session.startTime)
        self.logger.info("🏁 Ended OCR session: \(sessionId) - Total time: \(String(format: "%.3f", totalTime))s")
        self.sessions.removeValue(forKey: sessionId)
      }
    }
  }
  
  func getSession(_ sessionId: String) -> OCRSession? {
    return sessionQueue.sync {
      return sessions[sessionId]
    }
  }
  
  // MARK: - Performance Logging
  
  func logPerformanceStart(_ operation: String, engine: OCREngine, sessionId: String? = nil) -> String {
    let operationId = UUID().uuidString
    let startTime = CFAbsoluteTimeGetCurrent()
    
    performanceLogger.info("⏱️ START [\(engine.rawValue)] \(operation) - ID: \(operationId)")
    
    // Store timing info for end logging
    sessionQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      if let sessionId = sessionId, var session = self.sessions[sessionId] {
        session.operations[operationId] = PerformanceOperation(
          id: operationId,
          name: operation,
          engine: engine,
          startTime: startTime
        )
        self.sessions[sessionId] = session
      }
    }
    
    return operationId
  }
  
  func logPerformanceEnd(_ operationId: String, sessionId: String? = nil, result: String? = nil) {
    let endTime = CFAbsoluteTimeGetCurrent()
    
    sessionQueue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      if let sessionId = sessionId,
         var session = self.sessions[sessionId],
         let operation = session.operations[operationId] {
        
        let duration = endTime - operation.startTime
        let updatedOperation = PerformanceOperation(
          id: operation.id,
          name: operation.name,
          engine: operation.engine,
          startTime: operation.startTime,
          endTime: endTime,
          duration: duration,
          result: result
        )
        
        session.operations[operationId] = updatedOperation
        self.sessions[sessionId] = session
        
        self.performanceLogger.info("⏱️ END [\(operation.engine.rawValue)] \(operation.name) - Duration: \(String(format: "%.3f", duration))s")
        
        if let result = result {
          self.performanceLogger.debug("📊 Result preview: \(String(result.prefix(50)))...")
        }
      }
    }
  }
  
  func logPerformanceMetric(_ metric: String, value: Double, engine: OCREngine, sessionId: String? = nil) {
    performanceLogger.info("📊 [\(engine.rawValue)] \(metric): \(String(format: "%.3f", value))")
    
    if let sessionId = sessionId {
      sessionQueue.async(flags: .barrier) { [weak self] in
        guard let self = self else { return }
        if var session = self.sessions[sessionId] {
          session.metrics["\(engine.rawValue)_\(metric)"] = value
          self.sessions[sessionId] = session
        }
      }
    }
  }
  
  // MARK: - Process Logging
  
  func logProcess(_ process: String, details: String? = nil, sessionId: String? = nil) {
    var message = "🔄 \(process)"
    if let details = details {
      message += " - \(details)"
    }
    logger.info("\(message)")
  }
  
  func logSuccess(_ operation: String, details: String? = nil, sessionId: String? = nil) {
    var message = "✅ \(operation)"
    if let details = details {
      message += " - \(details)"
    }
    logger.info("\(message)")
  }
  
  func logError(_ operation: String, error: Error, sessionId: String? = nil) {
    logger.error("❌ \(operation) - Error: \(error.localizedDescription)")
  }
  
  func logWarning(_ operation: String, message: String, sessionId: String? = nil) {
    logger.warning("⚠️ \(operation) - \(message)")
  }
  
  // MARK: - UI Logging
  
  func logUIEvent(_ event: String, details: String? = nil) {
    var message = "🖱️ \(event)"
    if let details = details {
      message += " - \(details)"
    }
    uiLogger.info("\(message)")
  }
  
  func logUserAction(_ action: String, duration: Double? = nil) {
    var message = "👆 User: \(action)"
    if let duration = duration {
      message += " (took \(String(format: "%.1f", duration))s)"
    }
    uiLogger.info("\(message)")
  }
  
  // MARK: - OCR Specific Logging
  
  func logImageCapture(source: ImageSource, imageSize: CGSize, sessionId: String? = nil) {
    let sizeString = "\(Int(imageSize.width))x\(Int(imageSize.height))"
    logger.info("📸 Image captured from \(source.logDescription) - Size: \(sizeString)")
  }
  
  func logTextExtraction(engine: OCREngine, textLength: Int, confidence: Double, sessionId: String? = nil) {
    logger.info("📝 [\(engine.rawValue)] Text extracted - Length: \(textLength) chars, Confidence: \(String(format: "%.1f", confidence * 100))%")
  }
  
  func logFieldExtraction(field: String, value: String?, success: Bool, sessionId: String? = nil) {
    let status = success ? "✅" : "❌"
    let valuePreview = value?.prefix(20) ?? "nil"
    logger.debug("\(status) Field '\(field)': \(valuePreview)")
  }
  
  // MARK: - Session Summary
  
  func getSessionSummary(_ sessionId: String) -> OCRSessionSummary? {
    return sessionQueue.sync {
      guard let session = sessions[sessionId] else { return nil }
      
      let visionOperations = session.operations.values.filter { $0.engine == .vision }
      let mlkitOperations = session.operations.values.filter { $0.engine == .mlkit }
      
      let visionTotalTime = visionOperations.compactMap { $0.duration }.reduce(0, +)
      let mlkitTotalTime = mlkitOperations.compactMap { $0.duration }.reduce(0, +)
      
      return OCRSessionSummary(
        sessionId: sessionId,
        totalDuration: Date().timeIntervalSince(session.startTime),
        visionProcessingTime: visionTotalTime,
        mlkitProcessingTime: mlkitTotalTime,
        operationsCount: session.operations.count,
        metrics: session.metrics
      )
    }
  }
  
  func logSessionSummary(_ sessionId: String) {
    guard let summary = getSessionSummary(sessionId) else { return }
    
    logger.info("📊 Session Summary (\(sessionId)):")
    logger.info("   Total Duration: \(String(format: "%.3f", summary.totalDuration))s")
    logger.info("   Vision Processing: \(String(format: "%.3f", summary.visionProcessingTime))s")
    logger.info("   MLKit Processing: \(String(format: "%.3f", summary.mlkitProcessingTime))s")
    logger.info("   Operations: \(summary.operationsCount)")
    
    for (metric, value) in summary.metrics {
      logger.info("   \(metric): \(String(format: "%.3f", value))")
    }
  }
}

// MARK: - Data Models

struct OCRSession {
  let id: String
  let startTime: Date
  var operations: [String: PerformanceOperation] = [:]
  var metrics: [String: Double] = [:]
}

struct PerformanceOperation {
  let id: String
  let name: String
  let engine: OCREngine
  let startTime: CFAbsoluteTime
  var endTime: CFAbsoluteTime?
  var duration: Double?
  var result: String?
}

struct OCRSessionSummary {
  let sessionId: String
  let totalDuration: TimeInterval
  let visionProcessingTime: Double
  let mlkitProcessingTime: Double
  let operationsCount: Int
  let metrics: [String: Double]
}

// MARK: - Extensions

extension ImageSource {
  var logDescription: String {
    switch self {
    case .camera: return "Camera"
    case .gallery: return "Gallery"
    }
  }
}

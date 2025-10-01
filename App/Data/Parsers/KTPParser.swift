//
//  KTPParser.swift
//  Scan OCR KTP - Data Layer
//
//  Clean Architecture implementation of KTP Parser
//  Follows SOLID principles with Strategy Pattern for field extraction
//
//  Created by Dicky Darmawan on 30/09/25.
//

import Foundation

// MARK: - KTP Parser Implementation

/// Modern KTP parser using Strategy Pattern and Dependency Injection
/// - Single Responsibility: Orchestrates field extraction and result assembly
/// - Open/Closed: Extensible through new extractors without modifying parser
/// - Liskov Substitution: All extractors conform to same protocol
/// - Interface Segregation: Clean protocol contracts
/// - Dependency Inversion: Depends on abstractions (protocols), not concrete types
final class KTPParser: KTPParserProtocol {

  // MARK: - Properties

  private let logger: OCRLoggerProtocol
  private let extractors: [KTPFieldExtractionStrategy]

  // MARK: - Initialization

  /// Initialize with dependency injection
  /// - Parameters:
  ///   - logger: Logger for tracking operations
  ///   - extractors: Array of field extraction strategies
  init(
    logger: OCRLoggerProtocol = OCRLogger.shared,
    extractors: [KTPFieldExtractionStrategy]? = nil
  ) {
    self.logger = logger
    self.extractors = extractors ?? Self.defaultExtractors()
  }

  /// Factory method for default extractors
  private static func defaultExtractors() -> [KTPFieldExtractionStrategy] {
    return [
      NIKExtractor(),
      NamaExtractor(),
      TempatLahirExtractor(),
      TanggalLahirExtractor(),
      JenisKelaminExtractor(),
      AlamatExtractor(),
      RTRWExtractor(),
      KelurahanExtractor(),
      KecamatanExtractor(),
      AgamaExtractor(),
      StatusPerkawinanExtractor(),
      PekerjaanExtractor(),
      KewarganegaraanExtractor(),
      BerlakuHinggaExtractor(),
      GolonganDarahExtractor()
    ]
  }

  // MARK: - Public API

  func parse(
    text: String,
    confidence: Double,
    engine: OCREngine,
    processingTime: TimeInterval
  ) -> KTPData {
    let sessionId: String? = nil
    logger.logProcess(
      "Starting KTP data parsing",
      details: "Engine: \(engine.rawValue), Text length: \(text.count)",
      sessionId: sessionId
    )

    let parsingOperationId = logger.logPerformanceStart(
      "KTP_Field_Extraction",
      engine: engine,
      sessionId: sessionId
    )

    // Preprocess text into lines
    let lines = preprocessText(text, sessionId: sessionId)

    // Extract all fields using strategies
    let extractedFields = extractAllFields(from: lines, engine: engine, sessionId: sessionId)

    // Calculate metrics
    let metrics = calculateExtractionMetrics(extractedFields, engine: engine, sessionId: sessionId)

    logger.logPerformanceEnd(
      parsingOperationId,
      sessionId: sessionId,
      result: "\(metrics.successCount)/\(metrics.totalCount) fields extracted"
    )

    logger.logSuccess(
      "KTP parsing complete",
      details: "Success rate: \(String(format: "%.1f", metrics.successRate * 100))% (\(metrics.successCount)/\(metrics.totalCount))",
      sessionId: sessionId
    )

    return assembleKTPData(
      from: extractedFields,
      rawText: text,
      confidence: confidence,
      engine: engine,
      processingTime: processingTime
    )
  }

  // MARK: - Private Methods

  /// Preprocess raw text into clean lines
  private func preprocessText(_ text: String, sessionId: String?) -> [String] {
    let lines = text
      .components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    logger.logProcess(
      "Text preprocessing complete",
      details: "\(lines.count) lines to process",
      sessionId: sessionId
    )

    return lines
  }

  /// Extract all fields using configured strategies
  private func extractAllFields(
    from lines: [String],
    engine: OCREngine,
    sessionId: String?
  ) -> [String: String?] {
    var fields: [String: String?] = [:]

    for extractor in extractors {
      let value = extractor.extract(from: lines)
      fields[extractor.fieldName] = value

      logger.logFieldExtraction(
        field: extractor.fieldName,
        value: value,
        success: value != nil,
        sessionId: sessionId
      )
    }

    return fields
  }

  /// Calculate extraction success metrics
  private func calculateExtractionMetrics(
    _ fields: [String: String?],
    engine: OCREngine,
    sessionId: String?
  ) -> (successCount: Int, totalCount: Int, successRate: Double) {
    let successCount = fields.values.compactMap { $0 }.count
    let totalCount = fields.count
    let successRate = Double(successCount) / Double(totalCount)

    logger.logPerformanceMetric(
      "extraction_success_rate",
      value: successRate,
      engine: engine,
      sessionId: sessionId
    )

    logger.logPerformanceMetric(
      "extracted_fields_count",
      value: Double(successCount),
      engine: engine,
      sessionId: sessionId
    )

    logger.logPerformanceMetric(
      "total_fields_count",
      value: Double(totalCount),
      engine: engine,
      sessionId: sessionId
    )

    return (successCount, totalCount, successRate)
  }

  /// Assemble final KTPData from extracted fields
  private func assembleKTPData(
    from fields: [String: String?],
    rawText: String,
    confidence: Double,
    engine: OCREngine,
    processingTime: TimeInterval
  ) -> KTPData {
    return KTPData(
      nik: fields["NIK"] ?? nil,
      nama: fields["Nama"] ?? nil,
      tempatLahir: fields["TempatLahir"] ?? nil,
      tanggalLahir: fields["TanggalLahir"] ?? nil,
      jenisKelamin: fields["JenisKelamin"] ?? nil,
      alamat: fields["Alamat"] ?? nil,
      rtRw: fields["RTRW"] ?? nil,
      kelurahan: fields["Kelurahan"] ?? nil,
      kecamatan: fields["Kecamatan"] ?? nil,
      agama: fields["Agama"] ?? nil,
      statusPerkawinan: fields["StatusPerkawinan"] ?? nil,
      pekerjaan: fields["Pekerjaan"] ?? nil,
      kewarganegaraan: fields["Kewarganegaraan"] ?? nil,
      berlakuHingga: fields["BerlakuHingga"] ?? nil,
      golonganDarah: fields["GolonganDarah"] ?? nil,
      rawText: rawText,
      confidence: confidence,
      ocrEngine: engine,
      processingTime: processingTime
    )
  }
}

// MARK: - OCR Logger Protocol

/// Protocol for OCR logging operations (Dependency Inversion)
protocol OCRLoggerProtocol {
  func logProcess(_ message: String, details: String?, sessionId: String?)
  func logPerformanceStart(_ operation: String, engine: OCREngine, sessionId: String?) -> String
  func logPerformanceEnd(_ operationId: String, sessionId: String?, result: String?)
  func logPerformanceMetric(_ name: String, value: Double, engine: OCREngine, sessionId: String?)
  func logFieldExtraction(field: String, value: String?, success: Bool, sessionId: String?)
  func logSuccess(_ message: String, details: String?, sessionId: String?)
}

// MARK: - OCRLogger Conformance

extension OCRLogger: OCRLoggerProtocol {}

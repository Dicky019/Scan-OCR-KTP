//
//  MLKitOCRTests.swift
//  Scan OCR KTP Tests
//
//  Tests for Google MLKit OCR functionality
//  Note: These tests only run on physical devices (not simulator)
//

import Testing
import UIKit
@testable import Scan_OCR_KTP

#if !targetEnvironment(simulator)
@Suite("MLKit OCR", .tags(.mlkit, .ocr), .serialized)
@MainActor
struct MLKitOCRTests {
  
  static let manager = OCRManager()
  static let testImage = UIImage(resource: .ktpTesting)
  
  @Test("Returns valid result structure")
  func resultStructure() async throws {
    let result = await Self.manager.processWithMLKit(Self.testImage)
    
    #expect(result != nil, "MLKit OCR should return a result")
    
    guard let ktpData = result else { return }
    
    // Validate result structure
    #expect(ktpData.ocrEngine == .mlkit, "Engine identifier should be MLKit")
    #expect(ktpData.processingTime > 0, "Processing time must be positive")
    #expect(!ktpData.rawText.isEmpty, "Raw text should not be empty")
    #expect(ktpData.confidence > 0 && ktpData.confidence <= 1.0, "Confidence should be between 0 and 1")
    
    // Allow cleanup
    try await Task.sleep(nanoseconds: 100_000_000)
  }
  
  @Test("Extracts sufficient text from KTP")
  func textExtraction() async throws {
    let result = await Self.manager.processWithMLKit(Self.testImage)
    
    guard let ktpData = result else {
      Issue.record("MLKit OCR returned nil")
      return
    }
    
    #expect(ktpData.rawText.count > 100, "Should extract at least 100 characters from KTP")
    #expect(ktpData.confidence >= 0.5, "MLKit should achieve at least 50% confidence on test image")
    
    print("📝 MLKit extracted \(ktpData.rawText.count) characters with \(String(format: "%.1f%%", ktpData.confidence * 100)) confidence")
    
    // Allow cleanup
    try await Task.sleep(nanoseconds: 100_000_000)
  }
  
  @Test("Extracts KTP structured fields")
  func fieldExtraction() async throws {
    let result = await Self.manager.processWithMLKit(Self.testImage)
    
    guard let ktpData = result else {
      Issue.record("MLKit OCR returned nil")
      return
    }
    
    // Count extracted fields
    let fields: [(String, String?)] = [
      ("NIK", ktpData.nik),
      ("Nama", ktpData.nama),
      ("Tempat Lahir", ktpData.tempatLahir),
      ("Tanggal Lahir", ktpData.tanggalLahir),
      ("Jenis Kelamin", ktpData.jenisKelamin),
      ("Alamat", ktpData.alamat),
      ("RT/RW", ktpData.rtRw),
      ("Agama", ktpData.agama),
      ("Status Perkawinan", ktpData.statusPerkawinan),
      ("Pekerjaan", ktpData.pekerjaan)
    ]
    
    let extractedCount = fields.filter { $0.1 != nil }.count
    
    #expect(extractedCount >= 3, "MLKit should extract at least 3 KTP fields (got \(extractedCount)/\(fields.count))")
    
    // Detailed logging
    print("\n📊 MLKit OCR Field Extraction:")
    for (name, value) in fields {
      let status = value != nil ? "✅" : "❌"
      print("  \(status) \(name): \(value ?? "nil")")
    }
    print("  Total: \(extractedCount)/\(fields.count) fields extracted\n")
    
    // Allow cleanup
    try await Task.sleep(nanoseconds: 100_000_000)
  }
  
  @Test("Completes within acceptable time", .tags(.performance))
  func performance() async throws {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = await Self.manager.processWithMLKit(Self.testImage)
    let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
    
    guard let ktpData = result else {
      Issue.record("MLKit OCR returned nil")
      return
    }
    
    // Performance assertions
    #expect(elapsedTime < 10.0, "MLKit should complete within 10 seconds (took \(String(format: "%.2f", elapsedTime))s)")
    #expect(ktpData.processingTime > 0, "Processing time should be recorded")
    #expect(ktpData.processingTime <= elapsedTime + 0.1, "Recorded time should match elapsed time")
    
    // Performance feedback
    if ktpData.processingTime < 1.0 {
      print("⚡ Excellent performance: \(String(format: "%.3f", ktpData.processingTime))s")
    } else if ktpData.processingTime < 2.0 {
      print("✅ Good performance: \(String(format: "%.3f", ktpData.processingTime))s")
    } else {
      print("⚠️ Acceptable but slow: \(String(format: "%.3f", ktpData.processingTime))s")
    }
    
    // Allow cleanup
    try await Task.sleep(nanoseconds: 100_000_000)
  }
  
  @Test("Single engine processing works correctly")
  func singleEngineProcessing() async throws {
    // Process with MLKit only
    let result = await Self.manager.processWithSingleEngine(Self.testImage, engine: .mlkit)
    
    #expect(result != nil, "Single engine processing should return result")
    
    guard let ktpData = result else { return }
    
    #expect(ktpData.ocrEngine == .mlkit, "Result should be from requested engine")
    #expect(!ktpData.rawText.isEmpty, "Should extract text")
    #expect(ktpData.processingTime > 0, "Should record processing time")
    
    // Allow cleanup
    try await Task.sleep(nanoseconds: 100_000_000)
  }
}
#endif

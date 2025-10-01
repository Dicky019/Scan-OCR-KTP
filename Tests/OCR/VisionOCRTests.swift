//
//  VisionOCRTests.swift
//  Scan OCR KTP Tests
//
//  Tests for Apple Vision OCR functionality
//

import Testing
import UIKit
@testable import Scan_OCR_KTP

@Suite("Vision OCR", .tags(.vision, .ocr), .serialized)
@MainActor
struct VisionOCRTests {
  
  static let manager = OCRManager()
  static let testImage = UIImage(resource: .ktpTesting)
  
  @Test("Returns valid result structure")
  func resultStructure() async throws {
    let result = await Self.manager.processWithVision(Self.testImage)
    
    #expect(result != nil, "Vision OCR should return a result")
    
    guard let ktpData = result else { return }
    
    // Validate result structure
    #expect(ktpData.ocrEngine == .vision, "Engine identifier should be Vision")
    #expect(ktpData.processingTime > 0, "Processing time must be positive")
    #expect(!ktpData.rawText.isEmpty, "Raw text should not be empty")
    #expect(ktpData.confidence > 0 && ktpData.confidence <= 1.0, "Confidence should be between 0 and 1")
  }
  
  @Test("Extracts sufficient text from KTP")
  func textExtraction() async throws {
    let result = await Self.manager.processWithVision(Self.testImage)
    
    guard let ktpData = result else {
      Issue.record("Vision OCR returned nil")
      return
    }
    
    #expect(ktpData.rawText.count > 100, "Should extract at least 100 characters from KTP")
    #expect(ktpData.confidence >= 0.45, "Vision should achieve at least 45% confidence on test image")
    
    print("📝 Vision extracted \(ktpData.rawText.count) characters with \(String(format: "%.1f%%", ktpData.confidence * 100)) confidence")
  }
  
  @Test("Extracts KTP structured fields")
  func fieldExtraction() async throws {
    let result = await Self.manager.processWithVision(Self.testImage)
    
    guard let ktpData = result else {
      Issue.record("Vision OCR returned nil")
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
    
    #expect(extractedCount >= 3, "Vision should extract at least 3 KTP fields (got \(extractedCount)/\(fields.count))")
    
    // Detailed logging
    print("\n📊 Vision OCR Field Extraction:")
    for (name, value) in fields {
      let status = value != nil ? "✅" : "❌"
      print("  \(status) \(name): \(value ?? "nil")")
    }
    print("  Total: \(extractedCount)/\(fields.count) fields extracted\n")
  }
  
  @Test("Completes within acceptable time", .tags(.performance))
  func performance() async throws {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = await Self.manager.processWithVision(Self.testImage)
    let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
    
    guard let ktpData = result else {
      Issue.record("Vision OCR returned nil")
      return
    }
    
    // Performance assertions
    #expect(elapsedTime < 10.0, "Vision should complete within 10 seconds (took \(String(format: "%.2f", elapsedTime))s)")
    #expect(ktpData.processingTime > 0, "Processing time should be recorded")
    #expect(ktpData.processingTime <= elapsedTime + 0.1, "Recorded time should match elapsed time")
    
    // Performance feedback
    if ktpData.processingTime < 1.5 {
      print("⚡ Excellent performance: \(String(format: "%.3f", ktpData.processingTime))s")
    } else if ktpData.processingTime < 3.0 {
      print("✅ Good performance: \(String(format: "%.3f", ktpData.processingTime))s")
    } else {
      print("⚠️ Acceptable but slow: \(String(format: "%.3f", ktpData.processingTime))s")
    }
  }
  
  @Test("Handles tiny image with proper error")
  func tinyImageHandling() async throws {
    // Create a 2x2 pixel image (below 3x3 minimum required by Vision)
    let size = CGSize(width: 2, height: 2)
    UIGraphicsBeginImageContext(size)
    UIColor.white.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    let tinyImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    let result = await Self.manager.processWithVision(tinyImage)
    
    // Should return nil due to image being too small (Vision requires 3x3 minimum)
    #expect(result == nil, "Should return nil for image below 3x3 pixels")
  }
  
  @Test("Handles minimum valid image size")
  func minimumImageSize() async throws {
    // Create a 10x10 pixel image (above minimum)
    let size = CGSize(width: 10, height: 10)
    UIGraphicsBeginImageContext(size)
    UIColor.white.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    let smallImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    let result = await Self.manager.processWithVision(smallImage)
    
    // Should not crash with valid minimum size
    #expect(result != nil, "Should handle minimum valid image size")
  }
}

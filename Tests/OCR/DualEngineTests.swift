//
//  DualEngineTests.swift
//  Scan OCR KTP Tests
//
//  Tests for dual OCR engine comparison (Vision + MLKit)
//

import Testing
import UIKit
@testable import Scan_OCR_KTP

#if !targetEnvironment(simulator)
@Suite("Dual OCR Engine Comparison", .tags(.integration, .ocr), .serialized)
@MainActor
struct DualEngineTests {
  
  static let manager = OCRManager()
  static let testImage = UIImage(resource: .ktpTesting)
  
  @Test("Dual engine processing completes successfully")
  func dualEngineProcessing() async throws {
    let result = await Self.manager.processImage(Self.testImage)
    
    // Verify both engines executed
    #expect(result.visionResult != nil, "Vision result should be present")
    #expect(result.mlkitResult != nil, "MLKit result should be present")
    #expect(result.hasBothResults, "Should have results from both engines")
    
    // Verify processing times recorded
    #expect(result.processingTime.vision > 0, "Vision processing time should be recorded")
    #expect(result.processingTime.mlkit > 0, "MLKit processing time should be recorded")
    
    // Verify best result selection
    #expect(result.bestResult != nil, "Best result should be selected")
    
    // Allow cleanup
    try await Task.sleep(nanoseconds: 100_000_000)
  }
  
  @Test("Best result selection uses highest confidence")
  func bestResultSelection() async throws {
    let result = await Self.manager.processImage(Self.testImage)
    
    guard let vision = result.visionResult,
          let mlkit = result.mlkitResult,
          let best = result.bestResult else {
      Issue.record("Missing OCR results")
      return
    }
    
    // Best result should match engine with higher confidence
    let expectedEngine = vision.confidence >= mlkit.confidence ? OCREngine.vision : OCREngine.mlkit
    
    #expect(best.ocrEngine == expectedEngine, "Best result should be from engine with highest confidence")
    #expect(best.confidence == max(vision.confidence, mlkit.confidence), "Best result should have the highest confidence")
    
    print("\n🏆 Best Result:")
    print("  Engine: \(best.ocrEngine.rawValue)")
    print("  Confidence: \(String(format: "%.1f%%", best.confidence * 100))")
    print("  Vision: \(String(format: "%.1f%%", vision.confidence * 100))")
    print("  MLKit: \(String(format: "%.1f%%", mlkit.confidence * 100))\n")
    
    // Allow cleanup
    try await Task.sleep(nanoseconds: 100_000_000)
  }
  
  @Test("Compare Vision vs MLKit performance metrics", .tags(.performance))
  func engineComparison() async throws {
    let result = await Self.manager.processImage(Self.testImage)
    
    guard let vision = result.visionResult,
          let mlkit = result.mlkitResult else {
      Issue.record("Missing OCR results")
      return
    }
    
    // Both should produce valid results
    #expect(!vision.rawText.isEmpty, "Vision should extract text")
    #expect(!mlkit.rawText.isEmpty, "MLKit should extract text")
    
    // Both should have reasonable confidence
    #expect(vision.confidence >= 0.4, "Vision confidence should be reasonable")
    #expect(mlkit.confidence >= 0.4, "MLKit confidence should be reasonable")
    
    // Performance comparison
    let timeDiff = abs(vision.processingTime - mlkit.processingTime)
    let fasterEngine = vision.processingTime < mlkit.processingTime ? "Vision" : "MLKit"
    let accuracyWinner = vision.confidence > mlkit.confidence ? "Vision" : "MLKit"
    
    print("\n📊 Engine Comparison:")
    print("┌─────────────────────────────────────┐")
    print("│ Vision OCR                          │")
    print("├─────────────────────────────────────┤")
    print("│ Text: \(vision.rawText.count) chars")
    print("│ Confidence: \(String(format: "%.1f%%", vision.confidence * 100))")
    print("│ Time: \(String(format: "%.3fs", vision.processingTime))")
    print("├─────────────────────────────────────┤")
    print("│ MLKit OCR                           │")
    print("├─────────────────────────────────────┤")
    print("│ Text: \(mlkit.rawText.count) chars")
    print("│ Confidence: \(String(format: "%.1f%%", mlkit.confidence * 100))")
    print("│ Time: \(String(format: "%.3fs", mlkit.processingTime))")
    print("├─────────────────────────────────────┤")
    print("│ Summary                             │")
    print("├─────────────────────────────────────┤")
    print("│ ⚡ Faster: \(fasterEngine) by \(String(format: "%.3fs", timeDiff))")
    print("│ 🎯 More Accurate: \(accuracyWinner)")
    print("└─────────────────────────────────────┘\n")
    
    // Allow cleanup
    try await Task.sleep(nanoseconds: 100_000_000)
  }
}
#endif

// MARK: - OCR Comparison Result Tests

@Suite("OCR Comparison Result", .tags(.models))
struct OCRComparisonResultTests {
  
  @Test("Comparison result structure is valid")
  func comparisonResultStructure() {
    let visionData = KTPData(
      nik: "3171234567890123",
      nama: "TEST USER",
      rawText: "test vision text",
      confidence: 0.92,
      ocrEngine: .vision,
      processingTime: 0.5
    )
    
    let mlkitData = KTPData(
      nik: "3171234567890123",
      nama: "TEST USER",
      rawText: "test mlkit text",
      confidence: 0.88,
      ocrEngine: .mlkit,
      processingTime: 0.7
    )
    
    let result = OCRComparisonResult(
      visionResult: visionData,
      mlkitResult: mlkitData,
      processingTime: (vision: 0.5, mlkit: 0.7)
    )
    
    #expect(result.hasBothResults, "Should have both results")
    #expect(result.bestResult?.ocrEngine == .vision, "Vision should be selected (higher confidence)")
    #expect(result.bestResult?.confidence == 0.92, "Best result should have Vision's confidence")
  }
  
  @Test("Comparison handles single engine result")
  func singleEngineComparison() {
    let visionOnly = KTPData(
      nik: "3171234567890123",
      nama: "TEST USER",
      rawText: "test",
      confidence: 0.85,
      ocrEngine: .vision,
      processingTime: 0.5
    )
    
    let result = OCRComparisonResult(
      visionResult: visionOnly,
      mlkitResult: nil,
      processingTime: (vision: 0.5, mlkit: 0.0)
    )
    
    #expect(!result.hasBothResults, "Should not have both results")
    #expect(result.bestResult?.ocrEngine == .vision, "Vision should be selected")
  }
  
  @Test("Comparison selects MLKit when it has higher confidence")
  func mlkitSelection() {
    let visionData = KTPData(
      nik: "3171234567890123",
      nama: "TEST USER",
      rawText: "test",
      confidence: 0.75,
      ocrEngine: .vision,
      processingTime: 0.5
    )
    
    let mlkitData = KTPData(
      nik: "3171234567890123",
      nama: "TEST USER",
      rawText: "test",
      confidence: 0.92,
      ocrEngine: .mlkit,
      processingTime: 0.6
    )
    
    let result = OCRComparisonResult(
      visionResult: visionData,
      mlkitResult: mlkitData,
      processingTime: (vision: 0.5, mlkit: 0.6)
    )
    
    #expect(result.bestResult?.ocrEngine == .mlkit, "MLKit should be selected (higher confidence)")
    #expect(result.bestResult?.confidence == 0.92, "Best result should have MLKit's confidence")
  }
}

//
//  OCRProcessingViewModel.swift
//  Scan OCR KTP - Presentation Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import SwiftUI

// MARK: - ViewModel (MVVM Pattern)

/// ViewModel for OCR processing view
/// Separates presentation logic from view
@MainActor
final class OCRProcessingViewModel: ObservableObject {

  // MARK: - Published State

  @Published var state: ViewState = .idle
  @Published var ktpData: KTPData?
  @Published var comparisonResult: OCRComparisonResult?
  @Published var errorMessage: String?

  // MARK: - Dependencies

  private let processKTPUseCase: ProcessKTPImageUseCase
  private let logger: LoggerProtocol

  // MARK: - View State

  enum ViewState: Equatable {
    case idle
    case processing
    case success
    case error(String)

    var isProcessing: Bool {
      if case .processing = self { return true }
      return false
    }
  }

  // MARK: - Initialization

  init(
    processKTPUseCase: ProcessKTPImageUseCase,
    logger: LoggerProtocol
  ) {
    self.processKTPUseCase = processKTPUseCase
    self.logger = logger
  }

  // Convenience initializer using DI container
  convenience init(container: DIContainer = .shared) {
    self.init(
      processKTPUseCase: container.makeProcessKTPImageUseCase(),
      logger: container.makeLogger()
    )
  }

  // MARK: - Public Methods

  /// Process image with single OCR engine
  func processImage(_ image: UIImage, engine: OCREngine) async {
    state = .processing
    errorMessage = nil

    logger.logProcess("ViewModel: Processing image with \(engine.rawValue)")

    let result = await processKTPUseCase.execute(image: image, engine: engine)

    switch result {
    case .success(let data):
      ktpData = data
      state = .success
      logger.logSuccess("ViewModel: Processing completed successfully")

    case .failure(let error):
      errorMessage = error.localizedDescription
      state = .error(error.localizedDescription)
      logger.logError("ViewModel: Processing failed - \(error.localizedDescription)")
    }
  }

  /// Process image with multiple engines
  func processImageWithComparison(_ image: UIImage) async {
    state = .processing
    errorMessage = nil

    logger.logProcess("ViewModel: Processing image with comparison")

    let result = await processKTPUseCase.executeWithComparison(image: image)

    switch result {
    case .success(let comparison):
      comparisonResult = comparison
      ktpData = comparison.bestResult
      state = .success
      logger.logSuccess("ViewModel: Comparison completed successfully")

    case .failure(let error):
      errorMessage = error.localizedDescription
      state = .error(error.localizedDescription)
      logger.logError("ViewModel: Comparison failed - \(error.localizedDescription)")
    }
  }

  /// Reset state
  func reset() {
    state = .idle
    ktpData = nil
    comparisonResult = nil
    errorMessage = nil
  }
}

// MARK: - Helper Computed Properties

extension OCRProcessingViewModel {
  var isLoading: Bool {
    state.isProcessing
  }

  var hasResult: Bool {
    ktpData != nil
  }

  var hasError: Bool {
    if case .error = state { return true }
    return false
  }

  var resultConfidence: String? {
    guard let data = ktpData else { return nil }
    return String(format: "%.1f%%", data.confidence * 100)
  }

  var processingEngine: String? {
    ktpData?.ocrEngine.rawValue
  }
}
//
//  DIContainer.swift
//  Scan OCR KTP - Core Layer
//
//  Created by Dicky Darmawan on 30/09/25.
//

import Foundation

// MARK: - Dependency Injection Container

/// Centralized dependency injection container
/// Follows Dependency Inversion Principle and promotes testability
final class DIContainer {

  // MARK: - Singleton

  static let shared = DIContainer()

  private init() {}

  // MARK: - Factories

  /// Create OCR repository with all dependencies
  func makeOCRRepository() -> OCRRepositoryProtocol {
    let visionService = VisionOCRServiceAdapter()

    #if !targetEnvironment(simulator)
    let mlkitService: OCRServiceProtocol? = MLKitOCRServiceAdapter()
    #else
    let mlkitService: OCRServiceProtocol? = nil
    #endif

    let ktpParser = KTPParserAdapter()
    let logger = OCRLoggerAdapter()

    return OCRRepository(
      visionService: visionService,
      mlkitService: mlkitService,
      ktpParser: ktpParser,
      logger: logger
    )
  }

  /// Create Process KTP Image use case
  func makeProcessKTPImageUseCase() -> ProcessKTPImageUseCase {
    let repository = makeOCRRepository()
    let parser = KTPParserAdapter()
    let logger = OCRLoggerAdapter()

    return ProcessKTPImageUseCase(
      ocrRepository: repository,
      ktpParser: parser,
      logger: logger
    )
  }

  /// Create navigation coordinator
  @MainActor
  func makeNavigationCoordinator() -> NavigationCoordinator {
    return NavigationCoordinator()
  }

  /// Create logger
  func makeLogger() -> LoggerProtocol {
    return OCRLoggerAdapter()
  }
}

// MARK: - Factory Protocol (for testing)

protocol DIContainerProtocol {
  func makeOCRRepository() -> OCRRepositoryProtocol
  func makeProcessKTPImageUseCase() -> ProcessKTPImageUseCase
  func makeNavigationCoordinator() -> NavigationCoordinator
  func makeLogger() -> LoggerProtocol
}

extension DIContainer: DIContainerProtocol {}
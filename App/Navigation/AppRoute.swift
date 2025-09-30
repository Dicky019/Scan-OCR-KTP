//
//  AppRoute.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation

// MARK: - App Routes
enum AppRoute: Hashable, CaseIterable {
  case home
  case camera
  case photoPicker
  case imagePreview(imageId: String)
  case ocrResults(imageId: String)
  
  // Route identification
  var id: String {
    switch self {
    case .home:
      return "home"
    case .camera:
      return "camera"
    case .photoPicker:
      return "photoPicker"
    case .imagePreview(let imageId):
      return "imagePreview-\(imageId)"
    case .ocrResults(let imageId):
      return "ocrResults-\(imageId)"
    }
  }
  
  // Route titles for navigation
  var title: String {
    switch self {
    case .home:
      return "KTP Scanner"
    case .camera:
      return "Capture Image"
    case .photoPicker:
      return "Select Image"
    case .imagePreview:
      return "Image Preview"
    case .ocrResults:
      return "OCR Results"
    }
  }
  
  // For CaseIterable - only return routes without associated values
  static var allCases: [AppRoute] {
    return [.home, .camera, .photoPicker]
  }
}

// MARK: - Route Parameters
struct RouteParameters {
  let imageId: String?
  let sourceRoute: AppRoute?
  
  init(imageId: String? = nil, sourceRoute: AppRoute? = nil) {
    self.imageId = imageId
    self.sourceRoute = sourceRoute
  }
}

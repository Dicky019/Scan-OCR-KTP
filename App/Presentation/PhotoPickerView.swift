//
//  PhotoPickerView.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: UIViewControllerRepresentable {
  @EnvironmentObject var coordinator: NavigationCoordinator
  @Environment(\.dismiss) var dismiss
  
  private let logger = OCRLogger.shared
  
  func makeUIViewController(context: Context) -> PHPickerViewController {
    var configuration = PHPickerConfiguration()
    configuration.filter = .images
    configuration.selectionLimit = 1
    
    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = context.coordinator
    return picker
  }
  
  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let parent: PhotoPickerView
    
    init(_ parent: PhotoPickerView) {
      self.parent = parent
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      parent.dismiss()
      
      guard let result = results.first else {
        parent.logger.logUIEvent("Photo picker cancelled")
        return
      }
      
      if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
        result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
          DispatchQueue.main.async {
            if let image = image as? UIImage {
              self.parent.logger.logUIEvent("Photo picker image selected")
              self.parent.logger.logImageCapture(source: .gallery, imageSize: image.size)
              
              // Navigate to image preview using coordinator
              self.parent.coordinator.navigateToImagePreview(with: image)
            } else if let error = error {
              self.parent.logger.logError("Photo picker image load failed", error: error)
            }
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    PhotoPickerView()
      .environmentObject(NavigationCoordinator())
  }
}

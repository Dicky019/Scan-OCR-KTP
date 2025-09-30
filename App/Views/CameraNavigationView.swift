//
//  CameraNavigationView.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import SwiftUI
import UIKit

struct CameraNavigationView: UIViewControllerRepresentable {
  @EnvironmentObject var coordinator: NavigationCoordinator
  @Environment(\.dismiss) var dismiss
  
  private let logger = OCRLogger.shared
  
  func makeUIViewController(context: Context) -> UIViewController {
    // Check if camera is available
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      logger.logWarning("Camera not available", message: "Device doesn't support camera")
      
      // Return a simple alert controller for simulator/devices without camera
      let alert = UIAlertController(
        title: "Camera Not Available",
        message: "Camera is not available on this device. Please use the Photo Library option instead.",
        preferredStyle: .alert
      )
      
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
        self.dismiss()
      })
      
      return alert
    }
    
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    picker.allowsEditing = true
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // No updates needed
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: CameraNavigationView
    
    init(_ parent: CameraNavigationView) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
        parent.logger.logUIEvent("Camera image captured")
        parent.logger.logImageCapture(source: .camera, imageSize: image.size)
        
        // Navigate to image preview using coordinator
        parent.coordinator.navigateToImagePreview(with: image)
      }
      
      DispatchQueue.main.async {
        self.parent.dismiss()
      }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.logger.logUIEvent("Camera cancelled")
      
      DispatchQueue.main.async {
        self.parent.dismiss()
      }
    }
  }
}

#Preview {
  NavigationStack {
    CameraNavigationView()
      .environmentObject(NavigationCoordinator())
  }
}

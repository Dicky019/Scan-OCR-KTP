//
//  ImagePreviewView.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import SwiftUI

struct ImagePreviewView: View {
  let image: UIImage
  let imageId: String
  
  @EnvironmentObject var coordinator: NavigationCoordinator
  @State private var isProcessing = false
  @State private var ocrResults: OCRComparisonResult?
  
  private let logger = OCRLogger.shared
  
  var body: some View {
    VStack {
      // Image Display
      ScrollView {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity)
          .cornerRadius(12)
          .shadow(radius: 5)
      }
      .padding()
      
      Spacer()
      
      // Action Buttons
      VStack(spacing: 16) {
        // Process OCR Button
        Button(action: {
          coordinator.navigateToOCRResults(for: imageId)
        }) {
          HStack {
            if isProcessing {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            } else {
              Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
            }
            
            Text(isProcessing ? "Processing..." : "Process with OCR")
              .font(.headline)
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(isProcessing ? Color.gray : Color.blue)
          .cornerRadius(12)
        }
        .disabled(isProcessing)
        
        // Retake Button
        Button(action: {
          coordinator.pop()
        }) {
          HStack {
            Image(systemName: "arrow.clockwise")
              .font(.title2)
            Text("Retake Image")
              .font(.headline)
          }
          .foregroundColor(.blue)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue.opacity(0.1))
          .cornerRadius(12)
        }
      }
      .padding()
    }
    .onAppear {
      let imageSize = image.size
      logger.logUIEvent("Image preview navigation presented", details: "Size: \(Int(imageSize.width))x\(Int(imageSize.height))")
    }
    .onDisappear {
      logger.logUIEvent("Image preview navigation dismissed")
    }
  }
}

#Preview {
  NavigationStack {
    ImagePreviewView(
      image: UIImage(systemName: "photo")!,
      imageId: "preview-id"
    )
    .environmentObject(NavigationCoordinator())
  }
}

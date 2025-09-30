//
//  HomeView.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator
    private let logger = OCRLogger.shared

    var body: some View {
        VStack(spacing: 30) {
            // App Title
            VStack {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Scan OCR KTP")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Capture or select KTP image for OCR processing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 50)

            Spacer()

            // Action Buttons
            VStack(spacing: 20) {
                // Camera Button
                Button(action: {
                    logger.logUIEvent("Camera button tapped")
                    logger.logUserAction("Initiate camera capture")
                    coordinator.navigateToCamera()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Capture with Camera")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                // Gallery Button
                Button(action: {
                    logger.logUIEvent("Gallery button tapped")
                    logger.logUserAction("Initiate photo picker")
                    coordinator.navigateToPhotoPicker()
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Select from Gallery")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .onAppear {
            logger.logUIEvent("Main app screen appeared")
            logger.logUserAction("App launched")
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationCoordinator())
    }
}
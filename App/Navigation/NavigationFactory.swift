//
//  NavigationFactory.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import SwiftUI

// MARK: - Navigation Factory
struct NavigationFactory {

    // MARK: - View Factory Methods

    @MainActor
    @ViewBuilder
    static func makeView(for route: AppRoute, coordinator: NavigationCoordinator) -> some View {
        switch route {
        case .home:
            HomeView()
                .environmentObject(coordinator)

        case .camera:
            CameraNavigationView()
                .environmentObject(coordinator)
                .navigationTitle(route.title)
                .navigationBarTitleDisplayMode(.inline)

        case .photoPicker:
            PhotoPickerNavigationView()
                .environmentObject(coordinator)
                .navigationTitle(route.title)
                .navigationBarTitleDisplayMode(.inline)

        case .imagePreview(let imageId):
            if let image = coordinator.getImage(by: imageId) {
                ImagePreviewNavigationView(image: image, imageId: imageId)
                    .environmentObject(coordinator)
                    .navigationTitle(route.title)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ErrorView(
                    title: "Image Not Found",
                    message: "The requested image could not be loaded.",
                    action: {
                        coordinator.popToRoot()
                    }
                )
                .environmentObject(coordinator)
            }

        case .ocrResults(let imageId):
            if let image = coordinator.getImage(by: imageId) {
                OCRResultNavigationView(image: image, imageId: imageId)
                    .environmentObject(coordinator)
                    .navigationTitle(route.title)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ErrorView(
                    title: "Image Not Found",
                    message: "The requested image could not be loaded.",
                    action: {
                        coordinator.popToRoot()
                    }
                )
                .environmentObject(coordinator)
            }
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text(title)
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Go Home") {
                action()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension NavigationFactory {
    @MainActor
    static var preview: NavigationCoordinator {
        NavigationCoordinator()
    }
}
#endif
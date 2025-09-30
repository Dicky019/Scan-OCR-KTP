//
//  NavigationCoordinator.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation
import SwiftUI

// MARK: - Navigation Coordinator
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var imageStore: [String: UIImage] = [:]
    private var imageTimestamps: [String: Date] = [:]
    private let maxStoredImages = 5

    private let logger = OCRLogger.shared

    // MARK: - Navigation Methods

    /// Navigate to a specific route
    func push(to route: AppRoute) {
        logger.logUIEvent("Navigation push", details: "Route: \(route.id)")
        path.append(route)
    }

    /// Navigate back to previous screen
    func pop() {
        guard !path.isEmpty else { return }
        logger.logUIEvent("Navigation pop")
        path.removeLast()
    }

    /// Navigate back to root (home)
    func popToRoot() {
        logger.logUIEvent("Navigation pop to root")
        path.removeLast(path.count)
    }

    /// Navigate to a specific route and clear the stack
    func navigateToRoot(then route: AppRoute? = nil) {
        popToRoot()
        if let route = route {
            push(to: route)
        }
    }

    // MARK: - Image Management

    /// Store an image and return its unique ID
    func storeImage(_ image: UIImage) -> String {
        let imageId = UUID().uuidString
        imageStore[imageId] = image
        imageTimestamps[imageId] = Date()
        logger.logUIEvent("Image stored", details: "ID: \(imageId), Size: \(Int(image.size.width))x\(Int(image.size.height))")
        return imageId
    }

    /// Retrieve an image by ID
    func getImage(by id: String) -> UIImage? {
        return imageStore[id]
    }

    /// Clean up old images to manage memory
    func cleanupImages() {
        let oldCount = imageStore.count
        // Keep only the last maxStoredImages images to prevent memory issues
        if imageStore.count > maxStoredImages {
            // Sort by timestamp to remove oldest images
            let sortedByTime = imageTimestamps.sorted { $0.value < $1.value }
            let keysToRemove = sortedByTime.prefix(imageStore.count - maxStoredImages).map { $0.key }

            for key in keysToRemove {
                imageStore.removeValue(forKey: key)
                imageTimestamps.removeValue(forKey: key)
            }
        }
        let newCount = imageStore.count
        if oldCount != newCount {
            logger.logUIEvent("Image cleanup", details: "Removed \(oldCount - newCount) images")
        }
    }

    // MARK: - Navigation Helpers

    /// Navigate to camera and handle image capture
    func navigateToCamera() {
        push(to: .camera)
    }

    /// Navigate to photo picker and handle image selection
    func navigateToPhotoPicker() {
        push(to: .photoPicker)
    }

    /// Navigate to image preview with captured/selected image
    func navigateToImagePreview(with image: UIImage) {
        let imageId = storeImage(image)
        cleanupImages()
        push(to: .imagePreview(imageId: imageId))
    }

    /// Navigate to OCR results
    func navigateToOCRResults(for imageId: String) {
        push(to: .ocrResults(imageId: imageId))
    }

    // MARK: - State Management

    /// Check if we can navigate back
    var canGoBack: Bool {
        !path.isEmpty
    }

    /// Get current route count
    var routeCount: Int {
        path.count
    }

    /// Get the current route if available
    var currentRoute: AppRoute? {
        // This is a simplified approach - in a real app you might want to track this more explicitly
        return path.count > 0 ? nil : .home
    }
}

// MARK: - Navigation Extensions
extension NavigationCoordinator {
    /// Handle deep linking or external navigation requests
    func handleDeepLink(to route: AppRoute) {
        logger.logUIEvent("Deep link navigation", details: "Route: \(route.id)")

        switch route {
        case .home:
            navigateToRoot()
        case .camera:
            navigateToRoot(then: .camera)
        case .photoPicker:
            navigateToRoot(then: .photoPicker)
        case .imagePreview(let imageId):
            if getImage(by: imageId) != nil {
                navigateToRoot(then: .imagePreview(imageId: imageId))
            } else {
                logger.logWarning("Deep link failed", message: "Image not found: \(imageId)")
                navigateToRoot()
            }
        case .ocrResults(let imageId):
            if getImage(by: imageId) != nil {
                navigateToRoot(then: .ocrResults(imageId: imageId))
            } else {
                logger.logWarning("Deep link failed", message: "Image not found: \(imageId)")
                navigateToRoot()
            }
        }
    }
}
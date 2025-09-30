//
//  ImageData.swift
//  Scan OCR KTP
//
//  Created by Dicky Darmawan on 29/09/25.
//

import Foundation
import UIKit

struct CapturedImage {
    let image: UIImage
    let source: ImageSource
    let timestamp: Date

    init(image: UIImage, source: ImageSource) {
        self.image = image
        self.source = source
        self.timestamp = Date()
    }
}

enum ImageSource {
    case camera
    case gallery
}
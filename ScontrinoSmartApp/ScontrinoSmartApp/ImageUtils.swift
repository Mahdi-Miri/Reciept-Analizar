//
//  ImageUtils.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 11/11/25.
//

// FILE: ImageUtils.swift

import UIKit

// This extension adds a helper function to UIImage
extension UIImage {
    
    // Resizes an image to a specific width while maintaining aspect ratio
    func resize(toWidth targetWidth: CGFloat) -> UIImage? {
        let originalSize = self.size
        let targetHeight = (targetWidth / originalSize.width) * originalSize.height
        let targetSize = CGSize(width: targetWidth, height: targetHeight)
        
        // Use UIGraphicsImageRenderer for efficient resizing
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            // This draws the original image into the new, smaller context
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

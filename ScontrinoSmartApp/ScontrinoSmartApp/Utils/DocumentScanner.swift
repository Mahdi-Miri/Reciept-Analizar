//
//  DocumentScanner.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//

import SwiftUI
import VisionKit

// This is the UIKit bridge to show the VNDocumentCameraViewController
struct DocumentScanner: UIViewControllerRepresentable {
    
    // A callback to pass the scanned images back to SwiftUI
    var onFinish: ([CGImage]) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No update logic needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // The Coordinator handles communication from the UIKit controller
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner
        
        init(parent: DocumentScanner) {
            self.parent = parent
        }
        
        // Success: User scanned documents
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan){
            var images: [CGImage] = []
            for i in 0..<scan.pageCount {
                if let cgImage = scan.imageOfPage(at: i).cgImage {
                    images.append(cgImage)
                }
            }
            
            // Call the onFinish handler with the images
            parent.onFinish(images)
            controller.dismiss(animated: true)
        }
        
        // Failure
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scanner failed with error: \(error.localizedDescription)")
            parent.onFinish([]) // Return empty array on failure
            controller.dismiss(animated: true)
        }
        
        // User cancelled
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onFinish([]) // Return empty array on cancel
            controller.dismiss(animated: true)
        }
    }
}

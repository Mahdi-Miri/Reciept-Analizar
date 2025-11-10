//
//  ScanView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//

import SwiftUI
import AVFoundation
import Combine // <-- FIX 1: This was missing (for ObservableObject)

// MARK: - Camera View Model
// This class manages the camera session, permissions, and photo capture.
// NSObject is needed for AVCapturePhotoCaptureDelegate
class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    // The main session that manages camera input and output
    let session = AVCaptureSession()
    
    // The output for capturing a photo
    private let photoOutput = AVCapturePhotoOutput()
    
    // Published properties to update the UI
    @Published var capturedImage: UIImage?
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var isCameraBusy = false // Prevents multiple captures
    
    // Checks the current camera permission status
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission already granted
            permissionStatus = .authorized
            setupSession()
        case .notDetermined:
            // Permission not yet requested
            permissionStatus = .notDetermined
        case .denied, .restricted:
            // Permission denied or restricted
            permissionStatus = .denied
        default:
            break
        }
    }
    
    // Requests camera permission from the user
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionStatus = granted ? .authorized : .denied
                if granted {
                    self?.setupSession()
                }
            }
        }
    }
    
    // Configures the camera session (input device, output)
    private func setupSession() {
        guard permissionStatus == .authorized else { return }
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            // Start configuration
            session.beginConfiguration()
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            
            // Commit configuration and start the session
            session.commitConfiguration()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
            
        } catch {
            print("Error setting up camera session: \(error.localizedDescription)")
        }
    }
    
    // Call this function to capture a photo
    func capturePhoto() {
        guard !isCameraBusy else { return }
        isCameraBusy = true
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // Delegate method: Called when the photo is processed
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            isCameraBusy = false
            return
        }
        
        // Get the image data
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            isCameraBusy = false
            return
        }
        
        // Publish the captured image
        DispatchQueue.main.async {
            self.capturedImage = image
            self.isCameraBusy = false
        }
    }
}

// MARK: - Camera Preview (UIViewRepresentable)
// FIX 2: This is a complete rewrite of the preview to correctly use a
// custom UIView subclass, which fixes all the '...has no member...' errors.

struct CameraPreview: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        // Use our new custom view class
        let previewView = CameraPreviewView(session: session)
        return previewView
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // No update logic needed
    }
    
    // A custom UIView subclass to correctly handle the preview layer's frame
    class CameraPreviewView: UIView {
        private var previewLayer: AVCaptureVideoPreviewLayer?
        
        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            // FIX 3: Use videoRotationAngle instead of deprecated videoOrientation
            if previewLayer.connection?.isVideoRotationAngleSupported(90) == true {
                 previewLayer.connection?.videoRotationAngle = 90 // 90 degrees for Portrait
            }
            
            self.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // This is the key: update the layer's frame when the view's layout changes
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = self.bounds
        }
    }
}


// MARK: - Main Scan View (SwiftUI)
// This view is unchanged, but now its dependencies are fixed.
struct ScanView: View {
    
    // Manages the camera logic
    @StateObject private var viewModel = CameraViewModel()
    
    // A closure to pass the captured image back to the previous view
    var onImageCaptured: (UIImage) -> Void
    
    // For dismissing the view
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            
            // The main content depends on camera permission status
            switch viewModel.permissionStatus {
            case .authorized:
                // Show the camera preview
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()
                
            case .notDetermined:
                // Show button to request permission
                VStack {
                    Text("Camera access is required to scan receipts.")
                    Button("Request Permission", action: viewModel.requestPermission)
                }
                .padding()
                
            case .denied, .restricted:
                // Show error and link to settings
                VStack {
                    Text("Camera access was denied.")
                    Text("Please enable it in Settings to scan receipts.")
                    Button("Open Settings") {
                        // Opens the app's settings in the Settings app
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .padding()
                
            default:
                ProgressView()
            }
            
            // --- UI Overlays (Buttons) ---
            
            // Shutter Button
            if viewModel.permissionStatus == .authorized {
                VStack {
                    Spacer()
                    Button(action: {
                        viewModel.capturePhoto()
                    }) {
                        // A simple shutter button design
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .padding(.bottom, 40)
                    .disabled(viewModel.isCameraBusy) // Disable while processing
                }
            }
            
            // Close Button (Top-left)
            VStack {
                HStack {
                    Button(action: {
                        dismiss() // Close the camera view
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
            
        }
        .onAppear {
            viewModel.checkPermission() // Check permission as soon as the view appears
        }
        .onReceive(viewModel.$capturedImage) { image in
            // When an image is captured, call the closure to pass it back
            if let img = image {
                onImageCaptured(img)
                dismiss() // Close the view after capture
            }
        }
    }
}

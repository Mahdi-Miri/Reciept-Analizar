//
//  ScanView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 10/11/25.
//
// FILE: ScanView.swift (REPLACE THE ENTIRE FILE)

import SwiftUI
import AVFoundation
import Combine // Required for ObservableObject

// MARK: - Camera View Model
class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    @Published var capturedImage: UIImage?
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var isCameraBusy = false
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionStatus = .authorized
            setupSession()
        case .notDetermined:
            permissionStatus = .notDetermined
        case .denied, .restricted:
            permissionStatus = .denied
        default:
            break
        }
    }
    
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
    
    private func setupSession() {
        guard permissionStatus == .authorized else { return }
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            session.commitConfiguration()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        } catch {
            print("Error setting up camera session: \(error.localizedDescription)")
        }
    }
    
    func capturePhoto() {
        guard !isCameraBusy else { return }
        isCameraBusy = true
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            isCameraBusy = false
            return
        }
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            isCameraBusy = false
            return
        }
        DispatchQueue.main.async {
            self.capturedImage = image
            self.isCameraBusy = false
        }
    }
}

// MARK: - Camera Preview (UIViewRepresentable)
struct CameraPreview: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let previewView = CameraPreviewView(session: session)
        return previewView
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) { }
    
    class CameraPreviewView: UIView {
        private var previewLayer: AVCaptureVideoPreviewLayer?
        
        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            if previewLayer.connection?.isVideoRotationAngleSupported(90) == true {
                 previewLayer.connection?.videoRotationAngle = 90
            }
            self.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = self.bounds
        }
    }
}


// MARK: - Main Scan View (SwiftUI)
struct ScanView: View {
    
    // --- 🔴 YOUR PROBLEM IS LIKELY HERE 🔴 ---
    // This line MUST be inside the struct ScanView, right at the top.
    @StateObject private var viewModel = CameraViewModel()
    
    var onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            
            // The main content depends on camera permission status
            switch viewModel.permissionStatus {
            case .authorized:
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()
            case .notDetermined:
                VStack {
                    Text("Camera access is required to scan receipts.")
                    Button("Request Permission", action: viewModel.requestPermission)
                }
                .padding()
            case .denied, .restricted:
                VStack {
                    Text("Camera access was denied.")
                    Text("Please enable it in Settings to scan receipts.")
                    Button("Open Settings") {
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
            if viewModel.permissionStatus == .authorized {
                VStack {
                    Spacer()
                    Button(action: {
                        viewModel.capturePhoto()
                    }) {
                        ZStack {
                            Circle().fill(Color.white).frame(width: 70, height: 70)
                            Circle().stroke(Color.white, lineWidth: 4).frame(width: 80, height: 80)
                        }
                    }
                    .padding(.bottom, 40)
                    .disabled(viewModel.isCameraBusy)
                }
            }
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
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
        } // --- End of ZStack ---
        
        // --- Modifiers are applied to the ZStack ---
        .onAppear {
            viewModel.checkPermission() // Now 'viewModel' is in scope
        }
        .onDisappear {
            // --- THIS IS THE FIX FOR THE LAG ---
            // Stop the camera session when the view is closed
            viewModel.session.stopRunning() // 'viewModel' is in scope
        }
        .onReceive(viewModel.$capturedImage) { image in // 'viewModel' is in scope
            if let img = image {
                onImageCaptured(img)
                dismiss()
            }
        }
        
    } // --- End of body ---
} // --- End of struct ScanView ---

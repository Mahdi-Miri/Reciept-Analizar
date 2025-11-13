//
//  ScannerView.swift
//  ScontrinoSmartApp
//
//  Created by Mahdi Miri on 13/11/25.
//  Camera view for scanning receipts
//

import SwiftUI
import AVFoundation
import Combine   

struct ScannerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraManager = CameraManager()
    @State private var showingImagePicker = false
    @State private var isProcessing = false
    @State private var showingResult = false
    @State private var scannedReceipt: ScannedReceipt?
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                topBar
                Spacer()
                captureGuide
                Spacer()
                bottomControls
            }
            
            // Processing Overlay
            if isProcessing {
                processingOverlay
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(onImageSelected: processImage)
        }
        .sheet(item: $scannedReceipt) { receipt in
            ReceiptResultView(receipt: receipt) {
                appState.addReceipt(receipt)
                scannedReceipt = nil
                dismiss()
            }
        }
        .alert("Scan Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button(action: { cameraManager.toggleFlash() }) {
                Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    // MARK: - Capture Guide
    private var captureGuide: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white, lineWidth: 3)
            .frame(width: 300, height: 400)
            .overlay(
                VStack {
                    Spacer()
                    Text("Align receipt within frame")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, -40)
                }
            )
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 40) {
            // Gallery button
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            // Capture button
            Button(action: capturePhoto) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 85, height: 85)
                }
            }
            .disabled(isProcessing)
            
            // Empty spacer for symmetry
            Color.clear
                .frame(width: 60, height: 60)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Processing Overlay
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Processing receipt...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Actions
    private func capturePhoto() {
        cameraManager.capturePhoto { result in
            switch result {
            case .success(let cgImage):
                processImage(cgImage)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func processImage(_ cgImage: CGImage) {
        isProcessing = true
        
        let ocrService = OCRService()
        ocrService.recognizeText(from: [cgImage]) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success(let receipt):
                    scannedReceipt = receipt
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var isFlashOn = false
    var captureSession: AVCaptureSession?   // ✅ made public (was private)
    private var photoOutput: AVCapturePhotoOutput?
    private var completion: ((Result<CGImage, Error>) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        photoOutput = AVCapturePhotoOutput()
        
        guard let captureSession = captureSession,
              let photoOutput = photoOutput else { return }
        
        captureSession.beginConfiguration()
        
        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func capturePhoto(completion: @escaping (Result<CGImage, Error>) -> Void) {
        self.completion = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion?(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            completion?(.failure(NSError(domain: "CameraManager", code: 1)))
            return
        }
        
        completion?(.success(cgImage))
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        guard let captureSession = cameraManager.captureSession else { return view }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill  // ✅ explicit
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (CGImage) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let cgImage = image.cgImage {
                parent.onImageSelected(cgImage)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Receipt Result View
struct ReceiptResultView: View {
    let receipt: ScannedReceipt
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top)
                    
                    Text("Receipt Scanned!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(receipt.items.count) items found")
                            .font(.headline)
                        
                        ForEach(receipt.items.prefix(5)) { item in
                            HStack {
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "€%.2f", item.price))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if receipt.items.count > 5 {
                            Text("+ \(receipt.items.count - 5) more items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "€%.2f", receipt.total))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Button(action: onSave) {
                        Text("Save Receipt")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScannerView()
        .environmentObject(AppState())
}

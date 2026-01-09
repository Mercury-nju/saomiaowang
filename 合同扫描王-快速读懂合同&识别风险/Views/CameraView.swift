//
//  CameraView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI
import UIKit
import AVFoundation
import UniformTypeIdentifiers

// MARK: - 手动拍照相机
struct CameraView: View {
    @Binding var images: [UIImage]
    @Binding var isPresented: Bool
    @StateObject private var camera = CameraModel()
    @State private var capturedImages: [UIImage] = []
    
    var body: some View {
        ZStack {
            // 相机预览
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            VStack {
                // 顶部栏
                HStack {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !capturedImages.isEmpty {
                        Text("已拍 \(capturedImages.count) 页")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(16)
                    }
                    
                    Spacer()
                    
                    if !capturedImages.isEmpty {
                        Button("完成") {
                            images = capturedImages
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    } else {
                        Color.clear.frame(width: 44)
                    }
                }
                .padding()
                .background(
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                )
                
                Spacer()
                
                // 提示文字
                Text("将合同对准框内，点击拍摄")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                
                Spacer()
                
                // 底部控制栏
                HStack(spacing: 60) {
                    // 已拍照片预览
                    if let lastImage = capturedImages.last {
                        Image(uiImage: lastImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 60)
                    }
                    
                    // 拍摄按钮
                    Button {
                        camera.capturePhoto { image in
                            if let image = image {
                                capturedImages.append(image)
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    
                    // 删除最后一张
                    Button {
                        if !capturedImages.isEmpty {
                            capturedImages.removeLast()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(capturedImages.isEmpty ? .gray : .white)
                            .frame(width: 60, height: 60)
                    }
                    .disabled(capturedImages.isEmpty)
                }
                .padding(.bottom, 30)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                )
            }
        }
        .onAppear {
            camera.checkPermission()
        }
    }
}

// MARK: - 相机模型
class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer?
    
    private var photoCompletion: ((UIImage?) -> Void)?
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }
    
    func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            
            // 输入
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            // 输出
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoCompletion?(nil)
            return
        }
        
        DispatchQueue.main.async {
            self.photoCompletion?(image)
        }
    }
}

// MARK: - 相机预览
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        DispatchQueue.main.async {
            let preview = AVCaptureVideoPreviewLayer(session: camera.session)
            preview.frame = view.bounds
            preview.videoGravity = .resizeAspectFill
            view.layer.addSublayer(preview)
            camera.preview = preview
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            camera.preview?.frame = uiView.bounds
        }
    }
}

// MARK: - 相册选择器
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages = [image]
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 文档选择器
struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf, UTType.image])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.dismiss()
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                parent.dismiss()
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            if url.pathExtension.lowercased() == "pdf" {
                if let images = extractImagesFromPDF(url: url) {
                    parent.selectedImages = images
                }
            } else {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    parent.selectedImages = [image]
                }
            }
            
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
        
        private func extractImagesFromPDF(url: URL) -> [UIImage]? {
            guard let document = CGPDFDocument(url as CFURL) else { return nil }
            
            var images: [UIImage] = []
            let pageCount = document.numberOfPages
            
            for i in 1...pageCount {
                guard let page = document.page(at: i) else { continue }
                
                let pageRect = page.getBoxRect(.mediaBox)
                let scale: CGFloat = 2.0
                let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
                
                let renderer = UIGraphicsImageRenderer(size: scaledSize)
                let image = renderer.image { context in
                    UIColor.white.setFill()
                    context.fill(CGRect(origin: .zero, size: scaledSize))
                    
                    context.cgContext.translateBy(x: 0, y: scaledSize.height)
                    context.cgContext.scaleBy(x: scale, y: -scale)
                    context.cgContext.drawPDFPage(page)
                }
                
                images.append(image)
            }
            
            return images.isEmpty ? nil : images
        }
    }
}

//
//  CameraView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - 多页拍摄管理视图
struct CameraView: View {
    @Binding var images: [UIImage]
    @Binding var isPresented: Bool
    
    @State private var capturedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var pickerKey = UUID()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if capturedImages.isEmpty {
                    emptyState
                } else {
                    photoList
                }
                
                bottomBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("拍摄合同")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !capturedImages.isEmpty {
                        Button("完成") {
                            images = capturedImages
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .fullScreenCover(isPresented: $showImagePicker) {
                SingleImagePicker(onComplete: handleImagePicked)
                    .id(pickerKey)
                    .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "camera")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("点击下方按钮开始拍摄")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("支持拍摄多页合同")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
            
            Spacer()
        }
    }
    
    // MARK: - 照片列表
    private var photoList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                    photoRow(index: index, image: image)
                }
            }
            .padding()
        }
    }
    
    private func photoRow(index: Int, image: UIImage) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 100)
                .clipped()
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("第 \(index + 1) 页")
                    .font(.headline)
                Text("点击右侧删除")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    capturedImages.remove(at: index)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    // MARK: - 底部操作栏
    private var bottomBar: some View {
        VStack(spacing: 12) {
            Divider()
            
            Button {
                openCamera()
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(capturedImages.isEmpty ? "开始拍摄" : "继续拍摄第 \(capturedImages.count + 1) 页")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private func openCamera() {
        pickerKey = UUID()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showImagePicker = true
        }
    }
    
    private func handleImagePicked(_ image: UIImage?) {
        showImagePicker = false
        if let image = image {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                capturedImages.append(image)
            }
        }
    }
}

// MARK: - 单张拍照
struct SingleImagePicker: UIViewControllerRepresentable {
    let onComplete: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onComplete: (UIImage?) -> Void
        
        init(onComplete: @escaping (UIImage?) -> Void) {
            self.onComplete = onComplete
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            onComplete(image)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onComplete(nil)
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

//
//  CameraView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - 相机拍照（手动控制）
struct CameraView: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        // 包装在导航控制器中以便添加多页拍摄功能
        let nav = UINavigationController(rootViewController: picker)
        nav.isNavigationBarHidden = true
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        var capturedImages: [UIImage] = []
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                capturedImages.append(image)
                
                // 显示继续拍摄或完成的选项
                let alert = UIAlertController(title: "已拍摄 \(capturedImages.count) 页", message: "是否继续拍摄下一页？", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "继续拍摄", style: .default) { _ in
                    // 重新打开相机
                })
                
                alert.addAction(UIAlertAction(title: "完成", style: .cancel) { [weak self] _ in
                    guard let self = self else { return }
                    self.parent.images = self.capturedImages
                    self.parent.isPresented = false
                })
                
                picker.present(alert, animated: true)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            if capturedImages.isEmpty {
                parent.isPresented = false
            } else {
                // 如果已经拍了照片，询问是否保存
                let alert = UIAlertController(title: "已拍摄 \(capturedImages.count) 页", message: "是否使用已拍摄的照片？", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "使用", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    self.parent.images = self.capturedImages
                    self.parent.isPresented = false
                })
                
                alert.addAction(UIAlertAction(title: "放弃", style: .destructive) { [weak self] _ in
                    self?.parent.isPresented = false
                })
                
                picker.present(alert, animated: true)
            }
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

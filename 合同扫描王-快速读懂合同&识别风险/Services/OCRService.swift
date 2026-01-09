//
//  OCRService.swift
//  合同扫描王-快速读懂合同&识别风险
//

import Foundation
import Vision
import UIKit

final class OCRService: Sendable {
    static let shared = OCRService()
    
    private init() {}
    
    /// 识别图片中的文字
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // 配置识别参数
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
    
    /// 批量识别多张图片
    func recognizeText(from images: [UIImage]) async throws -> String {
        var allText: [String] = []
        
        for (index, image) in images.enumerated() {
            let text = try await recognizeText(from: image)
            allText.append("【第\(index + 1)页】\n\(text)")
        }
        
        return allText.joined(separator: "\n\n")
    }
}

// MARK: - OCR错误类型
enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片格式"
        case .noTextFound:
            return "未能识别到文字内容"
        case .recognitionFailed(let message):
            return "文字识别失败: \(message)"
        }
    }
}

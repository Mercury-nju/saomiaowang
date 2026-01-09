//
//  ExportService.swift
//  合同扫描王-快速读懂合同&识别风险
//

import Foundation
import UIKit
import PDFKit

class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - 导出选项
    enum ExportScope {
        case full           // 全文
        case keyTerms       // 仅关键条款
        case risks          // 仅风险条款
        case summary        // 仅摘要
    }
    
    enum ExportFormat {
        case pdf
        case text
    }
    
    // MARK: - 生成PDF
    func generatePDF(for contract: Contract, scope: ExportScope = .full) -> Data? {
        let pageWidth: CGFloat = 595.2  // A4
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2
        
        let pdfMetaData = [
            kCGPDFContextCreator: "合同扫描王",
            kCGPDFContextAuthor: "Contract Scanner",
            kCGPDFContextTitle: contract.title
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            
            // 标题
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 40)
            contract.title.draw(in: titleRect, withAttributes: titleAttributes)
            yPosition += 50
            
            // 分析时间
            if let analysis = contract.analysisResult {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
                let dateStr = "分析时间：\(dateFormatter.string(from: contract.updatedAt))"
                
                let dateFont = UIFont.systemFont(ofSize: 12)
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: dateFont,
                    .foregroundColor: UIColor.gray
                ]
                dateStr.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttributes)
                yPosition += 30
                
                // 合同类型
                let typeStr = "合同类型：\(analysis.contractType)"
                typeStr.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttributes)
                yPosition += 30
                
                // 分隔线
                yPosition = drawSeparator(context: context, y: yPosition, width: contentWidth, margin: margin)
                
                switch scope {
                case .full:
                    yPosition = drawSummary(analysis: analysis, context: context, y: yPosition, width: contentWidth, margin: margin, pageHeight: pageHeight)
                    yPosition = drawKeyTerms(analysis: analysis, context: context, y: yPosition, width: contentWidth, margin: margin, pageHeight: pageHeight)
                    yPosition = drawRisks(analysis: analysis, context: context, y: yPosition, width: contentWidth, margin: margin, pageHeight: pageHeight)
                    _ = drawSimplifiedExplanation(analysis: analysis, context: context, y: yPosition, width: contentWidth, margin: margin, pageHeight: pageHeight)
                    
                case .keyTerms:
                    _ = drawKeyTerms(analysis: analysis, context: context, y: yPosition, width: contentWidth, margin: margin, pageHeight: pageHeight)
                    
                case .risks:
                    _ = drawRisks(analysis: analysis, context: context, y: yPosition, width: contentWidth, margin: margin, pageHeight: pageHeight)
                    
                case .summary:
                    _ = drawSummary(analysis: analysis, context: context, y: yPosition, width: contentWidth, margin: margin, pageHeight: pageHeight)
                }
            }
        }
        
        return data
    }
    
    // MARK: - 生成纯文本
    func generateText(for contract: Contract, scope: ExportScope = .full) -> String {
        var text = """
        ═══════════════════════════════════════
        \(contract.title)
        ═══════════════════════════════════════
        
        """
        
        guard let analysis = contract.analysisResult else {
            return text + "暂无分析结果"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        text += "分析时间：\(dateFormatter.string(from: contract.updatedAt))\n"
        text += "合同类型：\(analysis.contractType)\n\n"
        
        switch scope {
        case .full:
            text += generateSummaryText(analysis)
            text += generateKeyTermsText(analysis)
            text += generateRisksText(analysis)
            text += generateSimplifiedText(analysis)
            
        case .keyTerms:
            text += generateKeyTermsText(analysis)
            
        case .risks:
            text += generateRisksText(analysis)
            
        case .summary:
            text += generateSummaryText(analysis)
        }
        
        return text
    }
    
    // MARK: - 私有方法 - PDF绘制
    private func drawSeparator(context: UIGraphicsPDFRendererContext, y: CGFloat, width: CGFloat, margin: CGFloat) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: margin + width, y: y))
        UIColor.lightGray.setStroke()
        path.stroke()
        return y + 20
    }
    
    private func drawSectionTitle(_ title: String, context: UIGraphicsPDFRendererContext, y: CGFloat, margin: CGFloat) -> CGFloat {
        let font = UIFont.boldSystemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        ]
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: attributes)
        return y + 30
    }
    
    private func drawText(_ text: String, context: UIGraphicsPDFRendererContext, y: CGFloat, width: CGFloat, margin: CGFloat, pageHeight: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.darkGray
        ]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        
        var allAttributes = attributes
        allAttributes[.paragraphStyle] = paragraphStyle
        
        let attributedString = NSAttributedString(string: text, attributes: allAttributes)
        let textRect = CGRect(x: margin, y: y, width: width, height: pageHeight - y - 50)
        attributedString.draw(in: textRect)
        
        let boundingRect = attributedString.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
        
        return y + boundingRect.height + 20
    }
    
    private func drawSummary(analysis: ContractAnalysis, context: UIGraphicsPDFRendererContext, y: CGFloat, width: CGFloat, margin: CGFloat, pageHeight: CGFloat) -> CGFloat {
        var currentY = drawSectionTitle("📋 合同摘要", context: context, y: y, margin: margin)
        currentY = drawText(analysis.summary, context: context, y: currentY, width: width, margin: margin, pageHeight: pageHeight)
        return currentY
    }
    
    private func drawKeyTerms(analysis: ContractAnalysis, context: UIGraphicsPDFRendererContext, y: CGFloat, width: CGFloat, margin: CGFloat, pageHeight: CGFloat) -> CGFloat {
        var currentY = drawSectionTitle("📌 关键条款", context: context, y: y, margin: margin)
        
        for term in analysis.keyTerms {
            let termText = "【\(term.category.rawValue)】\(term.title)\n\(term.explanation)"
            currentY = drawText(termText, context: context, y: currentY, width: width, margin: margin, pageHeight: pageHeight)
        }
        
        return currentY
    }
    
    private func drawRisks(analysis: ContractAnalysis, context: UIGraphicsPDFRendererContext, y: CGFloat, width: CGFloat, margin: CGFloat, pageHeight: CGFloat) -> CGFloat {
        var currentY = drawSectionTitle("⚠️ 风险提示", context: context, y: y, margin: margin)
        
        for risk in analysis.riskItems {
            let riskText = "【\(risk.level.rawValue)】\(risk.title)\n\(risk.description)\n建议：\(risk.suggestion)"
            currentY = drawText(riskText, context: context, y: currentY, width: width, margin: margin, pageHeight: pageHeight)
        }
        
        return currentY
    }
    
    private func drawSimplifiedExplanation(analysis: ContractAnalysis, context: UIGraphicsPDFRendererContext, y: CGFloat, width: CGFloat, margin: CGFloat, pageHeight: CGFloat) -> CGFloat {
        var currentY = drawSectionTitle("💡 简明解读", context: context, y: y, margin: margin)
        currentY = drawText(analysis.simplifiedExplanation, context: context, y: currentY, width: width, margin: margin, pageHeight: pageHeight)
        return currentY
    }
    
    // MARK: - 私有方法 - 文本生成
    private func generateSummaryText(_ analysis: ContractAnalysis) -> String {
        return """
        ───────────────────────────────────────
        📋 合同摘要
        ───────────────────────────────────────
        \(analysis.summary)
        
        
        """
    }
    
    private func generateKeyTermsText(_ analysis: ContractAnalysis) -> String {
        var text = """
        ───────────────────────────────────────
        📌 关键条款
        ───────────────────────────────────────
        
        """
        
        for (index, term) in analysis.keyTerms.enumerated() {
            text += """
            \(index + 1). 【\(term.category.rawValue)】\(term.title)
               重要程度：\(term.importance.rawValue)
               原文：\(term.originalText)
               解释：\(term.explanation)
            
            """
        }
        
        return text + "\n"
    }
    
    private func generateRisksText(_ analysis: ContractAnalysis) -> String {
        var text = """
        ───────────────────────────────────────
        ⚠️ 风险提示
        ───────────────────────────────────────
        
        """
        
        for (index, risk) in analysis.riskItems.enumerated() {
            text += """
            \(index + 1). 【\(risk.level.rawValue)】\(risk.title)
               描述：\(risk.description)
               建议：\(risk.suggestion)
               相关条款：\(risk.relatedClause)
            
            """
        }
        
        return text + "\n"
    }
    
    private func generateSimplifiedText(_ analysis: ContractAnalysis) -> String {
        return """
        ───────────────────────────────────────
        💡 简明解读
        ───────────────────────────────────────
        \(analysis.simplifiedExplanation)
        
        """
    }
}

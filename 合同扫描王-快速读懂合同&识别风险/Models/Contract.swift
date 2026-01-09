//
//  Contract.swift
//  合同扫描王-快速读懂合同&识别风险
//

import Foundation

// MARK: - 合同模型
struct Contract: Identifiable, Codable {
    let id: UUID
    var title: String
    var originalText: String
    var createdAt: Date
    var updatedAt: Date
    var imageData: [Data]?
    var analysisResult: ContractAnalysis?
    var status: ContractStatus
    
    init(id: UUID = UUID(), title: String, originalText: String = "", imageData: [Data]? = nil) {
        self.id = id
        self.title = title
        self.originalText = originalText
        self.createdAt = Date()
        self.updatedAt = Date()
        self.imageData = imageData
        self.analysisResult = nil
        self.status = .pending
    }
}

// MARK: - 合同状态
enum ContractStatus: String, Codable {
    case pending = "待分析"
    case analyzing = "分析中"
    case completed = "已完成"
    case failed = "分析失败"
}

// MARK: - 合同分析结果
struct ContractAnalysis: Codable {
    var summary: String                    // 合同摘要
    var keyTerms: [KeyTerm]               // 关键条款
    var riskItems: [RiskItem]             // 风险项
    var simplifiedExplanation: String     // 简明解读
    var contractType: String              // 合同类型
    var parties: [String]                 // 合同各方
    var effectiveDate: String?            // 生效日期
    var expirationDate: String?           // 到期日期
}

// MARK: - 关键条款
struct KeyTerm: Identifiable, Codable {
    let id: UUID
    var category: TermCategory
    var title: String
    var originalText: String
    var explanation: String
    var importance: Importance
    
    init(id: UUID = UUID(), category: TermCategory, title: String, originalText: String, explanation: String, importance: Importance) {
        self.id = id
        self.category = category
        self.title = title
        self.originalText = originalText
        self.explanation = explanation
        self.importance = importance
    }
}

// MARK: - 条款类别
enum TermCategory: String, Codable, CaseIterable {
    case payment = "付款条款"
    case liability = "违约责任"
    case termination = "解除条件"
    case duration = "合同期限"
    case confidentiality = "保密条款"
    case dispute = "争议解决"
    case other = "其他条款"
    
    var icon: String {
        switch self {
        case .payment: return "yensign.circle"
        case .liability: return "exclamationmark.triangle"
        case .termination: return "xmark.circle"
        case .duration: return "calendar"
        case .confidentiality: return "lock.shield"
        case .dispute: return "scale.3d"
        case .other: return "doc.text"
        }
    }
}

// MARK: - 重要程度
enum Importance: String, Codable {
    case high = "高"
    case medium = "中"
    case low = "低"
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "green"
        }
    }
}

// MARK: - 风险项
struct RiskItem: Identifiable, Codable {
    let id: UUID
    var level: RiskLevel
    var title: String
    var description: String
    var suggestion: String
    var relatedClause: String
    
    init(id: UUID = UUID(), level: RiskLevel, title: String, description: String, suggestion: String, relatedClause: String) {
        self.id = id
        self.level = level
        self.title = title
        self.description = description
        self.suggestion = suggestion
        self.relatedClause = relatedClause
    }
}

// MARK: - 风险等级
enum RiskLevel: String, Codable, CaseIterable {
    case high = "高风险"
    case medium = "中风险"
    case low = "低风险"
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "yellow"
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "exclamationmark.octagon.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .low: return "info.circle.fill"
        }
    }
}

// MARK: - 问答记录
struct QARecord: Identifiable, Codable {
    let id: UUID
    var question: String
    var answer: String
    var timestamp: Date
    var contractId: UUID
    
    init(id: UUID = UUID(), question: String, answer: String, contractId: UUID) {
        self.id = id
        self.question = question
        self.answer = answer
        self.timestamp = Date()
        self.contractId = contractId
    }
}

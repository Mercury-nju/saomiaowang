//
//  AIService.swift
//  合同扫描王-快速读懂合同&识别风险
//

import Foundation

class AIService {
    static let shared = AIService()
    
    private let apiKey = "sk-9bf19547ddbd4be1a87a7a43cf251097"
    private let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    
    private init() {}
    
    // MARK: - 合同分析
    func analyzeContract(_ text: String) async throws -> ContractAnalysis {
        let prompt = """
        你是一位专业的合同分析师。请分析以下合同内容，并以JSON格式返回分析结果。

        合同内容：
        \(text)

        请返回以下JSON格式的分析结果（确保是有效的JSON）：
        {
            "summary": "合同整体摘要（100-200字）",
            "contractType": "合同类型（如：租赁合同、劳动合同、买卖合同等）",
            "parties": ["甲方名称", "乙方名称"],
            "effectiveDate": "生效日期（如有）",
            "expirationDate": "到期日期（如有）",
            "keyTerms": [
                {
                    "category": "payment/liability/termination/duration/confidentiality/dispute/other",
                    "title": "条款标题",
                    "originalText": "原文内容",
                    "explanation": "通俗易懂的解释",
                    "importance": "high/medium/low"
                }
            ],
            "riskItems": [
                {
                    "level": "high/medium/low",
                    "title": "风险标题",
                    "description": "风险描述",
                    "suggestion": "应对建议",
                    "relatedClause": "相关条款原文"
                }
            ],
            "simplifiedExplanation": "用通俗易懂的语言解释整份合同的主要内容和注意事项（300-500字）"
        }

        注意：
        1. 重点关注付款条款、违约责任、解除条件、合同期限等关键内容
        2. 识别可能对签约方不利的条款作为风险项
        3. 解释要通俗易懂，适合非法律专业人士理解
        4. 只返回JSON，不要有其他内容
        """
        
        let response = try await sendRequest(prompt: prompt)
        return try parseAnalysisResponse(response)
    }
    
    // MARK: - 问答功能
    func askQuestion(question: String, contractText: String, context: [QARecord] = []) async throws -> String {
        var contextStr = ""
        if !context.isEmpty {
            contextStr = "之前的问答记录：\n" + context.suffix(5).map { "问：\($0.question)\n答：\($0.answer)" }.joined(separator: "\n\n")
        }
        
        let prompt = """
        你是一位专业的合同法律顾问。用户正在阅读一份合同，并有以下问题需要解答。

        合同内容：
        \(contractText)

        \(contextStr)

        用户问题：\(question)

        请用通俗易懂的语言回答用户的问题，如果问题涉及法律风险，请给出相应的建议。回答要简洁明了，控制在300字以内。
        """
        
        return try await sendRequest(prompt: prompt)
    }
    
    // MARK: - 合同对比
    func compareContracts(contract1: String, contract2: String) async throws -> String {
        let prompt = """
        你是一位专业的合同分析师。请对比以下两份合同的异同。

        【合同一】
        \(contract1)

        【合同二】
        \(contract2)

        请从以下几个方面进行对比分析：
        1. 合同类型和主体
        2. 主要条款差异
        3. 权利义务差异
        4. 风险条款差异
        5. 总结建议

        请用清晰的结构和通俗的语言进行说明。
        """
        
        return try await sendRequest(prompt: prompt)
    }
    
    // MARK: - 条款深度解释
    func explainClause(_ clause: String, contractContext: String) async throws -> String {
        let prompt = """
        你是一位专业的合同法律顾问。用户想要深入了解以下合同条款。

        合同背景：
        \(contractContext.prefix(2000))

        需要解释的条款：
        \(clause)

        请提供：
        1. 条款的通俗解释
        2. 该条款的法律含义
        3. 对签约方的影响
        4. 需要注意的风险点
        5. 相关建议

        请用通俗易懂的语言回答，适合非法律专业人士理解。
        """
        
        return try await sendRequest(prompt: prompt)
    }
    
    // MARK: - 网络请求
    private func sendRequest(prompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120
        
        let requestBody: [String: Any] = [
            "model": "qwen-plus",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 4000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw AIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError
        }
        
        return content
    }
    
    // MARK: - 解析分析结果
    private func parseAnalysisResponse(_ response: String) throws -> ContractAnalysis {
        // 提取JSON部分
        var jsonString = response
        if let startIndex = response.firstIndex(of: "{"),
           let endIndex = response.lastIndex(of: "}") {
            jsonString = String(response[startIndex...endIndex])
        }
        
        guard let data = jsonString.data(using: .utf8) else {
            throw AIError.parseError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw AIError.parseError
        }
        
        // 解析关键条款
        var keyTerms: [KeyTerm] = []
        if let termsArray = json["keyTerms"] as? [[String: Any]] {
            for term in termsArray {
                let categoryStr = term["category"] as? String ?? "other"
                let category = TermCategory(rawValue: categoryStr) ?? .other
                let importanceStr = term["importance"] as? String ?? "medium"
                let importance = Importance(rawValue: importanceStr) ?? .medium
                
                keyTerms.append(KeyTerm(
                    category: category,
                    title: term["title"] as? String ?? "",
                    originalText: term["originalText"] as? String ?? "",
                    explanation: term["explanation"] as? String ?? "",
                    importance: importance
                ))
            }
        }
        
        // 解析风险项
        var riskItems: [RiskItem] = []
        if let risksArray = json["riskItems"] as? [[String: Any]] {
            for risk in risksArray {
                let levelStr = risk["level"] as? String ?? "low"
                let level: RiskLevel
                switch levelStr {
                case "high": level = .high
                case "medium": level = .medium
                default: level = .low
                }
                
                riskItems.append(RiskItem(
                    level: level,
                    title: risk["title"] as? String ?? "",
                    description: risk["description"] as? String ?? "",
                    suggestion: risk["suggestion"] as? String ?? "",
                    relatedClause: risk["relatedClause"] as? String ?? ""
                ))
            }
        }
        
        return ContractAnalysis(
            summary: json["summary"] as? String ?? "暂无摘要",
            keyTerms: keyTerms,
            riskItems: riskItems,
            simplifiedExplanation: json["simplifiedExplanation"] as? String ?? "暂无解读",
            contractType: json["contractType"] as? String ?? "未知类型",
            parties: json["parties"] as? [String] ?? [],
            effectiveDate: json["effectiveDate"] as? String,
            expirationDate: json["expirationDate"] as? String
        )
    }
}

// MARK: - AI错误类型
enum AIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .invalidResponse:
            return "服务器响应无效"
        case .apiError(let code, let message):
            return "API错误(\(code)): \(message)"
        case .parseError:
            return "解析响应数据失败"
        }
    }
}

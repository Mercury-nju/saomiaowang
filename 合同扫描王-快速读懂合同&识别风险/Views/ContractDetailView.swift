//
//  ContractDetailView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI

struct ContractDetailView: View {
    @Environment(ContractStore.self) var contractStore
    @State var contract: Contract
    @State private var selectedTab = 0
    @State private var showExportSheet = false
    @State private var showQAView = false
    @State private var isAnalyzing = false
    @State private var showShareSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标签页选择器
            Picker("", selection: $selectedTab) {
                Text("摘要").tag(0)
                Text("关键条款").tag(1)
                Text("风险提示").tag(2)
                Text("原文").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 内容区域
            TabView(selection: $selectedTab) {
                summaryView.tag(0)
                keyTermsView.tag(1)
                risksView.tag(2)
                originalTextView.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(contract.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showQAView = true
                    } label: {
                        Label("AI问答", systemImage: "bubble.left.and.bubble.right")
                    }
                    
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("导出报告", systemImage: "square.and.arrow.up")
                    }
                    
                    if contract.status != .completed {
                        Button {
                            reanalyze()
                        } label: {
                            Label("重新分析", systemImage: "arrow.clockwise")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showQAView) {
            QAView(contract: contract)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportOptionsView(contract: contract)
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportData {
                ShareSheet(items: [data])
            }
        }
        .overlay {
            if isAnalyzing {
                AnalyzingOverlay()
            }
        }
        .onAppear {
            if contract.status == .analyzing || contract.status == .pending {
                analyzeContract()
            }
        }
    }
    
    // MARK: - 摘要视图
    private var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let analysis = contract.analysisResult {
                    // 合同基本信息
                    InfoCard(title: "合同信息") {
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(label: "合同类型", value: analysis.contractType)
                            
                            if !analysis.parties.isEmpty {
                                InfoRow(label: "合同各方", value: analysis.parties.joined(separator: "、"))
                            }
                            
                            if let effectiveDate = analysis.effectiveDate {
                                InfoRow(label: "生效日期", value: effectiveDate)
                            }
                            
                            if let expirationDate = analysis.expirationDate {
                                InfoRow(label: "到期日期", value: expirationDate)
                            }
                        }
                    }
                    
                    // 摘要
                    InfoCard(title: "合同摘要") {
                        Text(analysis.summary)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // 简明解读
                    InfoCard(title: "简明解读") {
                        Text(analysis.simplifiedExplanation)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // 风险概览
                    riskOverviewCard(analysis: analysis)
                    
                } else {
                    noAnalysisView
                }
            }
            .padding()
        }
    }
    
    // MARK: - 关键条款视图
    private var keyTermsView: some View {
        ScrollView {
            if let analysis = contract.analysisResult {
                LazyVStack(spacing: 16) {
                    ForEach(analysis.keyTerms) { term in
                        KeyTermCard(term: term, contractText: contract.originalText)
                    }
                }
                .padding()
            } else {
                noAnalysisView
            }
        }
    }
    
    // MARK: - 风险提示视图
    private var risksView: some View {
        ScrollView {
            if let analysis = contract.analysisResult {
                if analysis.riskItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)
                        
                        Text("未发现明显风险")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("该合同条款相对规范，未发现明显的风险条款")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(analysis.riskItems) { risk in
                            RiskCard(risk: risk)
                        }
                    }
                    .padding()
                }
            } else {
                noAnalysisView
            }
        }
    }
    
    // MARK: - 原文视图
    private var originalTextView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("合同原文")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = contract.originalText
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                            .font(.subheadline)
                    }
                }
                
                Text(contract.originalText)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding()
        }
    }
    
    // MARK: - 无分析结果视图
    private var noAnalysisView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("暂无分析结果")
                .font(.title3)
                .fontWeight(.medium)
            
            Button("开始分析") {
                analyzeContract()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 60)
    }
    
    // MARK: - 风险概览卡片
    private func riskOverviewCard(analysis: ContractAnalysis) -> some View {
        let highRisks = analysis.riskItems.filter { $0.level == .high }.count
        let mediumRisks = analysis.riskItems.filter { $0.level == .medium }.count
        let lowRisks = analysis.riskItems.filter { $0.level == .low }.count
        
        return InfoCard(title: "风险概览") {
            HStack(spacing: 20) {
                RiskBadge(count: highRisks, level: .high)
                RiskBadge(count: mediumRisks, level: .medium)
                RiskBadge(count: lowRisks, level: .low)
            }
        }
    }
    
    // MARK: - 分析合同
    private func analyzeContract() {
        guard !contract.originalText.isEmpty else { return }
        
        isAnalyzing = true
        
        Task {
            do {
                let analysis = try await AIService.shared.analyzeContract(contract.originalText)
                
                await MainActor.run {
                    contract.analysisResult = analysis
                    contract.status = .completed
                    contractStore.updateContract(contract)
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    contract.status = .failed
                    contractStore.updateContract(contract)
                    isAnalyzing = false
                    print("分析失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func reanalyze() {
        contract.status = .analyzing
        contract.analysisResult = nil
        contractStore.updateContract(contract)
        analyzeContract()
    }
}

// MARK: - 信息卡片
struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 信息行
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 风险徽章
struct RiskBadge: View {
    let count: Int
    let level: RiskLevel
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(levelColor)
            
            Text(level.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var levelColor: Color {
        switch level {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

// MARK: - 关键条款卡片
struct KeyTermCard: View {
    let term: KeyTerm
    let contractText: String
    @State private var isExpanded = false
    @State private var showExplanation = false
    @State private var detailedExplanation: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack {
                Image(systemName: term.category.icon)
                    .foregroundColor(.blue)
                
                Text(term.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                ImportanceBadge(importance: term.importance)
            }
            
            Text(term.title)
                .font(.headline)
            
            // 原文
            VStack(alignment: .leading, spacing: 8) {
                Text("原文")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(term.originalText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 3)
            }
            
            // 解释
            VStack(alignment: .leading, spacing: 8) {
                Text("解释")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(term.explanation)
                    .font(.subheadline)
            }
            
            // 操作按钮
            HStack {
                Button {
                    isExpanded.toggle()
                } label: {
                    Text(isExpanded ? "收起" : "展开原文")
                        .font(.caption)
                }
                
                Spacer()
                
                Button {
                    getDetailedExplanation()
                } label: {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label("深度解读", systemImage: "lightbulb")
                            .font(.caption)
                    }
                }
                .disabled(isLoading)
            }
            
            // 深度解读内容
            if let explanation = detailedExplanation {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("深度解读")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(explanation)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func getDetailedExplanation() {
        isLoading = true
        
        Task {
            do {
                let explanation = try await AIService.shared.explainClause(term.originalText, contractContext: contractText)
                await MainActor.run {
                    detailedExplanation = explanation
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - 重要程度徽章
struct ImportanceBadge: View {
    let importance: Importance
    
    var body: some View {
        Text(importance.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var badgeColor: Color {
        switch importance {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - 风险卡片
struct RiskCard: View {
    let risk: RiskItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 风险等级
            HStack {
                Image(systemName: risk.level.icon)
                    .foregroundColor(levelColor)
                
                Text(risk.level.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(levelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(levelColor.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(risk.title)
                .font(.headline)
            
            Text(risk.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 建议
            VStack(alignment: .leading, spacing: 8) {
                Text("应对建议")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(risk.suggestion)
                    .font(.subheadline)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
            
            // 相关条款
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("相关条款")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(risk.relatedClause)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Text(isExpanded ? "收起" : "查看相关条款")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(levelColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var levelColor: Color {
        switch risk.level {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

// MARK: - 分析中遮罩
struct AnalyzingOverlay: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: animationProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
                
                Text("AI正在分析合同...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("识别关键条款和潜在风险")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationProgress = 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContractDetailView(contract: Contract(title: "测试合同", originalText: "这是一份测试合同内容"))
    }
    .environment(ContractStore())
}

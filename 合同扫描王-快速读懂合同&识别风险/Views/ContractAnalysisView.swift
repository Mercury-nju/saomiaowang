//
//  ContractAnalysisView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI

struct ContractAnalysisView: View {
    @Environment(ContractStore.self) var contractStore
    @Environment(\.dismiss) var dismiss
    @State var contract: Contract
    @State private var isAnalyzing = true
    @State private var analysisError: String?
    @State private var showEditTitle = false
    @State private var editedTitle: String = ""
    
    var body: some View {
        VStack {
            if isAnalyzing {
                analysisProgressView
            } else if let error = analysisError {
                errorView(error)
            } else {
                successView
            }
        }
        .navigationTitle("合同分析")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isAnalyzing)
        .toolbar {
            if !isAnalyzing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .alert("修改合同名称", isPresented: $showEditTitle) {
            TextField("合同名称", text: $editedTitle)
            Button("取消", role: .cancel) { }
            Button("确定") {
                contract.title = editedTitle
                contractStore.updateContract(contract)
            }
        }
        .onAppear {
            editedTitle = contract.title
            startAnalysis()
        }
    }
    
    // MARK: - 分析进度视图
    private var analysisProgressView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 动画图标
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("AI正在分析合同")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("正在识别关键条款和潜在风险...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 进度指示
            VStack(spacing: 16) {
                AnalysisStep(icon: "doc.text", title: "文字识别", status: .completed)
                AnalysisStep(icon: "brain", title: "AI分析中", status: .inProgress)
                AnalysisStep(icon: "checkmark.shield", title: "风险评估", status: .pending)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - 错误视图
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("分析失败")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                startAnalysis()
            } label: {
                Label("重新分析", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - 成功视图
    private var successView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 成功图标
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                }
                .padding(.top, 20)
                
                Text("分析完成")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 合同信息卡片
                if let analysis = contract.analysisResult {
                    VStack(spacing: 16) {
                        // 合同名称
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("合同名称")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(contract.title)
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            Button {
                                showEditTitle = true
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Divider()
                        
                        // 合同类型
                        HStack {
                            Text("合同类型")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(analysis.contractType)
                                .fontWeight(.medium)
                        }
                        
                        // 关键条款数
                        HStack {
                            Text("关键条款")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(analysis.keyTerms.count) 条")
                                .fontWeight(.medium)
                        }
                        
                        // 风险统计
                        HStack {
                            Text("风险提示")
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 12) {
                                let highCount = analysis.riskItems.filter { $0.level == .high }.count
                                let mediumCount = analysis.riskItems.filter { $0.level == .medium }.count
                                let lowCount = analysis.riskItems.filter { $0.level == .low }.count
                                
                                if highCount > 0 {
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.red).frame(width: 8, height: 8)
                                        Text("\(highCount)")
                                    }
                                }
                                if mediumCount > 0 {
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                                        Text("\(mediumCount)")
                                    }
                                }
                                if lowCount > 0 {
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.yellow).frame(width: 8, height: 8)
                                        Text("\(lowCount)")
                                    }
                                }
                                if analysis.riskItems.isEmpty {
                                    Text("无风险")
                                        .foregroundColor(.green)
                                }
                            }
                            .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    // 摘要预览
                    VStack(alignment: .leading, spacing: 12) {
                        Text("合同摘要")
                            .font(.headline)
                        
                        Text(analysis.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
                
                // 查看详情按钮
                NavigationLink {
                    ContractDetailView(contract: contract)
                } label: {
                    Text("查看详细分析")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - 开始分析
    private func startAnalysis() {
        isAnalyzing = true
        analysisError = nil
        
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
                    analysisError = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }
}

// MARK: - 分析步骤
struct AnalysisStep: View {
    let icon: String
    let title: String
    let status: StepStatus
    
    enum StepStatus {
        case pending
        case inProgress
        case completed
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if status == .inProgress {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: status == .completed ? "checkmark" : icon)
                        .foregroundColor(statusColor)
                }
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(status == .pending ? .secondary : .primary)
            
            Spacer()
            
            if status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}

#Preview {
    NavigationStack {
        ContractAnalysisView(contract: Contract(title: "测试合同", originalText: "这是测试内容"))
    }
    .environment(ContractStore())
}

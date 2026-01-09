//
//  HomeView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @Environment(ContractStore.self) var contractStore
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var showAnalysisView = false
    @State private var newContract: Contract?
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部统计
                    statsHeader
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // 主操作区
                    mainActions
                        .padding()
                    
                    // 最近合同
                    recentSection
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("合同扫描王")
            .sheet(isPresented: $showCamera) {
                CameraView(images: $selectedImages, isPresented: $showCamera)
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView(selectedImages: $selectedImages)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView(selectedImages: $selectedImages)
            }
            .navigationDestination(isPresented: $showAnalysisView) {
                if let contract = newContract {
                    ContractAnalysisView(contract: contract)
                }
            }
            .onChange(of: selectedImages) { _, newImages in
                if !newImages.isEmpty {
                    processImages(newImages)
                }
            }
            .overlay {
                if isProcessing {
                    ProcessingOverlay()
                }
            }
        }
    }
    
    // MARK: - 统计头部
    private var statsHeader: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(contractStore.totalContracts)", label: "全部", color: .primary)
            
            Divider()
                .frame(height: 30)
            
            StatItem(value: "\(contractStore.analyzedContracts)", label: "已分析", color: .green)
            
            Divider()
                .frame(height: 30)
            
            StatItem(value: "\(contractStore.highRiskCount)", label: "高风险", color: .red)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 主操作区
    private var mainActions: some View {
        VStack(spacing: 12) {
            // 扫描按钮 - 主要操作
            Button {
                showCamera = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("扫描合同")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("拍照识别，支持多页")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // 次要操作
            HStack(spacing: 12) {
                SecondaryButton(title: "相册导入", icon: "photo", color: .orange) {
                    showPhotoPicker = true
                }
                
                SecondaryButton(title: "文件导入", icon: "doc", color: .purple) {
                    showDocumentPicker = true
                }
                
                NavigationLink {
                    ContractCompareView()
                } label: {
                    SecondaryButtonLabel(title: "合同对比", icon: "doc.on.doc", color: .teal)
                }
            }
        }
    }
    
    // MARK: - 最近合同
    private var recentSection: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("最近合同")
                    .font(.headline)
                Spacer()
                if contractStore.contracts.count > 3 {
                    NavigationLink {
                        ContractListView()
                    } label: {
                        Text("查看全部")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // 列表
            if contractStore.contracts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无合同记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("扫描或导入合同开始使用")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
                .background(Color(.systemBackground))
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(contractStore.contracts.prefix(5).enumerated()), id: \.element.id) { index, contract in
                        let currentContract = contractStore.getContract(by: contract.id) ?? contract
                        
                        NavigationLink {
                            ContractDetailView(contract: currentContract)
                        } label: {
                            ContractCell(contract: currentContract)
                        }
                        .buttonStyle(.plain)
                        
                        if index < min(4, contractStore.contracts.count - 1) {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(12)
    }
    
    // MARK: - 处理图片
    private func processImages(_ images: [UIImage]) {
        isProcessing = true
        
        Task {
            do {
                let text = try await OCRService.shared.recognizeText(from: images)
                let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.7) }
                var contract = Contract(
                    title: "合同_\(Date().formatted(date: .numeric, time: .omitted))",
                    originalText: text,
                    imageData: imageData
                )
                contract.status = .analyzing
                
                await MainActor.run {
                    contractStore.addContract(contract)
                    newContract = contract
                    selectedImages = []
                    isProcessing = false
                    showAnalysisView = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    selectedImages = []
                }
            }
        }
    }
}

// MARK: - 统计项
struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 次要按钮
struct SecondaryButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SecondaryButtonLabel(title: title, icon: icon, color: color)
        }
    }
}

struct SecondaryButtonLabel: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - 合同单元格
struct ContractCell: View {
    let contract: Contract
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态图标
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 18))
                    .foregroundColor(statusColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(contract.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(contract.status.rawValue)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let type = contract.analysisResult?.contractType {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(type)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // 风险标记
            if let analysis = contract.analysisResult {
                let highRisk = analysis.riskItems.filter { $0.level == .high }.count
                if highRisk > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("\(highRisk)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var statusColor: Color {
        switch contract.status {
        case .completed: return .green
        case .analyzing: return .blue
        case .pending: return .orange
        case .failed: return .red
        }
    }
    
    private var statusIcon: String {
        switch contract.status {
        case .completed: return "checkmark"
        case .analyzing: return "arrow.2.circlepath"
        case .pending: return "clock"
        case .failed: return "xmark"
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: contract.createdAt, relativeTo: Date())
    }
}

// MARK: - 处理中
struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.1)
                    .tint(.primary)
                Text("正在识别...")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    HomeView()
        .environment(ContractStore())
}

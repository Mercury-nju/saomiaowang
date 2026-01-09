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
                VStack(spacing: 24) {
                    // 核心扫描区域
                    scanSection
                    
                    // 其他导入方式
                    otherImportSection
                    
                    // 最近合同
                    recentSection
                }
                .padding(.horizontal)
                .padding(.top, 12)
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
    
    // MARK: - 扫描区域
    private var scanSection: some View {
        Button {
            showCamera = true
        } label: {
            VStack(spacing: 20) {
                // 图标
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                // 文字
                VStack(spacing: 6) {
                    Text("扫描合同")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("拍照识别合同内容，智能分析风险")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 其他导入
    private var otherImportSection: some View {
        HStack(spacing: 12) {
            ImportButton(title: "相册导入", icon: "photo") {
                showPhotoPicker = true
            }
            
            ImportButton(title: "文件导入", icon: "folder") {
                showDocumentPicker = true
            }
            
            NavigationLink {
                ContractCompareView()
            } label: {
                ImportButtonLabel(title: "合同对比", icon: "doc.on.doc")
            }
        }
    }
    
    // MARK: - 最近合同
    private var recentSection: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("最近合同")
                    .font(.headline)
                Spacer()
                if contractStore.contracts.count > 3 {
                    NavigationLink {
                        ContractListView()
                    } label: {
                        Text("全部")
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
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("暂无合同")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
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
                            Divider().padding(.leading, 56)
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

// MARK: - 导入按钮
struct ImportButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ImportButtonLabel(title: title, icon: icon)
        }
    }
}

struct ImportButtonLabel: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
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
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 3) {
                Text(contract.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(contract.status.rawValue)
                        .foregroundColor(statusColor)
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    
                    Text(timeAgo)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
            
            Spacer()
            
            // 风险
            if let analysis = contract.analysisResult {
                let highRisk = analysis.riskItems.filter { $0.level == .high }.count
                if highRisk > 0 {
                    Text("\(highRisk)个风险")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.quaternary)
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

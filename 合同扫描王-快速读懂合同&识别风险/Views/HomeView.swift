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
                VStack(spacing: 20) {
                    // 扫描按钮
                    scanButton
                    
                    // 其他方式
                    otherOptions
                    
                    // 最近合同
                    recentSection
                }
                .padding()
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
    
    // MARK: - 扫描按钮
    private var scanButton: some View {
        Button {
            showCamera = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.blue)
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("拍照扫描合同")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("支持多页扫描")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 其他选项
    private var otherOptions: some View {
        HStack(spacing: 12) {
            OptionButton(title: "相册", icon: "photo", color: .green) {
                showPhotoPicker = true
            }
            
            OptionButton(title: "文件", icon: "folder", color: .orange) {
                showDocumentPicker = true
            }
            
            NavigationLink {
                ContractCompareView()
            } label: {
                OptionLabel(title: "对比", icon: "doc.on.doc", color: .purple)
            }
        }
    }
    
    // MARK: - 最近合同
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近")
                    .font(.headline)
                Spacer()
                if !contractStore.contracts.isEmpty {
                    NavigationLink("全部") {
                        ContractListView()
                    }
                    .font(.subheadline)
                }
            }
            
            if contractStore.contracts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无合同")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(contractStore.contracts.prefix(5)) { contract in
                    let currentContract = contractStore.getContract(by: contract.id) ?? contract
                    NavigationLink {
                        ContractDetailView(contract: currentContract)
                    } label: {
                        ContractRow(contract: currentContract)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
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

// MARK: - 选项按钮
struct OptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            OptionLabel(title: title, icon: icon, color: color)
        }
    }
}

struct OptionLabel: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 合同行
struct ContractRow: View {
    let contract: Contract
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contract.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(contract.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 状态
            Text(contract.status.rawValue)
                .font(.caption)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch contract.status {
        case .completed: return .green
        case .analyzing: return .blue
        case .pending: return .orange
        case .failed: return .red
        }
    }
}

// MARK: - 处理中
struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("识别中...")
                    .font(.body)
            }
            .padding(24)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
    }
}

#Preview {
    HomeView()
        .environment(ContractStore())
}

//
//  ContractCompareView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI

struct ContractCompareView: View {
    @Environment(ContractStore.self) var contractStore
    @State private var contract1: Contract?
    @State private var contract2: Contract?
    @State private var comparisonResult: String?
    @State private var isComparing = false
    @State private var showContract1Picker = false
    @State private var showContract2Picker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 说明
                Text("选择两份合同进行对比分析，AI将帮您识别条款差异")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 合同选择区域
                HStack(spacing: 16) {
                    ContractSelector(
                        title: "合同一",
                        contract: contract1,
                        action: { showContract1Picker = true }
                    )
                    
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    ContractSelector(
                        title: "合同二",
                        contract: contract2,
                        action: { showContract2Picker = true }
                    )
                }
                .padding(.horizontal)
                
                // 对比按钮
                Button {
                    startComparison()
                } label: {
                    HStack {
                        if isComparing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "doc.on.doc")
                        }
                        Text(isComparing ? "对比中..." : "开始对比")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(canCompare ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!canCompare || isComparing)
                .padding(.horizontal)
                
                // 对比结果
                if let result = comparisonResult {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("对比结果")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = result
                            } label: {
                                Label("复制", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                        
                        Text(result)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("合同对比")
        .sheet(isPresented: $showContract1Picker) {
            ContractPickerSheet(selectedContract: $contract1, excludeContract: contract2)
        }
        .sheet(isPresented: $showContract2Picker) {
            ContractPickerSheet(selectedContract: $contract2, excludeContract: contract1)
        }
    }
    
    private var canCompare: Bool {
        contract1 != nil && contract2 != nil
    }
    
    private func startComparison() {
        guard let c1 = contract1, let c2 = contract2 else { return }
        
        isComparing = true
        comparisonResult = nil
        
        Task {
            do {
                let result = try await AIService.shared.compareContracts(
                    contract1: c1.originalText,
                    contract2: c2.originalText
                )
                
                await MainActor.run {
                    comparisonResult = result
                    isComparing = false
                }
            } catch {
                await MainActor.run {
                    comparisonResult = "对比失败：\(error.localizedDescription)"
                    isComparing = false
                }
            }
        }
    }
}

// MARK: - 合同选择器
struct ContractSelector: View {
    let title: String
    let contract: Contract?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let contract = contract {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text(contract.title)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(contract != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: contract != nil ? 2 : 1)
            )
        }
    }
}

// MARK: - 合同选择弹窗
struct ContractPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ContractStore.self) var contractStore
    @Binding var selectedContract: Contract?
    let excludeContract: Contract?
    
    var availableContracts: [Contract] {
        contractStore.contracts.filter { contract in
            contract.status == .completed && contract.id != excludeContract?.id
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if availableContracts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("暂无可用合同")
                            .font(.headline)
                        
                        Text("请先分析合同后再进行对比")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(availableContracts) { contract in
                        Button {
                            selectedContract = contract
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contract.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let analysis = contract.analysisResult {
                                        Text(analysis.contractType)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(contract.createdAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedContract?.id == contract.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择合同")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContractCompareView()
    }
    .environment(ContractStore())
}

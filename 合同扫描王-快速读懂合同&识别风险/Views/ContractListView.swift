//
//  ContractListView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI

struct ContractListView: View {
    @Environment(ContractStore.self) var contractStore
    @State private var searchText = ""
    @State private var selectedFilter: ContractStatus? = nil
    
    var filteredContracts: [Contract] {
        var contracts = contractStore.contracts
        
        if let filter = selectedFilter {
            contracts = contracts.filter { $0.status == filter }
        }
        
        if !searchText.isEmpty {
            contracts = contracts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.originalText.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return contracts
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 筛选器
                filterSection
                
                // 合同列表
                if filteredContracts.isEmpty {
                    emptyView
                } else {
                    contractList
                }
            }
            .navigationTitle("我的合同")
            .searchable(text: $searchText, prompt: "搜索合同")
        }
    }
    
    // MARK: - 筛选器
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "全部",
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }
                
                ForEach([ContractStatus.completed, .analyzing, .pending, .failed], id: \.self) { status in
                    FilterChip(
                        title: status.rawValue,
                        isSelected: selectedFilter == status
                    ) {
                        selectedFilter = status
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 空视图
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("暂无合同")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("扫描或上传合同开始使用")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - 合同列表
    private var contractList: some View {
        List {
            ForEach(filteredContracts) { contract in
                NavigationLink {
                    ContractDetailView(contractId: contract.id)
                } label: {
                    ContractRowView(contract: contract)
                }
            }
            .onDelete(perform: deleteContracts)
        }
        .listStyle(.plain)
    }
    
    private func deleteContracts(at offsets: IndexSet) {
        for index in offsets {
            let contract = filteredContracts[index]
            contractStore.deleteContract(contract)
        }
    }
}

// MARK: - 筛选标签
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

// MARK: - 合同行视图
struct ContractRowView: View {
    let contract: Contract
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(contract.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(contract.status.rawValue)
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(4)
                    
                    if let analysis = contract.analysisResult {
                        Text(analysis.contractType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(contract.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 风险指示
            if let analysis = contract.analysisResult {
                let highRiskCount = analysis.riskItems.filter { $0.level == .high }.count
                if highRiskCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("\(highRiskCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
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
    
    private var statusIcon: String {
        switch contract.status {
        case .completed: return "checkmark.circle.fill"
        case .analyzing: return "arrow.triangle.2.circlepath"
        case .pending: return "clock.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

#Preview {
    ContractListView()
        .environment(ContractStore())
}

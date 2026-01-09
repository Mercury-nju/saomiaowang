//
//  SettingsView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI

struct SettingsView: View {
    @Environment(ContractStore.self) var contractStore
    @State private var showClearAlert = false
    
    // GitHub Pages 链接
    private let privacyPolicyURL = "https://mercury-nju.github.io/saomiaowang/privacy-policy.html"
    private let userAgreementURL = "https://mercury-nju.github.io/saomiaowang/user-agreement.html"
    
    var body: some View {
        NavigationStack {
            List {
                // 统计
                Section("使用统计") {
                    LabeledContent("已分析合同", value: "\(contractStore.analyzedContracts)")
                    LabeledContent("总合同数", value: "\(contractStore.totalContracts)")
                    LabeledContent("高风险条款", value: "\(contractStore.highRiskCount)")
                }
                
                // 数据管理
                Section("数据管理") {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("清除所有数据", systemImage: "trash")
                    }
                }
                
                // 法律条款
                Section("法律条款") {
                    Link(destination: URL(string: privacyPolicyURL)!) {
                        HStack {
                            Label("隐私政策", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: userAgreementURL)!) {
                        HStack {
                            Label("用户协议", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 关于
                Section("关于") {
                    LabeledContent("版本", value: "1.0.0")
                }
                
                // 安全说明
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.green)
                            Text("数据安全")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text("合同数据存储在本地设备，AI分析采用加密传输。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("设置")
            .alert("确认清除", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("将删除所有合同和问答记录，无法恢复。")
            }
        }
    }
    
    private func clearAllData() {
        for contract in contractStore.contracts {
            contractStore.deleteContract(contract)
        }
    }
}

#Preview {
    SettingsView()
        .environment(ContractStore())
}
